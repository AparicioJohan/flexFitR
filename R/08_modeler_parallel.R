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
#' @param n_points An integer specifying the number of time points to use for approximating the Area Under the Curve (AUC). Default is \code{1000}.
#' @param max_time Numeric. The maximum time value to use for calculating the AUC. Default is \code{NULL}, which uses the last time point in the data.
#' @param control A list of control parameters to be passed to the optimization function. For example, \code{list(maxit = 500)}.
#' @param progress Logical. If \code{TRUE} a progress bar is displayed. Default is \code{FALSE}. Try this before running the function: \code{progressr::handlers("progress", "beepr")}.
#' @param parallel Logical. If \code{TRUE} the model fit is performed in parallel. Default is \code{FALSE}.
#' @param workers The number of parallel processes to use. `parallel::detectCores()`
#' @return An object of class \code{modeler_HTP}, which is a list containing the following elements:
#' \describe{
#'   \item{\code{param}}{A data frame containing the optimized parameters and related information.}
#'   \item{\code{dt}}{A data frame with data used and fitted values.}
#'   \item{\code{fn}}{The call used to calculate the AUC.}
#'   \item{\code{max_time}}{Maximum time value used for calculating the AUC.}
#'   \item{\code{metrics}}{Metrics and summary of the models.}
#'   \item{\code{execution}}{Execution time.}
#'   \item{\code{response}}{Response variable.}
#' }
#' @export
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
modeler_HTP <- function(x,
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
  # Validate index
  traits <- unique(x$dt_long$trait)
  if (!index %in% traits) {
    stop("Index not found in x. Please verify the spelling.")
  }
  # Validate and extract argument names for the function
  args <- try(expr = names(formals(fn))[-1], silent = TRUE)
  if (inherits(args, "try-error")) {
    stop("Please verify the function: '", fn, "'. It was not found.")
  }
  # Validate initial_vals
  if (!is.null(initial_vals)) {
    nam_ini_vals <- colnames(initial_vals)
    if (!all(c("plot", "genotype") %in% colnames(initial_vals))) {
      stop("initial_vals should contain columns 'plot' and 'genotype'.")
    }
    if (!sum(nam_ini_vals[-c(1:2)] %in% args) == length(args)) {
      stop("initial_vals should have the same parameters as the function: ", fn)
    }
  }
  # Validate parameters
  if (!is.null(parameters) && !is.numeric(parameters)) {
    stop("Parameters should be a named numeric vector.")
  }
  # Validate lower and upper
  if (!is.numeric(lower) || !is.numeric(upper)) {
    stop("Lower and upper bounds should be numeric.")
  }
  # Validate fixed_params
  if (!is.null(fixed_params)) {
    nam_fix_params <- colnames(fixed_params)
    if (!all(c("plot", "genotype") %in% colnames(fixed_params))) {
      stop("fixed_params should contain columns 'plot' and 'genotype'.")
    }
    if (!any(nam_fix_params[-c(1:2)] %in% args)) {
      stop("fixed_params should have at least one parameter of: ", fn)
    }
    if (sum(nam_fix_params[-c(1:2)] %in% args) == length(args)) {
      stop("fixed_params cannot contain all parameters of the function: ", fn)
    }
  }
  # Validate n_points and max_time
  if (!is.numeric(n_points) || n_points <= 0) {
    stop("n_points should be a positive numeric value.")
  }
  if (!is.null(max_time) && (!is.numeric(max_time) || max_time <= 0)) {
    stop("max_time should be a positive numeric value if specified.")
  }
  # Validate parameters and initial_vals
  if (is.null(parameters) & is.null(initial_vals)) {
    stop("You have to provide initial values for the optimization procedure")
  } else if (!is.null(parameters)) {
    if (!sum(names(parameters) %in% args) == length(args)) {
      stop("names of parameters have to be in: ", fn)
    }
  }
  dt <- x$dt_long |>
    filter(trait %in% index) |>
    filter(!is.na(value)) |>
    droplevels()
  if (max_as_last) {
    dt <- max_as_last(dt)
  }
  if (check_negative) {
    dt <- mutate(dt, value = ifelse(value < 0, 0, value))
  }
  if (add_zero) {
    dt <- dt |>
      mutate(time = 0, value = 0) |>
      unique.data.frame() |>
      rbind.data.frame(dt) |>
      arrange(plot, time)
  }
  if (!is.null(initial_vals)) {
    init <- initial_vals |>
      pivot_longer(cols = -c(plot, genotype), names_to = "coef") |>
      nest_by(plot, genotype, .key = "initials") |>
      mutate(initials = list(pull(initials, value, coef)))
  } else {
    init <- dt |>
      select(plot, genotype) |>
      unique.data.frame() |>
      cbind(data.frame(t(parameters))) |>
      pivot_longer(cols = -c(plot, genotype), names_to = "coef") |>
      nest_by(plot, genotype, .key = "initials") |>
      mutate(initials = list(pull(initials, value, coef)))
  }
  if (!is.null(fixed_params)) {
    fixed <- fixed_params |>
      pivot_longer(cols = -c(plot, genotype), names_to = "coef") |>
      nest_by(plot, genotype, .key = "fx_params") |>
      mutate(fx_params = list(pull(fx_params, value, coef)))
    init <- init |>
      full_join(fixed, by = c("plot", "genotype")) |>
      mutate(
        initials = list(initials[!names(initials) %in% names(fixed_params)])
      )
  } else {
    fixed <- dt |>
      select(plot, genotype) |>
      unique.data.frame() |>
      nest_by(plot, genotype, .key = "fx_params") |>
      mutate(fx_params = list(NA))
    init <- full_join(init, fixed, by = c("plot", "genotype"))
  }
  if (!is.null(plot_id)) {
    dt <- droplevels(filter(dt, plot %in% plot_id))
    init <- droplevels(filter(init, plot %in% plot_id))
    fixed <- droplevels(filter(fixed, plot %in% plot_id))
  }
  dt_nest <- dt |>
    nest_by(plot, genotype, row, range) |>
    full_join(init, by = c("plot", "genotype"))
  if (any(unlist(lapply(dt_nest$fx_params, is.null)))) {
    stop(
      "Fitting models for all plots but 'fixed_params' has only a few.
       Check the argument 'plot_id'"
    )
  }
  # Parallel
  `%dofu%` <- doFuture::`%dofuture%`
  plot_id <- unique(dt_nest$plot)
  if (parallel) {
    workers <- ifelse(
      test = is.null(workers),
      yes = round(parallel::detectCores() * .5),
      no = workers
    )
    future::plan(future::multisession, workers = workers)
    on.exit(future::plan(future::sequential), add = TRUE)
  } else {
    future::plan(future::sequential)
  }
  if (progress) {
    progressr::handlers(global = TRUE)
    on.exit(progressr::handlers(global = FALSE), add = TRUE)
  }
  p <- progressr::progressor(along = plot_id)
  init_time <- Sys.time()
  modeler <- foreach(
    i = plot_id,
    # .combine = rbind,
    .options.future = list(seed = TRUE)
  ) %dofu% {
    p(sprintf("plot_id = %g", i))
    .fitter_curve(
      data = dt_nest,
      plot_id = i,
      fn = fn,
      metric = metric,
      method = method,
      lower = lower,
      upper = upper,
      control = control
    )
  }
  end_time <- Sys.time()
  # Metrics
  metrics <- do.call(
    what = rbind,
    args = lapply(modeler, function(x) {
      x$rr |>
        select(c(plot, genotype, method, sse, fevals:xtime)) |>
        as_tibble()
    })
  )
  # Selecting the best
  param_mat <- do.call(rbind, lapply(modeler, function(x) as_tibble(x$param)))
  if (is.null(fixed_params)) {
    param_mat <- param_mat |> select(-`t(fx_params)`)
  }
  if (is.null(max_time)) {
    max_time <- max(dt$time, na.rm = TRUE)
  }
  # AUC
  density <- create_call(fn)
  sq <- seq(0, max_time, length.out = n_points)
  auc <- full_join(
    x = expand.grid(time = sq, plot = unique(dt$plot)),
    y = param_mat,
    by = "plot"
  ) |>
    group_by(time, plot) |>
    mutate(hat = !!density) |>
    group_by(plot) |>
    mutate(trapezoid_area = (lead(hat) + hat) / 2 * (lead(time) - time)) |>
    filter(!is.na(trapezoid_area)) |>
    summarise(auc = sum(trapezoid_area))
  param_mat <- full_join(param_mat, auc, by = "plot")
  # Fitted values
  fitted_vals <- dt |>
    select(time, plot) |>
    full_join(param_mat, by = "plot") |>
    group_by(time, plot) |>
    mutate(.fitted = !!density) |>
    ungroup() |>
    select(time, plot, .fitted)
  dt <- full_join(dt, fitted_vals, by = c("time", "plot"))
  # Output
  if (!return_method) {
    param_mat <- select(param_mat, -method)
  }
  out <- list(
    param = param_mat,
    dt = dt,
    fn = density,
    metrics = metrics,
    max_time = max_time,
    execution = end_time - init_time,
    response = index,
    fun = fn,
    fit = modeler
  )
  class(out) <- "modeler_HTP"
  return(invisible(out))
}


