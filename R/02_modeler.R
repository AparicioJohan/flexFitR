#' Modeler: Non-linear regression for curve fitting
#'
#' @description
#' A versatile function for performing non-linear least squares optimization on grouped data.
#' It supports customizable optimization methods, flexible initial/fixed parameters, and parallel processing.
#' @param data A \code{data.frame} containing the input data for analysis.
#' @param x The name of the column in \code{data} representing the independent variable (x points).
#' @param y The name of the column in \code{data} containing the dependent variable to analyze (response variable).
#' @param grp Column(s) in \code{data} used as grouping variable(s). Defaults to \code{NULL}. (Optional)
#' @param keep Names of columns to retain in the output. Defaults to \code{NULL}. (Optional)
#' @param fn A string. The name of the function used for curve fitting.
#'   Example: \code{"fn_lin"}. Defaults to \code{"fn_lin_plat"}.
#' @param parameters A numeric vector, named list, or \code{data.frame} providing initial values for parameters:
#'   \describe{
#'     \item{Numeric vector}{Named vector specifying initial values (e.g., \code{c(k = 0.5, t1 = 30)}).}
#'     \item{Data frame}{Requires a \code{uid} column with group IDs and parameter values for each group.}
#'     \item{List}{Named list where parameter values can be numeric or expressions (e.g., \code{list(k = "max(y)", t1 = 40)}).}
#'   }
#'   Defaults to \code{NULL}.
#' @param lower A numeric vector specifying lower bounds for parameters. Defaults to \code{-Inf} for all parameters.
#' @param upper A numeric vector specifying upper bounds for parameters. Defaults to \code{Inf} for all parameters.
#' @param fixed_params A list or \code{data.frame} for fixing specific parameters:
#'   \describe{
#'     \item{List}{Named list where parameter values can be numeric or expressions (e.g., \code{list(k = "max(y)", t1 = 40)}).}
#'     \item{Data frame}{Requires a \code{uid} column for group IDs and fixed parameter values.}
#'   }
#'   Defaults to \code{NULL}.
#' @param method A character vector specifying optimization methods.
#'   Check available methods using \code{list_methods()} and their dependencies using
#'   \code{optimx::checkallsolvers()}. Defaults to \code{c("subplex", "pracmanm", "anms")}.
#' @param subset A vector (optional) containing levels of \code{grp} to filter the data for analysis.
#'   Defaults to \code{NULL} (all groups are included).
#' @param options A list of additional options. See \code{modeler.options()}
#' \describe{
#'   \item{\code{progress}}{Logical. If \code{TRUE} a progress bar is displayed. Default is \code{FALSE}. Try this before running the function: \code{progressr::handlers("progress", "beepr")}.}
#'   \item{\code{parallel}}{Logical. If \code{TRUE} the model fit is performed in parallel. Default is \code{FALSE}.}
#'   \item{\code{workers}}{The number of parallel processes to use. \code{parallel::detectCores()}}
#'   \item{\code{trace}}{If \code{TRUE} , convergence monitoring of the current fit is reported in the console. \code{FALSE} by default.}
#'   \item{\code{return_method}}{ Logical. If \code{TRUE}, includes the optimization method used in the result. Default is \code{FALSE}.}
#' }
#' @param control A list of control parameters to be passed to the optimization function. For example: \code{list(maxit = 500)}.
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
#'     fn = "fn_lin_plat",
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
                    fn = "fn_lin_plat",
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
  if (any(method == "ALL")) {
    list_methods(check_package = TRUE)
    method <- list_methods()
  } else {
    packages <- names(list_methods())[list_methods() %in% method]
    ensure_packages(packages)
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
  fn_name <- fn
  fn_to_opt_flx <- get(fn_name)
  objt <- foreach(
    i = grp_id,
    .options.future = list(
      seed = TRUE,
      globals = structure(TRUE, add = fn_name)
    )
  ) %dofu% {
    p(sprintf("uid = %s", i))
    .fitter_curve(
      data = dt_nest,
      id = i,
      fn = fn_to_opt_flx,
      method = method,
      lower = lower,
      upper = upper,
      trace = trace,
      control = control,
      metadata = metadata,
      fn_str = fn_name
    )
  }
  end_time <- Sys.time()
  # Metrics
  metrics <- do.call(
    what = rbind,
    args = lapply(objt, function(x) {
      x$rr |>
        select(c(uid, method, sse, fevals:convergence)) |>
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
    mutate(.fitted = !!density) |>
    select(x, uid, .fitted) |>
    unique.data.frame()
  # Final data
  dt <- suppressWarnings({
    dt |>
      full_join(y = fitted_vals, by = c("x", "uid")) |>
      full_join(y = .sigma_grp.modeler(objt), by = "uid") |>
      mutate(
        .resid = y - .fitted,
        .std_resid = .resid / .sigma
      ) |>
      mutate(fn_name = fn_name) |>
      select(-.sigma)
  })
  # Output
  if (!return_method) {
    param_mat <- select(param_mat, -method)
  }
  out <- list(
    param = param_mat,
    dt = dt,
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
  attr(out, "options") <- opt.list
  attr(out, "control") <- control
  return(invisible(out))
}

#' General-purpose optimization
#'
#' @description
#' The function .fitter_curve is used internally to find the parameters requested.
#'
#' @param data A nested data.frame with columns <plot, genotype, row, range, data, initials, fx_params>.
#' @param id An optional vector of IDs to filter the data. Default is \code{NULL}, meaning all ids are used.
#' @param fn A function to be used for the curve fitting. Default is \code{"fn_lin_plat"}.
#' @param method A character vector specifying the optimization methods to be used. See \code{optimx} package for available methods. Default is \code{c("subplex", "pracmanm", "anms")}.
#' @param lower Numeric vector specifying the lower bounds for the parameters. Default is \code{-Inf} for all parameters.
#' @param upper Numeric vector specifying the upper bounds for the parameters. Default is \code{Inf} for all parameters.
#' @param control A list of control parameters to be passed to the optimization function. For example, \code{list(maxit = 500)}.
#' @param trace  If \code{TRUE} , convergence monitoring of the current fit is reported in the console. \code{FALSE} by default.
#' @param fn_str A string specifying the name of the function to be used for the curve fitting. Default is \code{"fn_lin_plat"}.
#' @return A list containing the following elements:
#' \describe{
#'   \item{\code{kkopt}}{opm object.}
#'   \item{\code{param}}{Data frame with best solution parameters.}
#'   \item{\code{rr}}{Data frame with all methods tested.}
#'   \item{\code{details}}{Additional details of the best solution.}
#'   \item{\code{hessian}}{Hessian matrix.}
#'   \item{\code{type}}{Data frame describing the type of coefficient (estimable of fixed)}
#'   \item{\code{conv}}{Convergency.}
#'   \item{\code{p}}{Number of parameters estimated.}
#'   \item{\code{n_obs}}{Number of observations.}
#'   \item{\code{uid}}{Unique identifier.}
#'   \item{\code{fn_name}}{Name of the curve-fitting function used.}
#' }
#' @export
#' @keywords internal
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
                          trace,
                          fn_str) {
  dt <- data[data$uid == id, ]
  initials <- unlist(dt$initials)
  fx_params <- unlist(dt$fx_params)
  nested_data <- unnest(dt, data)
  t <- nested_data$x
  y <- nested_data$y
  names_params <- names(initials)
  p <- length(names_params)
  ans_sols_list <- vector("list", length(method))
  names(ans_sols_list) <- method
  params_list <- list()
  for (i in seq_along(method)) {
    s <- method[i]
    ans <- suppressWarnings(
      optimr(
        par = initials,
        fn = minimizer,
        t = t,
        y = y,
        curve = fn,
        fixed_params = fx_params,
        trace = trace,
        method = s,
        lower = lower,
        upper = upper,
        control = control
      )
    )
    params <- ans$par
    names(params) <- names_params
    params_list[[s]] <- params
    solution <- data.frame(
      method = s,
      t(params),
      sse = ans$value,
      fevals = ans$scounts[1],
      convergence = ans$convergence
    )
    ans_sols_list[[i]] <- solution
  }
  ans_sols <- do.call(rbind, ans_sols_list)
  # metadata
  rr <- data.frame(
    cbind(dt[, c("uid", metadata)], cbind(ans_sols, t(fx_params))),
    row.names = NULL,
    check.names = FALSE
  )
  best <- rr$method[which.min(rr$sse)]
  best_params <- params_list[[best]]
  param <- rr |>
    dplyr::filter(method == best) |>
    dplyr::select(-c(fevals:convergence)) |>
    dplyr::mutate(fn_name = fn_str)
  # Compute jacobian and hessian only for best
  jac_matrix <- NULL
  hess_matrix <- NULL
  if (!any(is.na(best_params))) {
    jac_matrix <- numDeriv::jacobian(
      func = minimizer,
      x = best_params,
      t = t,
      y = y,
      curve = fn,
      fixed_params = fx_params
    )
    hess_matrix <- numDeriv::hessian(
      func = minimizer,
      x = best_params,
      t = t,
      y = y,
      curve = fn,
      fixed_params = fx_params
    )
  }
  if (is.null(hess_matrix)) {
    hess_matrix <- matrix(NA, nrow = p, ncol = p)
  }
  dimnames(hess_matrix) <- list(names_params, names_params)
  coef <- data.frame(
    parameter = c(names_params, names(fx_params)),
    value = unlist(c(best_params, na.omit(fx_params))),
    type = c(
      rep("estimable", times = p),
      rep("fixed", times = length(names(fx_params)))
    ),
    row.names = NULL
  )
  out <- list(
    kkopt = ans_sols,
    param = param,
    rr = rr,
    details = list(method = best, ngatend = jac_matrix, nhatend = hess_matrix),
    hessian = hess_matrix,
    type = coef,
    lower = lower,
    upper = upper,
    conv = rr[rr$method == best, "convergence"],
    x = t,
    y = y,
    p = p,
    n_obs = length(t),
    uid = id,
    fn_name = fn_str
  )
  return(out)
}

.fitter_curve2 <- function(data,
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
  ans_details <- ans_sols <- list()
  names_params <- names(initials)
  for (s in method) {
    ans <- suppressWarnings(
      optimr(
        par = initials,
        fn = minimizer,
        t = t,
        y = y,
        curve = fn,
        fixed_params = fx_params,
        trace = trace,
        method = s,
        lower = lower,
        upper = upper,
        control = control
      )
    )
    .params <- ans$par
    names(.params) <- names_params
    solution <- data.frame(
      method = s,
      t(.params),
      sse = ans$value,
      fevals = ans$scounts[1],
      convergence = ans$convergence
    )
    jac_matrix <- NULL
    hess_matrix <- NULL
    if (!any(is.na(.params))) { #  ans$convergence == 0
      jac_matrix <- numDeriv::jacobian(
        func = minimizer,
        x = ans$par,
        t = t,
        y = y,
        curve = fn,
        fixed_params = fx_params
      )
      hess_matrix <- numDeriv::hessian(
        func = minimizer,
        x = ans$par,
        t = t,
        y = y,
        curve = fn,
        fixed_params = fx_params
      )
    }
    point <- list(method = s, ngatend = jac_matrix, nhatend = hess_matrix)
    ans_sols <- rbind(ans_sols, solution)
    ans_details <- rbind(ans_details, point)
  }
  row.names(ans_details) <- method
  row.names(ans_sols) <- method
  # metadata
  rr <- data.frame(
    cbind(dt[, c("uid", metadata)], cbind(ans_sols, t(fx_params))),
    row.names = NULL,
    check.names = FALSE
  )
  best <- rr$method[which.min(rr$sse)]
  param <- rr |>
    dplyr::filter(method == best) |>
    dplyr::select(-c(fevals:convergence)) |>
    dplyr::mutate(fn_name = fn)
  # attributes
  details <- ans_details[best, ]
  hessian <- details$nhatend
  coeff <- ans_sols[, names_params]
  if (is.null(hessian)) {
    hessian <- matrix(NA, nrow = ncol(coeff), ncol = ncol(coeff))
  }
  dimnames(hessian) <- list(names_params, names_params)
  coef <- data.frame(
    parameter = c(names_params, names(fx_params)),
    value = na.omit(unlist(c(coeff[best, ], fx_params))),
    type = c(
      rep("estimable", times = length(names_params)),
      rep("fixed", times = length(names(fx_params)))
    ),
    row.names = NULL
  )
  out <- list(
    kkopt = ans_sols,
    param = param,
    rr = rr,
    details = details,
    hessian = hessian,
    type = coef,
    conv = rr[rr$method == best, "convergence"],
    x = t,
    y = y,
    p = length(names_params),
    n_obs = length(t),
    uid = id,
    fn_name = fn
  )
  return(out)
}

# .fitter_curve2 <- function(data,
#                            id,
#                            fn,
#                            method,
#                            lower,
#                            upper,
#                            control,
#                            metadata,
#                            trace) {
#   dt <- data[data$uid == id, ]
#   initials <- unlist(dt$initials)
#   fx_params <- unlist(dt$fx_params)
#   t <- unnest(dt, data)$x
#   y <- unnest(dt, data)$y
#   kkopt <- opm(
#     par = initials,
#     fn = minimizer,
#     t = t,
#     y = y,
#     curve = fn,
#     fixed_params = fx_params,
#     method = method,
#     trace = trace,
#     lower = lower,
#     upper = upper,
#     control = control
#   )
#   # metadata
#   rr <- cbind(
#     dt[, c("uid", metadata)],
#     kkopt |>
#       tibble::rownames_to_column(var = "method") |>
#       dplyr::rename(sse = value) |>
#       cbind(t(fx_params))
#   )
#   best <- rr$method[which.min(rr$sse)]
#   param <- rr |>
#     dplyr::filter(method == best) |>
#     dplyr::select(-c(fevals:xtime)) |>
#     dplyr::mutate(fn_name = fn)
#   # attributes
#   details <- attr(kkopt, "details")[best, ]
#   hessian <- details$nhatend
#   coeff <- coef(kkopt)
#   if (all(is.na(details$hev))) {
#     hessian <- matrix(NA, nrow = ncol(coeff), ncol = ncol(coeff))
#   }
#   est_params <- colnames(coeff)
#   dimnames(hessian) <- list(est_params, est_params)
#   coef <- data.frame(
#     parameter = c(est_params, names(fx_params)),
#     value = na.omit(c(coeff[best, ], fx_params)),
#     type = c(
#       rep("estimable", times = length(est_params)),
#       rep("fixed", times = length(names(fx_params)))
#     ),
#     row.names = NULL
#   )
#   out <- list(
#     kkopt = kkopt,
#     param = param,
#     rr = rr,
#     details = details,
#     hessian = hessian,
#     type = coef,
#     conv = rr[rr$method == best, "convergence"],
#     x = t,
#     y = y,
#     p = length(est_params),
#     n_obs = length(t),
#     uid = id,
#     fn_name = fn
#   )
#   return(out)
# }

# .eval_fun <- function(obj, names) {
#   .method <- attr(obj$value, "method")
#   .params <- obj$par
#   names(.params) <- names
#   .solution <- data.frame(
#     method = .method,
#     t(.params),
#     sse = obj$value,
#     fevals = obj$scounts[1],
#     convergence = obj$convergence,
#     xtime = as.numeric(obj$xtime)
#   )
#   jac_matrix <- NULL
#   hess_matrix <- NULL
#   if (obj$convergence == 0) {
#     jac_matrix <- numDeriv::jacobian(
#       func = minimizer,
#       x = obj$par,
#       t = t,
#       y = y,
#       curve = fn,
#       fixed_params = fx_params
#     )
#     hess_matrix <- numDeriv::hessian(
#       func = minimizer,
#       x = obj$par,
#       t = t,
#       y = y,
#       curve = fn,
#       fixed_params = fx_params
#     )
#   }
#   .mat <- list(method = .method, ngatend = jac_matrix, nhatend = hess_matrix)
#   return(list(ans = .solution, details = .mat))
# }


#' Extract fitted values from a \code{modeler} object
#'
#' @aliases fitted.modeler
#' @param object An object of class `modeler`
#' @param ... Additional parameters for future functionality.
#' @author Johan Aparicio [aut]
#' @method fitted modeler
#' @return A numeric vector of fitted values.
#' @export
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
#' fitted(mod_1)
#' @export
fitted.modeler <- function(object, ...) {
  if (!inherits(object, "modeler")) {
    stop("The object must be of class 'modeler'.")
  }
  fitted_vals <- object$dt$.fitted
  return(fitted_vals)
}

#' Extract residuals from a \code{modeler} object
#'
#' @aliases residuals.modeler
#' @param object An object of class `modeler`
#' @param ... Additional parameters for future functionality.
#' @author Johan Aparicio [aut]
#' @method residuals modeler
#' @return A numeric vector of residuals
#' @export
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
#' residuals(mod_1)
#' @export
residuals.modeler <- function(object, ...) {
  if (!inherits(object, "modeler")) {
    stop("The object must be of class 'modeler'.")
  }
  resid_vals <- object$dt$.resid
  return(resid_vals)
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
