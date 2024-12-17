#' Modeler: Non-linear Regression for Curve Fitting
#'
#' @description
#' A versatile function for performing non-linear least squares optimization on grouped data.
#' It supports customizable optimization methods, flexible initial/fixed parameters, and parallel processing.
#' @param data A `data.frame` containing the input data for analysis.
#' @param x The name of the column in `data` representing the independent variable (x points).
#' @param y The name of the column in `data` containing the dependent variable to analyze (response variable).
#' @param grp Column(s) in `data` used as grouping variable(s). Defaults to `NULL`. (optional)
#' @param keep Names of columns to retain in the output. Defaults to `NULL`. (Optional)
#' @param fn A string. The name of the function used for curve fitting.
#'   Example: `"fn_linear_sat"`. Defaults to \code{"fn_linear_sat"}.
#' @param parameters A numeric vector, named list, or `data.frame` providing initial values for parameters:
#'   \describe{
#'     \item{Numeric vector}{Named vector specifying initial values (e.g., `c(k = 0.5, t1 = 30)`).}
#'     \item{Data frame}{Requires a `uid` column with group IDs and parameter values for each group.}
#'     \item{List}{Named list where parameter values can be numeric or expressions (e.g., `list(k = "max(y)", t1 = 40)`).}
#'   }
#'   Defaults to `NULL`.
#' @param lower A numeric vector specifying lower bounds for parameters. Defaults to `-Inf` for all parameters.
#' @param upper A numeric vector specifying upper bounds for parameters. Defaults to `Inf` for all parameters.
#' @param fixed_params A list or `data.frame` for fixing specific parameters:
#'   \describe{
#'     \item{List}{Named list where parameter values can be numeric or expressions (e.g., `list(k = "max(y)", t1 = 40)`).}
#'     \item{Data frame}{Requires a `uid` column for group IDs and fixed parameter values.}
#'   }
#'   Defaults to `NULL`.
#' @param method A character vector specifying optimization methods.
#'   Check available methods using \code{list_methods()} and their dependencies using
#'   \code{optimx::checkallsolvers()}. Defaults to \code{c("subplex", "pracmanm", "anms")}.
#' @param subset A vector (optional) containing levels of `grp` to filter the data for analysis.
#'   Defaults to `NULL` (all groups are included).
#' @param options A list of additional options. See `modeler.options()`
#' \describe{
#'   \item{\code{add_zero}}{Logical. If \code{TRUE}, adds a zero value to the series at the start. Default is \code{FALSE}.}
#'   \item{\code{check_negative}}{Logical. If \code{TRUE}, converts negative values in the data to zero. Default is \code{FALSE}.}
#'   \item{\code{max_as_last}}{Logical. If \code{TRUE}, appends the maximum value after reaching the maximum. Default is \code{FALSE}.}
#'   \item{\code{progress}}{Logical. If \code{TRUE} a progress bar is displayed. Default is \code{FALSE}. Try this before running the function: \code{progressr::handlers("progress", "beepr")}.}
#'   \item{\code{parallel}}{Logical. If \code{TRUE} the model fit is performed in parallel. Default is \code{FALSE}.}
#'   \item{\code{workers}}{The number of parallel processes to use. `parallel::detectCores()`}
#'   \item{\code{trace}}{If \code{TRUE} , convergence monitoring of the current fit is reported in the console. \code{FALSE} by default.}
#'   \item{\code{return_method}}{ Logical. If \code{TRUE}, includes the optimization method used in the result. Default is \code{FALSE}.}
#' }
#' @param control A list of control parameters to be passed to the optimization function. For example: \code{list(maxit = 500)}.
#' @return An object of class \code{modeler}, which is a list containing the following elements:
#' \describe{
#'   \item{\code{param}}{Data frame containing optimized parameters and related information.}
#'   \item{\code{dt}}{Data frame with input data, fitted values, and residuals.}
#'   \item{\code{fn}}{The function call used for fitting models.}
#'   \item{\code{metrics}}{Metrics and summary of the models.}
#'   \item{\code{execution}}{Total execution time for the analysis.}
#'   \item{\code{response}}{Name of the response variable analyzed.}
#'   \item{\code{keep}}{Metadata retained based on the `keep` argument.}
#'   \item{\code{fun}}{Name of the curve-fitting function used.}
#'   \item{\code{parallel}}{List containing parallel execution details (if applicable).}
#'   \item{\code{fit}}{List of fitted models for each group.}
#' }
#' @export
#'
#' @examples
#' library(flexFitR)
#' data(dt_potato)
#' explorer <- explorer(dt_potato, x = DAP, y = c(Canopy, GLI), id = Plot)
#' # Example 1
#' mod_1 <- dt_potato |>
#'   modeler(
#'     x = DAP,
#'     y = GLI,
#'     grp = Plot,
#'     fn = "fn_lin_pl_lin",
#'     parameters = c(t1 = 38.7, t2 = 62, t3 = 90, k = 0.32, beta = -0.01),
#'     subset = 195
#'   )
#' plot(mod_1, id = 195)
#' print(mod_1)
#' # Example 2
#' mod_2 <- dt_potato |>
#'   modeler(
#'     x = DAP,
#'     y = Canopy,
#'     grp = Plot,
#'     fn = "fn_linear_sat",
#'     parameters = c(t1 = 45, t2 = 80, k = 0.9),
#'     subset = 195
#'   )
#' plot(mod_2, id = 195)
#' print(mod_2)
#' @import optimx
#' @import tibble
#' @import dplyr
#' @import foreach
modeler <- function(data,
                    x,
                    y,
                    grp,
                    keep,
                    fn = "fn_linear_sat",
                    parameters = NULL,
                    lower = -Inf,
                    upper = Inf,
                    fixed_params = NULL,
                    method = c("subplex", "pracmanm", "anms"),
                    subset = NULL,
                    options = modeler.options(),
                    control = list()) {
  if (is.null(data)) {
    stop("Error: data not found")
  }
  x <- explorer(data, {{ x }}, {{ y }}, {{ grp }}, {{ keep }})
  # Check the class of x
  if (!inherits(x, "explorer")) {
    stop("The object should be of class 'explorer'.")
  }
  metadata <- x$metadata
  variable <- unique(x$summ_vars$var)
  if (length(variable) != 1) stop("Only single response is allowed.")
  # Validate options
  if (!is.null(options) && inherits(options, what = "list")) {
    if (any(!names(options) %in% names(modeler.options()))) {
      stop(
        "Options availables in modeler.options() \n \t",
        paste(names(modeler.options()), collapse = ", ")
      )
    } else {
      opt.list <- modeler.options()
      opt.list[names(options)] <- options[names(options) %in% names(opt.list)]
      add_zero <- opt.list[["add_zero"]]
      check_negative <- opt.list[["check_negative"]]
      max_as_last <- opt.list[["max_as_last"]]
      progress <- opt.list[["progress"]]
      parallel <- opt.list[["parallel"]]
      workers <- opt.list[["workers"]]
      trace <- opt.list[["trace"]]
      return_method <- opt.list[["return_method"]]
    }
  }
  # Validate and extract argument names for the function
  args <- try(expr = names(formals(fn))[-1], silent = TRUE)
  if (inherits(args, "try-error")) {
    stop("Please verify the function: '", fn, "'. It was not found.")
  }
  # Validate lower and upper
  if (!is.numeric(lower) || !is.numeric(upper)) {
    stop("Lower and upper bounds should be numeric.")
  }
  # Data transformation
  dt <- x$dt_long |>
    filter(var %in% variable) |>
    filter(!is.na(y)) |>
    droplevels()
  if (max_as_last) {
    dt <- dt |>
      group_by(uid, across(all_of(metadata))) |>
      mutate(max = max(y, na.rm = TRUE), pos = x[which.max(y)]) |>
      mutate(y = ifelse(x <= pos, y, max)) |>
      select(-max, -pos) |>
      ungroup()
  }
  if (check_negative) {
    dt <- mutate(dt, y = ifelse(y < 0, 0, y))
  }
  if (add_zero) {
    dt <- dt |>
      mutate(x = 0, y = 0) |>
      unique.data.frame() |>
      rbind.data.frame(dt) |>
      arrange(uid, x)
  }
  # Validate fixed parameters
  if (!is.null(fixed_params)) {
    if ("data.frame" %in% class(fixed_params)) {
      nam_fix_params <- colnames(fixed_params)[-1]
      if (!all(c("uid") %in% colnames(fixed_params))) {
        stop("fixed_params should contain column 'uid'.")
      }
    } else if ("list" %in% class(fixed_params)) {
      nam_fix_params <- names(fixed_params)
    }
    if (!all(nam_fix_params %in% args)) {
      stop("All fixed_params must be in:", fn)
    }
    if (length(args) - length(nam_fix_params) <= 1) {
      stop("More than one parameter needs to be free.")
    }
  }
  # Validate initial values
  if (is.null(parameters)) {
    stop("Initial parameters need to be provided.")
  } else if (is.numeric(parameters)) { # Numeric Vector
    if (!sum(names(parameters) %in% args) == length(args)) {
      stop("names of parameters have to be in: ", fn)
    }
    init <- dt |>
      select(uid) |>
      unique.data.frame() |>
      cbind(data.frame(t(parameters))) |>
      pivot_longer(cols = -c(uid), names_to = "coef") |>
      nest_by(uid, .key = "initials") |>
      mutate(initials = list(pull(initials, value, coef)))
  } else if ("data.frame" %in% class(parameters)) { # Data.frame
    nam_ini_vals <- colnames(parameters)
    if (!"uid" %in% nam_ini_vals) {
      stop("parameters should contain columns 'uid'.")
    }
    if (!sum(nam_ini_vals[-c(1)] %in% args) == length(args)) {
      stop("parameters should have the same parameters as the function: ", fn)
    }
    init <- parameters |>
      pivot_longer(cols = -c(uid), names_to = "coef") |>
      nest_by(uid, .key = "initials") |>
      mutate(initials = list(pull(initials, value, coef)))
  } else if ("list" %in% class(parameters)) { # List
    if (!sum(names(parameters) %in% args) == length(args)) {
      stop("parameters should have the same parameters as the function: ", fn)
    }
    init <- dt |>
      select(uid, x, y) |>
      group_by(uid)
    for (j in names(parameters)) {
      str <- parameters[[j]]
      if ("numeric" %in% class(str)) {
        express <- str
      } else if ("character" %in% class(str)) {
        express <- rlang::parse_expr(str)
      }
      init <- mutate(init, "{j}" := !!express)
    }
    init <- init |>
      ungroup() |>
      select(uid, all_of(names(parameters))) |>
      unique.data.frame() |>
      pivot_longer(cols = -c(uid), names_to = "coef") |>
      nest_by(uid, .key = "initials") |>
      mutate(initials = list(pull(initials, value, coef)))
  }
  # Merging with fixed parameters
  if (!is.null(fixed_params)) {
    if ("data.frame" %in% class(fixed_params)) {
      fixed <- fixed_params |>
        pivot_longer(cols = -c(uid), names_to = "coef") |>
        nest_by(uid, .key = "fx_params") |>
        mutate(fx_params = list(pull(fx_params, value, coef)))
    } else if ("list" %in% class(fixed_params)) {
      fixed <- dt |>
        select(uid, x, y) |>
        group_by(uid)
      for (j in names(fixed_params)) {
        str <- fixed_params[[j]]
        if ("numeric" %in% class(str)) {
          express <- str
        } else if ("character" %in% class(str)) {
          express <- rlang::parse_expr(str)
        }
        fixed <- mutate(fixed, "{j}" := !!express)
      }
      fixed <- fixed |>
        ungroup() |>
        select(uid, all_of(names(fixed_params))) |>
        unique.data.frame() |>
        pivot_longer(cols = -c(uid), names_to = "coef") |>
        nest_by(uid, .key = "fx_params") |>
        mutate(fx_params = list(pull(fx_params, value, coef)))
    }
    init <- init |>
      full_join(fixed, by = c("uid")) |>
      mutate(
        initials = list(initials[!names(initials) %in% names(fixed_params)])
      )
  } else {
    fixed <- dt |>
      select(uid) |>
      unique.data.frame() |>
      nest_by(uid, .key = "fx_params") |>
      mutate(fx_params = list(NA))
    init <- full_join(init, fixed, by = c("uid"))
  }
  if (!is.null(subset)) {
    dt <- droplevels(filter(dt, uid %in% subset))
    init <- droplevels(filter(init, uid %in% subset))
    fixed <- droplevels(filter(fixed, uid %in% subset))
  }
  dt_nest <- dt |>
    nest_by(uid, across(all_of(metadata))) |>
    full_join(init, by = c("uid"))
  if (nrow(dt_nest) == 0) {
    stop("Check the ids for which you are filtering.")
  }
  if (any(unlist(lapply(dt_nest$fx_params, is.null)))) {
    stop(
      "Fitting models for all ids but 'fixed_params' has only a few.
       Check the argument 'subset'"
    )
  }
  # Parallel
  `%dofu%` <- doFuture::`%dofuture%`
  grp_id <- unique(dt_nest$uid)
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
  p <- progressr::progressor(along = grp_id)
  init_time <- Sys.time()
  objt <- foreach(
    i = grp_id,
    .options.future = list(seed = TRUE)
  ) %dofu% {
    p(sprintf("uid = %s", i))
    .fitter_curve(
      data = dt_nest,
      id = i,
      fn = fn,
      method = method,
      lower = lower,
      upper = upper,
      trace = trace,
      control = control,
      metadata = metadata
    )
  }
  end_time <- Sys.time()
  # Metrics
  metrics <- do.call(
    what = rbind,
    args = lapply(objt, function(x) {
      x$rr |>
        select(c(uid, method, sse, fevals:xtime)) |>
        as_tibble()
    })
  )
  # Selecting the best
  param_mat <- do.call(rbind, lapply(objt, function(x) as_tibble(x$param)))
  if (is.null(fixed_params)) {
    param_mat <- param_mat |> select(-`t(fx_params)`)
  }
  # Fitted values
  density <- create_call(fn)
  fitted_vals <- dt |>
    select(x, uid) |>
    full_join(param_mat, by = "uid") |>
    rowwise() |>
    mutate(.fitted = !!density) |>
    select(x, uid, .fitted)
  # Final data
  dt <- suppressWarnings({
    dt |>
      full_join(y = fitted_vals, by = c("x", "uid")) |>
      mutate(.residual = y - .fitted)
  })
  # Output
  if (!return_method) {
    param_mat <- select(param_mat, -method)
  }
  out <- list(
    param = param_mat,
    dt = dt,
    fn = density,
    metrics = metrics,
    execution = end_time - init_time,
    response = variable,
    x_var = x$x_var,
    keep = metadata,
    fun = fn,
    parallel = list("parallel" = parallel, "workers" = workers),
    fit = objt
  )
  class(out) <- "modeler"
  return(invisible(out))
}

