#' Compute tangent line(s) from a \code{modeler} object
#'
#' Computes the slope and intercept of the tangent line(s) to a fitted curve
#' at one or more specified x-values.
#'
#' @param object A fitted object of class \code{modeler}, created by \code{\link{modeler}()}.
#' @param x A numeric vector of x-values at which to compute tangent lines.
#' A data.frame is also accepted with columns <uid, x>.
#' @param id Optional vector of \code{uid}s indicating which groups to compute tangent lines for. If \code{NULL}, all groups are used.
#'
#' @return A tibble with one row per tangent line and the following columns:
#' \itemize{
#'   \item \code{uid}: unique identifier of the group.
#'   \item \code{fn_name}: Name of the fitted function.
#'   \item \code{x}: x-value where the tangent line is evaluated.
#'   \item \code{y}: Fitted y-value at x.
#'   \item \code{slope}: First derivative (slope of tangent) at x.
#'   \item \code{intercept}: y-intercept of the tangent line.
#' }
#'
#' @export
#'
#' @examples
#' library(flexFitR)
#' library(ggplot2)
#' data(dt_potato)
#' mod <- dt_potato |>
#'   modeler(
#'     x = DAP,
#'     y = Canopy,
#'     grp = Plot,
#'     fn = "fn_logistic",
#'     parameters = c(a = 4, t0 = 40, k = 100),
#'     subset = 2
#'   )
#' plot(mod)
#' tl <- compute_tangent(mod, x = c(48.35, 65))
#' print(tl)
#' plot(mod) +
#'   geom_abline(
#'     data = tl,
#'     mapping = aes(slope = slope, intercept = intercept),
#'     linetype = 2,
#'     color = "blue"
#'   ) +
#'   geom_point(
#'     data = tl,
#'     mapping = aes(x = x, y = y),
#'     shape = 8,
#'     color = "blue",
#'     size = 2
#'   )
compute_tangent <- function(object, x = NULL, id = NULL) {
  # Check the class of object
  if (!inherits(object, "modeler")) {
    stop("The object should be of class 'modeler'.")
  }
  if (is.null(x)) {
    stop("Argument x is required for tangent line.")
  }
  data <- object$dt
  if (!is.null(id)) {
    if (!all(id %in% unique(data$uid))) {
      stop("ids not found in object.")
    }
    uid <- id
  } else {
    uid <- unique(data$uid)
  }
  # List of models
  fit_list <- object$fit
  id <- which(unlist(lapply(fit_list, function(x) x$uid)) %in% uid)
  fit_list <- fit_list[id]
  do_tangent <- function(fit, x) {
    sample <- fit$uid
    fn_name <- fit$fn_name
    est <- fit$type |>
      dplyr::filter(type == "estimable") |>
      dplyr::pull(value, name = parameter)
    fix <- fit$type |>
      dplyr::filter(type == "fixed") |>
      dplyr::pull(value, name = parameter)
    if (inherits(x, "data.frame")) {
      stopifnot(all(c("uid", "x") %in% colnames(x)))
      x <- x[x$uid %in% sample, "x", drop = TRUE]
      if (length(x) == 0) {
        stop("uid: '", sample, "' not found.")
      }
    }
    y_est <- ff(params = est, x_new = x, curve = fn_name, fixed_params = fix)
    d_est <- ff_deriv(params = est, x_new = x, curve = fn_name, fixed_params = fix)
    data.frame(
      uid = sample,
      fn_name = fn_name,
      x = x,
      y = y_est,
      slope = d_est,
      intercept = y_est - d_est * x
    )
  }
  out <- do.call(
    what = rbind,
    args = lapply(X = fit_list, FUN = do_tangent, x = x)
  ) |>
    as_tibble()
  return(out)
}