#' General-purpose optimization
#'
#' @description
#' The function .fitter_curve is used internally to find the parameters requested.
#'
#' @param data A nested data.frame with columns <plot, genotype, row, range, data, initials, fx_params>.
#' @param plot_id An optional vector of plot IDs to filter the data. Default is \code{NULL}, meaning all plots are used.
#' @param fn A string specifying the name of the function to be used for the curve fitting. Default is \code{"fn_piwise"}.
#' @param metric A string specifying the metric to minimize during optimization. Options are \code{"sse"}, \code{"mae"}, \code{"mse"}, and \code{"rmse"}. Default is \code{"sse"}.
#' @param method A character vector specifying the optimization methods to be used. See \code{optimx} package for available methods. Default is \code{c("subplex", "pracmanm", "anms")}.
#' @param lower Numeric vector specifying the lower bounds for the parameters. Default is \code{-Inf} for all parameters.
#' @param upper Numeric vector specifying the upper bounds for the parameters. Default is \code{Inf} for all parameters.
#' @param control A list of control parameters to be passed to the optimization function. For example, \code{list(maxit = 500)}.
#' @export
#' @keywords internal
#'
#' @examples
#' library(exploreHTP)
#' suppressMessages(library(dplyr))
#' data(dt_potato)
#' dt_potato <- dt_potato
#' results <- read_HTP(
#'   data = dt_potato,
#'   genotype = "Gen",
#'   time = "DAP",
#'   plot = "Plot",
#'   traits = c("Canopy", "GLI_2"),
#'   row = "Row",
#'   range = "Range"
#' )
#' mod <- modeler_HTP(
#'   x = results,
#'   index = "GLI_2",
#'   plot_id = c(195),
#'   parameters = c(t1 = 38.7, t2 = 62, t3 = 90, k = 0.32, beta = -0.01),
#'   fn = "fn_lin_pl_lin",
#' )
#' @import optimx
#' @import tibble
#' @import tidyr
#' @import dplyr
#' @import subplex
#' @importFrom stats na.omit
#' @importFrom stats qnorm
.fitter_curve <- function(data,
                          plot_id,
                          fn,
                          metric,
                          method,
                          lower,
                          upper,
                          control) {
  dt <- data[data$plot == plot_id, ]
  initials <- unlist(dt$initials)
  fx_params <- unlist(dt$fx_params)
  t <- unnest(dt, data)$time
  y <- unnest(dt, data)$value
  kkopt <- opm(
    par = initials,
    fn = minimizer,
    t = t,
    y = y,
    curve = fn,
    fixed_params = fx_params,
    metric = "sse",
    method = method,
    lower = lower,
    upper = upper,
    control = control
  )
  # metadata
  rr <- cbind(
    dt[, c("plot", "genotype", "row", "range")],
    kkopt |>
      tibble::rownames_to_column(var = "method") |>
      dplyr::rename(sse = value) |>
      cbind(t(fx_params))
  )
  best <- rr$method[which.min(rr$sse)]
  param <- rr |>
    dplyr::filter(method == best) |>
    dplyr::select(-c(fevals:xtime))
  # attributes
  details <- attr(kkopt, "details")[best, ]
  hessian <- details$nhatend
  est_params <- colnames(coef(kkopt))
  dimnames(hessian) <- list(est_params, est_params)
  coef <- data.frame(
    parameter = c(est_params, names(fx_params)),
    value = na.omit(c(coef(kkopt)[best, ], fx_params)),
    type = c(
      rep("estimable", times = length(est_params)),
      rep("fixed", times = length(names(fx_params)))
    ),
    row.names = NULL
  )
  out <- list(
    kkopt = kkopt,
    param = param,
    rr = rr,
    details = details,
    hessian = hessian,
    type = coef,
    p = length(est_params),
    n_obs = length(t),
    plot_id = plot_id
  )
  return(out)
}


# .fitter_curve <- function(data,
#                           plot_id,
#                           fn,
#                           metric,
#                           method,
#                           lower,
#                           upper,
#                           control) {
#   dt <- data[data$plot == plot_id, ]
#   initials <- unlist(dt$initials)
#   fx_params <- unlist(dt$fx_params)
#   t <- unnest(dt, data)$time
#   y <- unnest(dt, data)$value
#   rr <- opm(
#     par = initials,
#     fn = minimizer,
#     t = t,
#     y = y,
#     curve = fn,
#     fixed_params = fx_params,
#     metric = metric,
#     method = method,
#     lower = lower,
#     upper = upper,
#     control = control
#   ) |>
#     tibble::rownames_to_column(var = "method") |>
#     dplyr::rename(sse = value) |>
#     cbind(t(fx_params))
#   rr <- cbind(select(dt, plot, genotype, row, range), rr)
#   return(rr)
# }
