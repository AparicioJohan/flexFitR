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
#' Computes the time (x-value) at which a fitted model reaches a user-specified response value (y-value).
#'
#' @aliases inverse_predict.modeler
#' @param object A fitted object of class \code{modeler}.
#' @param y A numeric scalar giving the target y-value for which to compute the corresponding x.
#' @param id Optional vector of \code{uid}s for which to perform inverse prediction. If \code{NULL}, all groups are used.
#' @param interval Optional numeric vector of length 2 specifying the interval in which to search for the root.
#' If \code{NULL}, the interval is inferred from the range of the observed x-values.
#' @param tol Numerical tolerance passed to \code{\link[stats]{uniroot}} for root-finding accuracy.
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
                                    tol = 1e-6, ...) {
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
  # For applying to a list
  .x_for_y <- function(fit, y, interval = NULL, tol = 1e-6) {
    fn_name <- fit$fn_name
    param_list <- setNames(fit$type$value, fit$type$parameter)
    fn <- get(fn_name, mode = "function")
    # Define the root function: f(t) - y = 0
    root_fun <- function(t) do.call(fn, c(list(t), param_list)) - y
    if (is.null(interval)) {
      x_vals <- fit$x
      interval <- range(x_vals, finite = TRUE)
    }
    # Solve numerically
    result <- tryCatch(
      {
        uniroot(root_fun, interval = interval, tol = tol)$root
      },
      error = function(e) {
        warning("Root not found: ", e$message)
        return(NA)
      }
    )
    # Predicted value
    predicted_value <- ff(params = param_list, x_new = result, curve = fn_name)
    # Combine results
    results <- data.frame(
      uid = fit$uid,
      fn_name = fit$fn_name,
      lower = interval[1],
      upper = interval[2],
      y = predicted_value,
      x = result
    )
    return(results)
  }
  # List of models
  fit_list <- object$fit
  id <- which(unlist(lapply(fit_list, function(x) x$uid)) %in% uid)
  fit_list <- fit_list[id]
  iter <- seq_along(fit_list)
  inverse <- do.call(
    what = rbind,
    args = lapply(fit_list, .x_for_y, y, interval = interval, tol = tol)
  ) |>
    as_tibble()
  return(inverse)
}
