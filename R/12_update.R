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
#' \code{c("subplex", "pracmanm", "anms")}.
#' @param options A list of additional options. See \code{modeler.options()}
#' \describe{
#'   \item{\code{progress}}{Logical. If \code{TRUE} a progress bar is displayed. Default is \code{FALSE}. Try this before running the function: \code{progressr::handlers("progress", "beepr")}.}
#'   \item{\code{parallel}}{Logical. If \code{TRUE} the model fit is performed in parallel. Default is \code{FALSE}.}
#'   \item{\code{workers}}{The number of parallel processes to use. \code{parallel::detectCores()}}
#'   \item{\code{trace}}{If \code{TRUE} , convergence monitoring of the current fit is reported in the console. \code{FALSE} by default.}
#'   \item{\code{return_method}}{ Logical. If \code{TRUE}, includes the optimization method used in the result. Default is \code{FALSE}.}
#' }
#' @param control A list of control parameters to be passed to the optimization function. For example: \code{list(maxit = 500)}.
#' @param track Logical. If \code{TRUE}, the function compares the sse
#' before and after the update and reports how many groups improved. Useful for
#' evaluating whether the refit led to better convergence.
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
                           options = modeler.options(),
                           control = list(), ...) {
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
    options = options,
    control = control
  )
  if (track) {
    comp <- merge(
      x = old_metrics,
      y = new_object$param[, c("uid", "sse")],
      by = "uid",
      suffixes = c(".old", ".new")
    )
    i <- with(comparison, (sse.new < sse.old))
    n_i <- sum(i, na.rm = TRUE)
    message(sprintf("Update improved fit in %d/%d groups.", n_i, nrow(comp)))
  }
  return(new_object)
}
