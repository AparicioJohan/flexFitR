#' Modeler
#'
#' @description
#' General-purpose optimization techniques for non-linear least squares problems.
#'
#' @param data A data.frame in a wide format.
#' @param x The name of the column in `data` that contains x points.
#' @param y The name of the column in `data` that contain the variable to be analyzed. Must match a var in the data.
#' @param grp The names of the columns in `data` that contains a grouping variable. (Optional).
#' @param keep The names of the columns in `data` to keep across the analysis.
#' @param fn A string specifying the name of the function to be used for the curve fitting. Default is \code{"fn_piwise"}.
#' @param parameters A named numeric vector specifying the initial values for the parameters to be optimized. Default is \code{NULL}.
#' @param lower Numeric vector specifying the lower bounds for the parameters. Default is \code{-Inf} for all parameters.
#' @param upper Numeric vector specifying the upper bounds for the parameters. Default is \code{Inf} for all parameters.
#' @param initial_vals A data frame with columns \code{uid}, and the initial parameter values for each group id. Used for providing specific initial values per group id.
#' @param fixed_params A data frame with columns \code{uid}, and the fixed parameter values for each group id. Used for fixing certain parameters during optimization.
#' @param method A character vector specifying the optimization methods to be used. Check `optimx::checkallsolvers()` for available methods.
#' Default is \code{c("subplex", "pracmanm", "anms")}.
#' @param return_method Logical. If \code{TRUE}, includes the optimization method used in the result. Default is \code{FALSE}.
#' @param subset An optional vector with levels of `grp` to filter the data. Default is \code{NULL}, meaning all groups are used.
#' @param add_zero Logical. If \code{TRUE}, adds a zero value to the series at the start. Default is \code{FALSE}.
#' @param check_negative Logical. If \code{TRUE}, converts negative values in the data to zero. Default is \code{FALSE}.
#' @param max_as_last Logical. If \code{TRUE}, appends the maximum value after reaching the maximum. Default is \code{FALSE}.
#' @param progress Logical. If \code{TRUE} a progress bar is displayed. Default is \code{FALSE}. Try this before running the function: \code{progressr::handlers("progress", "beepr")}.
#' @param parallel Logical. If \code{TRUE} the model fit is performed in parallel. Default is \code{FALSE}.
#' @param workers The number of parallel processes to use. `parallel::detectCores()`
#' @param control A list of control parameters to be passed to the optimization function. For example: \code{list(maxit = 500)}.
#' @return An object of class \code{modeler}, which is a list containing the following elements:
#' \describe{
#'   \item{\code{param}}{A data frame containing the optimized parameters and related information.}
#'   \item{\code{dt}}{A data frame with data used and fitted values.}
#'   \item{\code{fn}}{The call used when fitting models.}
#'   \item{\code{metrics}}{Metrics and summary of the models.}
#'   \item{\code{execution}}{Execution time.}
#'   \item{\code{response}}{Response variable.}
#'   \item{\code{keep}}{Metadata to keep across.}
#'   \item{\code{fun}}{Name of the function.}
#'   \item{\code{fit}}{List with the fitted models.}
#' }
#' @export
#'
#' @examples
#' library(flexFitR)
#' data(dt_potato)
#' explorer <- explorer(dt_potato, x = DAP, y = c(Canopy, GLI_2), id = Plot)
#' # Example 1
#' mod_1 <- dt_potato |>
#'   modeler(
#'     x = DAP,
#'     y = GLI_2,
#'     grp = Plot,
#'     fn = "fn_lin_pl_lin",
#'     parameters = c(t1 = 38.7, t2 = 62, t3 = 90, k = 0.32, beta = -0.01),
#'     subset = 195,
#'     add_zero = TRUE
#'   )
#' plot(mod_1, id = 195)
#' print(mod_1)
#' # Example 2
#' mod_2 <- dt_potato |>
#'   modeler(
#'     x = DAP,
#'     y = Canopy,
#'     grp = Plot,
#'     fn = "fn_piwise",
#'     parameters = c(t1 = 45, t2 = 80, k = 0.9),
#'     subset = 195,
#'     add_zero = TRUE,
#'     max_as_last = TRUE
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
                    fn = "fn_piwise",
                    parameters = NULL,
                    lower = -Inf,
                    upper = Inf,
                    initial_vals = NULL,
                    fixed_params = NULL,
                    method = c("subplex", "pracmanm", "anms"),
                    return_method = FALSE,
                    subset = NULL,
                    add_zero = FALSE,
                    check_negative = FALSE,
                    max_as_last = FALSE,
                    progress = FALSE,
                    parallel = FALSE,
                    workers = max(1, parallel::detectCores(), na.rm = TRUE),
                    control = list()) {
  if (is.null(data)) {
    stop("Error: data not found")
  }
  x <- explorer(data, {{ x }}, {{ y }}, {{ grp }}, {{ keep }})
  # Check the class of x
  if (!inherits(x, "explorer")) {
    stop("The object should be of class 'explorer'.")
  }
  .keep <- x$metadata
  variable <- unique(x$summ_vars$var)
  if (length(variable) != 1) stop("Only single response is allowed.")
  # Validate and extract argument names for the function
  args <- try(expr = names(formals(fn))[-1], silent = TRUE)
  if (inherits(args, "try-error")) {
    stop("Please verify the function: '", fn, "'. It was not found.")
  }
  # Validate initial_vals
  if (!is.null(initial_vals)) {
    nam_ini_vals <- colnames(initial_vals)
    if (!all(c("uid") %in% colnames(initial_vals))) {
      stop("initial_vals should contain columns 'uid'.")
    }
    if (!sum(nam_ini_vals[-c(1)] %in% args) == length(args)) {
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
    if (!all(c("uid") %in% colnames(fixed_params))) {
      stop("fixed_params should contain columns 'uid'.")
    }
    if (!any(nam_fix_params[-c(1)] %in% args)) {
      stop("fixed_params should have at least one parameter of: ", fn)
    }
    if (sum(nam_fix_params[-c(1)] %in% args) == length(args)) {
      stop("fixed_params cannot contain all parameters of the function: ", fn)
    }
  }
  # Validate parameters and initial_vals
  if (is.null(parameters) && is.null(initial_vals)) {
    stop("You have to provide initial values for the optimization procedure")
  } else if (!is.null(parameters)) {
    if (!sum(names(parameters) %in% args) == length(args)) {
      stop("names of parameters have to be in: ", fn)
    }
  }
  dt <- x$dt_long |>
    filter(var %in% variable) |>
    filter(!is.na(y)) |>
    droplevels()
  if (max_as_last) {
    dt <- max_as_last(dt, .keep = .keep)
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
  if (!is.null(initial_vals)) {
    init <- initial_vals |>
      pivot_longer(cols = -c(uid), names_to = "coef") |>
      nest_by(uid, .key = "initials") |>
      mutate(initials = list(pull(initials, value, coef)))
  } else {
    init <- dt |>
      select(uid) |>
      unique.data.frame() |>
      cbind(data.frame(t(parameters))) |>
      pivot_longer(cols = -c(uid), names_to = "coef") |>
      nest_by(uid, .key = "initials") |>
      mutate(initials = list(pull(initials, value, coef)))
  }
  if (!is.null(fixed_params)) {
    fixed <- fixed_params |>
      pivot_longer(cols = -c(uid), names_to = "coef") |>
      nest_by(uid, .key = "fx_params") |>
      mutate(fx_params = list(pull(fx_params, value, coef)))
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
    nest_by(uid, across(all_of(.keep))) |>
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
      control = control,
      .keep = .keep
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
    keep = .keep,
    fun = fn,
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
#' @param fn A string specifying the name of the function to be used for the curve fitting. Default is \code{"fn_piwise"}.
#' @param method A character vector specifying the optimization methods to be used. See \code{optimx} package for available methods. Default is \code{c("subplex", "pracmanm", "anms")}.
#' @param lower Numeric vector specifying the lower bounds for the parameters. Default is \code{-Inf} for all parameters.
#' @param upper Numeric vector specifying the upper bounds for the parameters. Default is \code{Inf} for all parameters.
#' @param control A list of control parameters to be passed to the optimization function. For example, \code{list(maxit = 500)}.
#' @export
#' @keywords internal
#'
#' @examples
#' library(flexFitR)
#' data(dt_potato)
#' explorer <- explorer(dt_potato, x = DAP, y = c(Canopy, GLI_2), id = Plot)
#' mod_1 <- dt_potato |>
#'   modeler(
#'     x = DAP,
#'     y = GLI_2,
#'     grp = Plot,
#'     fn = "fn_lin_pl_lin",
#'     parameters = c(t1 = 38.7, t2 = 62, t3 = 90, k = 0.32, beta = -0.01),
#'     subset = 195,
#'     add_zero = TRUE
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
                          .keep) {
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
    lower = lower,
    upper = upper,
    control = control
  )
  # metadata
  rr <- cbind(
    dt[, c("uid", .keep)],
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
max_as_last <- function(data, .keep) {
  dt_can <- data |>
    group_by(uid, across(all_of(.keep))) |>
    mutate(
      loc_max_at = paste(local_min_max(y, x)$days_max, collapse = "_"),
      loc_max = as.numeric(local_min_max(y, x)$days_max[1])
    ) |>
    mutate(loc_max = ifelse(is.na(loc_max), max(x, na.rm = TRUE), loc_max)) |>
    mutate(
      y = ifelse(x <= loc_max, y, y[x == loc_max])
    ) |>
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
