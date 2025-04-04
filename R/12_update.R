#' Update a \code{modeler} object
#'
#' @description
#' It creates a new fitted object using the parameter values from the current
#' model as initial values. It can also be used to perform a few additional
#' iterations of a model that has not converged.
#'
#' @aliases update.modeler
#' @param object An object of class \code{modeler}.
#' @param method A character vector specifying optimization methods.
#' Check available methods using \code{list_methods()}. Defaults to
#' the ones in \code{object}.
#' @param track Logical. If \code{TRUE}, the function compares the SSE
#' before and after the update and reports how many groups improved. Useful for
#' evaluating whether the refit led to better convergence.
#' @param eps Numeric. The minimum change in SSE required to consider a fit improved.
#' Defaults to \code{1e-6}. Smaller values may include numerical noise as improvements.
#' @param ... Additional parameters for future functionality.
#' @return An object of class \code{modeler}, which is a list containing the following elements:
#' \describe{
#'   \item{\code{param}}{Data frame containing optimized parameters and related information.}
#'   \item{\code{dt}}{Data frame with input data, fitted values, and residuals.}
#'   \item{\code{metrics}}{Metrics and summary of the models.}
#'   \item{\code{execution}}{Total execution time for the analysis.}
#'   \item{\code{response}}{Name of the response variable analyzed.}
#'   \item{\code{keep}}{Metadata retained based on the \code{keep} argument.}
#'   \item{\code{fun}}{Name of the curve-fitting function used.}
#'   \item{\code{parallel}}{List containing parallel execution details (if applicable).}
#'   \item{\code{fit}}{List of fitted models for each group.}
#' }
#'
#' @method update modeler
#'
#' @export
#' @examples
#' library(flexFitR)
#' data(dt_potato)
#' mo_1 <- dt_potato |>
#'   modeler(
#'     x = DAP,
#'     y = GLI,
#'     grp = Plot,
#'     fn = "fn_lin_pl_lin",
#'     parameters = c(t1 = 10, t2 = 62, t3 = 90, k = 0.32, beta = -0.01),
#'     subset = 195
#'   )
#' plot(mo_1)
#' mo_2 <- update(mo_1)
#' plot(mo_2)
#' @import dplyr
update.modeler <- function(object,
                           method = NULL,
                           track = TRUE,
                           eps = 1e-6, ...) {
  # Validate input
  if (!inherits(object, "modeler")) {
    stop("The object should be of class 'modeler'.")
  }
  # Check for single regression function
  fun <- object$fun
  if (length(fun) != 1) {
    stop("The object should contain exactly one regression function.")
  }
  # Prepare data
  data <- select(object$dt, -c(.fitted:fn_name))
  names(data)[names(data) %in% "x"] <- object$x_var
  names(data)[names(data) %in% "y"] <- object$response
  # Extract fitting sample
  sample <- object$fit[[1L]]
  coef_table <- sample$type
  param_info <- object$param
  # Identify parameter types
  free_params <- coef_table[coef_table$type == "estimable", "parameter"]
  fix_params <- coef_table[coef_table$type == "fixed", "parameter"]
  arg_order <- names(formals(fun))[-1]
  # Construct initial/fixed parameter data.frame
  param_cols <- c("uid", free_params, fix_params)
  parameters <- param_info[, param_cols, drop = FALSE]
  parameters <- parameters[, c("uid", arg_order), drop = FALSE]
  if (length(fix_params) == 0) {
    fixed_params <- NULL
  } else {
    fixed_params <- param_info[, c("uid", fix_params), drop = FALSE]
  }
  # Store original metrics if tracking
  if (track) {
    old_metrics <- param_info[, c("uid", "sse")]
  }
  # Re-fit
  new_object <- modeler(
    data = data,
    x = object$x_var,
    y = object$response,
    grp = "uid",
    keep = object$keep,
    fn = fun,
    parameters = parameters,
    lower = sample$lower,
    upper = sample$upper,
    fixed_params = fixed_params,
    method = if (!is.null(method)) method else unique(object$metrics$method),
    subset = unique(param_info$uid),
    options = attr(object, "options")[5:8],
    control = attr(object, "control")
  )
  if (track) {
    comp <- merge(
      x = old_metrics,
      y = new_object$param[, c("uid", "sse")],
      by = "uid",
      suffixes = c(".old", ".new")
    )
    improvement <- comp$sse.old - comp$sse.new
    i <- improvement > eps
    to <- nrow(comp)
    n_i <- sum(i, na.rm = TRUE)
    message(sprintf("Improved SSE in %d/%d groups (eps = %.1e)", n_i, to, eps))
  }
  return(new_object)
}
