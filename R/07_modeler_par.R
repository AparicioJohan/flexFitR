#' Modeler HTP
#'
#' @description
#' General-purpose optimization for HTP data.
#'
#' @param x An object of class \code{read_HTP}, containing the results of the \code{read_HTP()} function.
#' @param index A string specifying the trait to be modeled. Default is \code{"GLI"}. Must match a trait in the data.
#' @param plot_id An optional vector of plot IDs to filter the data. Default is \code{NULL}, meaning all plots are used.
#' @param add_zero Logical. If \code{TRUE}, adds a zero value to the time series at the start. Default is \code{TRUE}.
#' @param check_negative Logical. If \code{TRUE}, converts negative values in the data to zero. Default is \code{TRUE}.
#' @param max_as_last Logical. If \code{TRUE}, appends the maximum value after reaching the maximum. Default is \code{FALSE}.
#' @param method A character vector specifying the optimization methods to be used. See \code{optimx} package for available methods. Default is \code{c("subplex", "pracmanm", "anms")}.
#' @param return_method Logical. If \code{TRUE}, includes the optimization method used in the result. Default is \code{FALSE}.
#' @param parameters A named numeric vector specifying the initial values for the parameters to be optimized. Default is \code{NULL}.
#' @param lower Numeric vector specifying the lower bounds for the parameters. Default is \code{-Inf} for all parameters.
#' @param upper Numeric vector specifying the upper bounds for the parameters. Default is \code{Inf} for all parameters.
#' @param initial_vals A data frame with columns \code{plot}, \code{genotype}, and the initial parameter values for each plot. Used for providing specific initial values per plot.
#' @param fixed_params A data frame with columns \code{plot}, \code{genotype}, and the fixed parameter values for each plot. Used for fixing certain parameters during optimization.
#' @param fn A string specifying the name of the function to be used for the curve fitting. Default is \code{"fn_piwise"}.
#' @param metric A string specifying the metric to minimize during optimization. Options are \code{"sse"}, \code{"mae"}, \code{"mse"}, and \code{"rmse"}. Default is \code{"sse"}.
#' @param n_points An integer specifying the number of time points to use for approximating the Area Under the Curve (AUC). Default is \code{1000}.
#' @param max_time Numeric. The maximum time value to use for calculating the AUC. Default is \code{NULL}, which uses the last time point in the data.
#' @param control A list of control parameters to be passed to the optimization function. For example, \code{list(maxit = 500)}.
#' @param progress Logical. If \code{TRUE} a progress bar is displayed. Default is \code{FALSE}. Try this before running the function: \code{progressr::handlers("progress", "beepr")}.
#' @param parallel Logical. If \code{TRUE} the model fit is performed in parallel. Default is \code{TRUE}.
#' @param workers The number of parallel processes to use. `parallel::detectCores()`
#' @return An object of class \code{modeler_HTP}, which is a list containing the following elements:
#' \describe{
#'   \item{\code{param}}{A data frame containing the optimized parameters and related information.}
#'   \item{\code{dt}}{A data frame with data used and fitted values.}
#'   \item{\code{fn}}{The call used to calculate the AUC.}
#'   \item{\code{max_time}}{Maximum time value used for calculating the AUC.}
#'   \item{\code{metrics}}{Metrics and summary of the models.}
#'   \item{\code{execution}}{Execution time.}
#' }
#' @noRd
#'
#' @examples
#' library(exploreHTP)
#' suppressMessages(library(dplyr))
#' data(dt_potato)
#' results <- read_HTP(
#'   data = dt_potato,
#'   genotype = "Gen",
#'   time = "DAP",
#'   plot = "Plot",
#'   traits = c("Canopy", "GLI_2"),
#'   row = "Row",
#'   range = "Range"
#' )
#' mat <- modeler_HTP(
#'   x = results,
#'   index = "GLI_2",
#'   plot_id = c(195),
#'   parameters = c(t1 = 38.7, t2 = 62, t3 = 90, k = 0.32, beta = -0.01),
#'   fn = "fn_lin_pl_lin",
#' )
#' plot(mat, plot_id = c(195))
#' print(mat)
#' can <- modeler_HTP(
#'   x = results,
#'   index = "Canopy",
#'   plot_id = c(195),
#'   parameters = c(t1 = 45, t2 = 80, k = 0.9),
#'   fn = "fn_piwise",
#'   max_as_last = TRUE
#' )
#' plot(can, plot_id = c(195))
#' print(can)
#' @import optimx
#' @import tibble
#' @import dplyr
#' @import foreach
#' @import doFuture
#' @import future
modeler_HTP2 <- function(x,
                         index = "GLI",
                         plot_id = NULL,
                         check_negative = TRUE,
                         add_zero = TRUE,
                         max_as_last = FALSE,
                         method = c("subplex", "pracmanm", "anms"),
                         return_method = FALSE,
                         parameters = NULL,
                         lower = -Inf,
                         upper = Inf,
                         initial_vals = NULL,
                         fixed_params = NULL,
                         fn = "fn_piwise",
                         metric = "sse",
                         n_points = 1000,
                         max_time = NULL,
                         control = list(),
                         progress = FALSE,
                         parallel = FALSE,
                         workers = parallel::detectCores()) {
  # Check the class of x
  if (!inherits(x, "read_HTP")) {
    stop("The object should be of class 'read_HTP'.")
  }
  if (is.null(plot_id)) {
    plot_id <- unique(x$dt_long$plot)
  }
  if (parallel) {
    workers <- ifelse(
      test = is.null(workers),
      yes = round(parallel::detectCores() * .5),
      no = workers
    )
    plan(multisession, workers = workers)
    on.exit(plan(sequential), add = TRUE)
  } else {
    plan(sequential)
  }
  if (progress) {
    progressr::handlers(global = TRUE)
    on.exit(progressr::handlers(global = FALSE), add = TRUE)
  }
  p <- progressr::progressor(along = plot_id)
  init_time <- Sys.time()
  out <- foreach(i = plot_id) %dofuture% {
    p(sprintf("plot_id = %g", i))
    modeler(
      x = x,
      index = index,
      plot_id = i,
      check_negative = check_negative,
      add_zero = add_zero,
      max_as_last = max_as_last,
      method = method,
      return_method = return_method,
      parameters = parameters,
      lower = lower,
      upper = upper,
      initial_vals = initial_vals,
      fixed_params = fixed_params,
      fn = fn,
      metric = metric,
      n_points = n_points,
      max_time = max_time,
      control = control
    )
  }
  end_time <- Sys.time()
  res <- list()
  res$param <- do.call(rbind, lapply(out, function(x) x$param))
  res$dt <- do.call(rbind, lapply(out, function(x) x$dt))
  res$fn <- out[[1]]$fn
  res$metrics <- do.call(rbind, lapply(out, function(x) x$metrics))
  res$max_time <- max(do.call(c, lapply(out, function(x) x$max_time)))
  res$execution <- end_time - init_time
  class(res) <- "modeler_HTP"
  return(invisible(res))
}