#' General-purpose optimization
#'
#' @description
#' The function .fitter_curve is used internally to find the parameters requested.
#'
#' @param data A nested data.frame with columns <plot, genotype, row, range, data, initials, fx_params>.
#' @param id An optional vector of IDs to filter the data. Default is \code{NULL}, meaning all ids are used.
#' @param fn A string specifying the name of the function to be used for the curve fitting. Default is \code{"fn_linear_sat"}.
#' @param method A character vector specifying the optimization methods to be used. See \code{optimx} package for available methods. Default is \code{c("subplex", "pracmanm", "anms")}.
#' @param lower Numeric vector specifying the lower bounds for the parameters. Default is \code{-Inf} for all parameters.
#' @param upper Numeric vector specifying the upper bounds for the parameters. Default is \code{Inf} for all parameters.
#' @param control A list of control parameters to be passed to the optimization function. For example, \code{list(maxit = 500)}.
#' @param trace  If \code{TRUE} , convergence monitoring of the current fit is reported in the console. \code{FALSE} by default.
#' @export
#' @keywords internal
#'
#' @examples
#' library(flexFitR)
#' data(dt_potato)
#' mod_1 <- dt_potato |>
#'   modeler(
#'     x = DAP,
#'     y = GLI,
#'     grp = Plot,
#'     fn = "fn_lin_pl_lin",
#'     parameters = c(t1 = 38.7, t2 = 62, t3 = 90, k = 0.32, beta = -0.01),
#'     subset = 195,
#'     options = list(add_zero = TRUE)
#'   )
#' @import optimx
#' @import tibble
#' @import tidyr
#' @import dplyr
#' @import subplex
#' @importFrom stats na.omit
#' @importFrom stats qnorm
.fitter_curve <- function(data,
                          id,
                          fn,
                          method,
                          lower,
                          upper,
                          control,
                          metadata,
                          trace) {
  dt <- data[data$uid == id, ]
  initials <- unlist(dt$initials)
  fx_params <- unlist(dt$fx_params)
  t <- unnest(dt, data)$x
  y <- unnest(dt, data)$y
  kkopt <- opm(
    par = initials,
    fn = minimizer,
    t = t,
    y = y,
    curve = fn,
    fixed_params = fx_params,
    metric = "sse",
    method = method,
    trace = trace,
    lower = lower,
    upper = upper,
    control = control
  )
  # metadata
  rr <- cbind(
    dt[, c("uid", metadata)],
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
  coeff <- coef(kkopt)
  if (all(is.na(details$hev))) {
    hessian <- matrix(NA, nrow = ncol(coeff), ncol = ncol(coeff))
  }
  est_params <- colnames(coeff)
  dimnames(hessian) <- list(est_params, est_params)
  coef <- data.frame(
    parameter = c(est_params, names(fx_params)),
    value = na.omit(c(coeff[best, ], fx_params)),
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
    conv = rr[rr$method == best, "convergence"],
    p = length(est_params),
    n_obs = length(t),
    uid = id
  )
  return(out)
}

#' @noRd
max_as_last <- function(data, metadata) {
  dt_can <- data |>
    group_by(uid, across(all_of(metadata))) |>
    mutate(
      loc_max_at = paste(local_min_max(y, x)$days_max, collapse = "_"),
      loc_max = as.numeric(local_min_max(y, x)$days_max[1])
    ) |>
    mutate(loc_max = ifelse(is.na(loc_max), max(x, na.rm = TRUE), loc_max)) |>
    mutate(y = ifelse(x <= loc_max, y, y[x == loc_max])) |>
    select(-loc_max_at, -loc_max) |>
    ungroup()
  return(dt_can)
}

#' @noRd
local_min_max <- function(x, days) {
  up <- c(x[-1], NA)
  down <- c(NA, x[-length(x)])
  a <- cbind(x, up, down)
  minima <- which(apply(a, 1, min) == a[, 1])
  maxima <- which(apply(a, 1, max) == a[, 1])
  list(
    minima = minima,
    days_min = days[minima],
    maxima = maxima,
    days_max = days[maxima]
  )
}

modeler.options <- function(
    add_zero = FALSE,
    check_negative = FALSE,
    max_as_last = FALSE,
    progress = FALSE,
    parallel = FALSE,
    workers = max(1, parallel::detectCores(), na.rm = TRUE),
    trace = FALSE,
    return_method = FALSE) {
  list(
    add_zero = add_zero,
    check_negative = check_negative,
    max_as_last = max_as_last,
    progress = progress,
    parallel = parallel,
    workers = workers,
    trace = trace,
    return_method = return_method
  )
}
