#' Generic for inverse prediction
#'
#' @param object An object for which to compute the inverse prediction.
#' @param ... Additional arguments passed to methods.
#'
#' @keywords internal
#'
#' @export
inverse_predict <- function(object, ...) {
  UseMethod("inverse_predict")
}

#' Inverse prediction from a \code{modeler} object
#'
#' Computes the x-value at which a fitted model reaches a user-specified response value (y-value).
#'
#' @aliases inverse_predict.modeler
#' @param object A fitted object of class \code{modeler}.
#' @param y A numeric scalar giving the target y-value for which to compute the corresponding x.
#' @param id Optional vector of \code{uid}s for which to perform inverse prediction. If \code{NULL}, all groups are used.
#' @param interval Optional numeric vector of length 2 specifying the interval in which to search for the root.
#' If \code{NULL}, the interval is inferred from the range of the observed x-values.
#' @param tol Numerical tolerance passed to \code{\link[stats]{uniroot}} for root-finding accuracy.
#' @param resolution Integer. Number of grid points used to scan the interval.
#' @param ... Additional parameters for future functionality.
#'
#' @return A \code{tibble} with one row per group, containing:
#' \itemize{
#'   \item \code{uid} – unique identifier of the group,
#'   \item \code{fn_name} – the name of the fitted function,
#'   \item \code{lower} and \code{upper} – the search interval used,
#'   \item \code{y} – the predicted y-value (from the function at the root),
#'   \item \code{x} – the x-value at which the function reaches \code{y}.
#' }
#'
#' @details
#' The function uses numeric root-finding to solve \code{f(t, ...params) = y}.
#' If no root is found in the interval, \code{NA} is returned.
#'
#' @seealso \code{\link{predict.modeler}}, \code{\link[stats]{uniroot}}
#'
#' @method inverse_predict modeler
#'
#' @export
#' @importFrom stats uniroot
#'
#' @examples
#' library(flexFitR)
#' data(dt_potato)
#' mod_1 <- dt_potato |>
#'   modeler(
#'     x = DAP,
#'     y = Canopy,
#'     grp = Plot,
#'     fn = "fn_lin_plat",
#'     parameters = c(t1 = 45, t2 = 80, k = 0.9),
#'     subset = c(15, 2, 45)
#'   )
#' print(mod_1)
#' inverse_predict(mod_1, y = 50)
#' inverse_predict(mod_1, y = 75, interval = c(20, 80))
inverse_predict.modeler <- function(object,
                                    y,
                                    id = NULL,
                                    interval = NULL,
                                    tol = 1e-6,
                                    resolution = 1000, ...) {
  # Check the class of object
  if (!inherits(object, "modeler")) {
    stop("The object should be of class 'modeler'.")
  }
  if (is.null(y)) {
    stop("Argument y is required for inverse predictions.")
  }
  if (length(y) != 1) {
    stop("Argument y is required to be of sized 1.")
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
  # For applying to a list
  x_for_y <- function(fit,
                      y,
                      interval = NULL,
                      tol = 1e-6,
                      resolution = 1000) {
    fn_name <- fit$fn_name
    est <- fit$type |>
      dplyr::filter(type == "estimable") |>
      dplyr::pull(value, name = parameter)
    fix <- fit$type |>
      dplyr::filter(type == "fixed") |>
      dplyr::pull(value, name = parameter)
    if (length(fix) == 0) fix <- NA
    param_list <- aux_fun(curve = fn_name, params = est, fixed_params = fix)
    if (is.null(interval)) {
      x_vals <- fit$x
      interval <- range(x_vals, finite = TRUE)
    }
    t_seq <- seq(interval[1], interval[2], length.out = resolution)
    y_seq <- ff(params = est, x_new = t_seq, curve = fn_name, fixed_params = fix)
    sign_change <- diff(sign(y_seq - y))
    crossings <- which(sign_change != 0)
    roots <- lapply(crossings, function(i) {
      tryCatch(
        {
          uniroot(
            f = function(t) do.call(fn_name, c(list(t), param_list)) - y,
            interval = c(t_seq[i], t_seq[i + 1]),
            tol = tol
          )$root
        },
        error = function(e) {
          warning("Root not found: ", e$message)
          return(NA_real_)
        }
      )
    })
    roots <- unlist(roots)
    # Build output rows for each root
    y_pred <- ff(params = est, x_new = unlist(roots), curve = fn_name, fixed_params = fix)
    if (is.logical(y_pred)) {
      y_pred <- NA
      roots <- NA
    }
    data.frame(
      uid = fit$uid,
      fn_name = fn_name,
      lower = interval[1],
      upper = interval[2],
      y = y_pred,
      x = roots
    )
  }
  inverse <- do.call(
    what = rbind,
    args = lapply(
      X = fit_list,
      FUN = x_for_y,
      y = y,
      interval = interval,
      tol = tol,
      resolution = resolution
    )
  ) |>
    as_tibble()
  return(inverse)
}


aux_fun <- function(curve, params, fixed_params) {
  args <- names(formals(curve))
  arg_names <- args[-1]
  full_params <- setNames(rep(NA, length(arg_names)), arg_names)
  if (!any(is.na(fixed_params))) {
    full_params[names(fixed_params)] <- fixed_params
  }
  free_param_names <- setdiff(arg_names, names(fixed_params))
  full_params[free_param_names] <- params
  full_params
}
