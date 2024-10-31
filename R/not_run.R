# data <- data.frame(
#   time = c(0, 29, 36, 42, 56, 76, 92, 100, 108),
#   variable = c(0, 0, 0.67, 15.11, 77.38, 99.81, 99.81, 99.81, 99.81)
# )
# x = "time"
# y = "variable"
# grp = NULL
# keep = NULL
# fn = "fn_piwise"
# parameters = c(t1 = 45, t2 = 80, k = 0.9)
# lower = -Inf
# upper = Inf
# initial_vals = NULL
# fixed_params = NULL
# method = c("subplex", "pracmanm", "anms")
# return_method = FALSE
# subset = NULL
# add_zero = FALSE
# check_negative = FALSE
# max_as_last = FALSE
# progress = FALSE
# parallel = FALSE
# workers = max(1, parallel::detectCores(), na.rm = TRUE)
# control = list()
#
# formula <- variable ~ fn_piwise(time, t1, t2, k)
# formula <- as.formula(formula)
# var_names <- all.vars(formula)
# form2 <- formula
# form2[[2L]] <- 0
# var_name_LHS <- formula[[2L]]
# var_names_RHS <- all.vars(form2)
# pnames <- names(parameters)
# var_names <- var_names[is.na(match(var_names, pnames))]
# len_var <- function(var) tryCatch(length(eval(as.name(var), data, env)), error = function(e) -1L)
# env <- environment(formula)
# if (length(var_names)) {
#   n <- vapply(var_names, len_var, 0)
#   if (any(not.there <- n == -1L)) {
#     nnn <- names(n[not.there])
#     if (missing(parameters)) {
#       stop("No starting values specified for parameters.")
#     } else {
#       stop(gettextf(
#         "parameters without starting value in 'data': %s",
#         paste(nnn, collapse = ", ")
#       ), domain = NA)
#     }
#   }
# } else {
#   stop("No parameters to fit and/or no data variables present")
# }

# modeler_2 <- function(data,
#                       x,
#                       y,
#                       grp,
#                       keep,
#                       fn = "fn_piwise",
#                       parameters = NULL,
#                       lower = -Inf,
#                       upper = Inf,
#                       initial_vals = NULL,
#                       fixed_params = NULL,
#                       method = c("subplex", "pracmanm", "anms"),
#                       return_method = FALSE,
#                       subset = NULL,
#                       add_zero = FALSE,
#                       check_negative = FALSE,
#                       max_as_last = FALSE,
#                       progress = FALSE,
#                       parallel = FALSE,
#                       workers = max(1, parallel::detectCores(), na.rm = TRUE),
#                       control = list()) {
#   if (is.null(data)) {
#     stop("Error: data not found")
#   }
#   x <- explorer(data, {{ x }}, {{ y }}, {{ grp }}, {{ keep }})
#   # Check the class of x
#   if (!inherits(x, "explorer")) {
#     stop("The object should be of class 'explorer'.")
#   }
#   .keep <- x$metadata
#   variable <- unique(x$summ_vars$var)
#   if (length(variable) != 1) stop("Only single response is allowed.")
#   # Validate and extract argument names for the function
#   args <- try(expr = names(formals(fn))[-1], silent = TRUE)
#   if (inherits(args, "try-error")) {
#     stop("Please verify the function: '", fn, "'. It was not found.")
#   }
#   # Validate initial_vals
#   if (!is.null(initial_vals)) {
#     nam_ini_vals <- colnames(initial_vals)
#     if (!all(c("uid") %in% colnames(initial_vals))) {
#       stop("initial_vals should contain columns 'uid'.")
#     }
#     if (!sum(nam_ini_vals[-c(1)] %in% args) == length(args)) {
#       stop("initial_vals should have the same parameters as the function: ", fn)
#     }
#   }
#   # Validate parameters
#   if (!is.null(parameters) && !is.numeric(parameters)) {
#     stop("Parameters should be a named numeric vector.")
#   }
#   # Validate lower and upper
#   if (!is.numeric(lower) || !is.numeric(upper)) {
#     stop("Lower and upper bounds should be numeric.")
#   }
#   # Validate fixed_params
#   if (!is.null(fixed_params)) {
#     nam_fix_params <- colnames(fixed_params)
#     if (!all(c("uid") %in% colnames(fixed_params))) {
#       stop("fixed_params should contain columns 'uid'.")
#     }
#     if (!any(nam_fix_params[-c(1)] %in% args)) {
#       stop("fixed_params should have at least one parameter of: ", fn)
#     }
#     if (sum(nam_fix_params[-c(1)] %in% args) == length(args)) {
#       stop("fixed_params cannot contain all parameters of the function: ", fn)
#     }
#   }
#   # Validate parameters and initial_vals
#   if (is.null(parameters) && is.null(initial_vals)) {
#     stop("You have to provide initial values for the optimization procedure")
#   } else if (!is.null(parameters)) {
#     if (!sum(names(parameters) %in% args) == length(args)) {
#       stop("names of parameters have to be in: ", fn)
#     }
#   }
#   dt <- x$dt_long |>
#     filter(var %in% variable) |>
#     filter(!is.na(y)) |>
#     droplevels()
#   if (max_as_last) {
#     dt <- dt |>
#       group_by(uid, across(all_of(.keep))) |>
#       mutate(max = max(y, na.rm = TRUE), pos = x[which.max(y)]) |>
#       mutate(y = ifelse(x <= pos, y, max)) |>
#       select(-max, -pos) |>
#       ungroup() # max_as_last(dt, .keep = .keep)
#   }
#   if (check_negative) {
#     dt <- mutate(dt, y = ifelse(y < 0, 0, y))
#   }
#   if (add_zero) {
#     dt <- dt |>
#       mutate(x = 0, y = 0) |>
#       unique.data.frame() |>
#       rbind.data.frame(dt) |>
#       arrange(uid, x)
#   }
#   if (!is.null(initial_vals)) {
#     init <- initial_vals |>
#       pivot_longer(cols = -c(uid), names_to = "coef") |>
#       nest_by(uid, .key = "initials") |>
#       mutate(initials = list(pull(initials, value, coef)))
#   } else {
#     init <- dt |>
#       select(uid) |>
#       unique.data.frame() |>
#       cbind(data.frame(t(parameters))) |>
#       pivot_longer(cols = -c(uid), names_to = "coef") |>
#       nest_by(uid, .key = "initials") |>
#       mutate(initials = list(pull(initials, value, coef)))
#   }
#   if (!is.null(fixed_params)) {
#     fixed <- fixed_params |>
#       pivot_longer(cols = -c(uid), names_to = "coef") |>
#       nest_by(uid, .key = "fx_params") |>
#       mutate(fx_params = list(pull(fx_params, value, coef)))
#     init <- init |>
#       full_join(fixed, by = c("uid")) |>
#       mutate(
#         initials = list(initials[!names(initials) %in% names(fixed_params)])
#       )
#   } else {
#     fixed <- dt |>
#       select(uid) |>
#       unique.data.frame() |>
#       nest_by(uid, .key = "fx_params") |>
#       mutate(fx_params = list(NA))
#     init <- full_join(init, fixed, by = c("uid"))
#   }
#   if (!is.null(subset)) {
#     dt <- droplevels(filter(dt, uid %in% subset))
#     init <- droplevels(filter(init, uid %in% subset))
#     fixed <- droplevels(filter(fixed, uid %in% subset))
#   }
#   dt_nest <- dt |>
#     nest_by(uid, across(all_of(.keep))) |>
#     full_join(init, by = c("uid"))
#   if (nrow(dt_nest) == 0) {
#     stop("Check the ids for which you are filtering.")
#   }
#   if (any(unlist(lapply(dt_nest$fx_params, is.null)))) {
#     stop(
#       "Fitting models for all ids but 'fixed_params' has only a few.
#        Check the argument 'subset'"
#     )
#   }
#   # Parallel
#   `%dofu%` <- doFuture::`%dofuture%`
#   grp_id <- unique(dt_nest$uid)
#   if (parallel) {
#     workers <- ifelse(
#       test = is.null(workers),
#       yes = round(parallel::detectCores() * .5),
#       no = workers
#     )
#     future::plan(future::multisession, workers = workers)
#     on.exit(future::plan(future::sequential), add = TRUE)
#   } else {
#     future::plan(future::sequential)
#   }
#   if (progress) {
#     progressr::handlers(global = TRUE)
#     on.exit(progressr::handlers(global = FALSE), add = TRUE)
#   }
#   p <- progressr::progressor(along = grp_id)
#   init_time <- Sys.time()
#   objt <- foreach(
#     i = grp_id,
#     .options.future = list(seed = TRUE)
#   ) %dofu% {
#     p(sprintf("uid = %s", i))
#     .fitter_curve(
#       data = dt_nest,
#       id = i,
#       fn = fn,
#       method = method,
#       lower = lower,
#       upper = upper,
#       control = control,
#       .keep = .keep
#     )
#   }
#   end_time <- Sys.time()
#   # Metrics
#   metrics <- do.call(
#     what = rbind,
#     args = lapply(objt, function(x) {
#       x$rr |>
#         select(c(uid, method, sse, fevals:xtime)) |>
#         as_tibble()
#     })
#   )
#   # Selecting the best
#   param_mat <- do.call(rbind, lapply(objt, function(x) as_tibble(x$param)))
#   if (is.null(fixed_params)) {
#     param_mat <- param_mat |> select(-`t(fx_params)`)
#   }
#   # Fitted values
#   density <- create_call(fn)
#   fitted_vals <- dt |>
#     select(x, uid) |>
#     full_join(param_mat, by = "uid") |>
#     rowwise() |>
#     mutate(.fitted = !!density) |>
#     select(x, uid, .fitted)
#   # Final data
#   dt <- suppressWarnings({
#     dt |>
#       full_join(y = fitted_vals, by = c("x", "uid")) |>
#       mutate(.residual = y - .fitted)
#   })
#   # Output
#   if (!return_method) {
#     param_mat <- select(param_mat, -method)
#   }
#   out <- list(
#     param = param_mat,
#     dt = dt,
#     fn = density,
#     metrics = metrics,
#     execution = end_time - init_time,
#     response = variable,
#     keep = .keep,
#     fun = fn,
#     fit = objt
#   )
#   class(out) <- "modeler"
#   return(invisible(out))
# }
#
#
# # params <- c(t1 = 34.9, t2 = 61.8)
# # fixed <- c(k = 90)
# # t <- c(0, 29, 36, 42, 56, 76, 92, 100, 108)
# # y <- c(0, 0, 4.379, 26.138, 78.593, 100, 100, 100, 100)
# # fn <- "fn_piwise"
# # minimizer2(params, t, y, fn, fixed_params = fixed, metric = "rmse")
# # res <- opm(
# #   par = params,
# #   fn = minimizer2,
# #   t = t,
# #   y = y,
# #   curve = fn,
# #   fixed_params = fixed,
# #   metric = "sse",
# #   method = c("subplex"),
# #   lower = -Inf,
# #   upper = Inf
# # )
# minimizer2 <- function(params,
#                        t,
#                        y,
#                        curve,
#                        fixed_params = NA,
#                        metric = "sse") {
#   arg <- names(formals(curve))[-1]
#   values <- paste(params, collapse = ", ")
#   if (!any(is.na(fixed_params))) {
#     names(params) <- arg[!arg %in% names(fixed_params)]
#     values <- paste(
#       paste(names(params), params, sep = " = "),
#       collapse = ", "
#     )
#     fix <- paste(
#       paste(names(fixed_params), fixed_params, sep = " = "),
#       collapse = ", "
#     )
#     values <- paste(values, fix, sep = ", ")
#   }
#   string <- paste("sapply(t, FUN = ", curve, ", ", values, ")", sep = "")
#   y_hat <- eval(parse(text = string))
#   sse <- eval(parse(text = paste0(metric, "(y, y_hat)"))) # sum((y - y_hat)^2)
#   return(sse)
# }
#
#
# # data <- data.frame(
# #   time = c(0, 29, 36, 42, 56, 76, 92, 100, 108),
# #   variable = c(0, 0, 4.379, 26.138, 78.593, 100, 100, 100, 100)
# # )
# #
# # formula <- variable ~ fn_piwise(time, t1, t2, k)
# # params <- c(t1 = 34.9, t2 = 61.8)
# # names <- names(params)
# # fixed_params <- NA
# # fixed_params <- c(k = 90)
# #
# # minimizer_new(params, data, formula = formula, names, fixed_params)
# #
# # res <- opm(
# #   par = params,
# #   fn = minimizer_new,
# #   data = data,
# #   formula = formula,
# #   names = names,
# #   fixed_params = fixed_params,
# #   method = c("subplex"),
# #   lower = -Inf,
# #   upper = Inf
# # )
# minimizer_new <- function(params,
#                           data,
#                           formula,
#                           names,
#                           fixed_params = NA) {
#   names(params) <- names
#   y <- data[[all.vars(formula[[2]])]]
#   rhs <- paste(formula[3])
#   e_data <- cbind(data, t(params), t(fixed_params))
#   y_hat <- sapply(
#     X = seq_len(nrow(e_data)),
#     FUN = \(x) eval(parse(text = rhs), envir = e_data[x, , drop = FALSE])
#   )
#   sse <- sum((y - y_hat)^2)
#   return(sse)
# }
#
# minimizer_new2 <- function(params,
#                            data,
#                            formula,
#                            names,
#                            fixed_params = NA) {
#   names(params) <- names
#   y <- data[[all.vars(formula[[2]])]]
#   rhs <- paste(formula[3])
#   env <- new.env()
#   list2env(data, envir = env)
#   list2env(as.list(na.omit(c(params, fixed_params))), envir = env)
#   fn_piwise <- Vectorize(fn_piwise)
#   y_hat <- eval(parse(text = rhs), envir = env)
#   sse <- sum((y - y_hat)^2)
#   return(sse)
# }
#
# minimizer_new3 <- function(params,
#                            data,
#                            formula,
#                            names,
#                            fixed_params = NA) {
#   names(params) <- names
#   y <- data[[all.vars(formula[[2]])]]
#   rhs <- paste(formula[3])
#   env <- new.env()
#   list2env(data, envir = env)
#   list2env(as.list(na.omit(c(params, fixed_params))), envir = env)
#   fn_piwise <- Vectorize(fn_piwise)
#   y_hat <- eval(parse(text = rhs), envir = env)
#   sse <- sum((y - y_hat)^2)
#   return(sse)
# }
#
#
# # library(microbenchmark)
# # microbenchmark(
# #   a = opm(
# #     par = params,
# #     fn = minimizer_new2,
# #     data = data,
# #     formula = formula,
# #     names = names,
# #     fixed_params = fixed_params,
# #     method = c("subplex"),
# #     lower = -Inf,
# #     upper = Inf
# #   ),
# #   b = opm(
# #     par = params,
# #     fn = minimizer_new,
# #     data = data,
# #     formula = formula,
# #     names = names,
# #     fixed_params = fixed_params,
# #     method = c("subplex"),
# #     lower = -Inf,
# #     upper = Inf
# #   ),
# #   c = opm(
# #     par = params,
# #     fn = minimizer2,
# #     t = t,
# #     y = y,
# #     curve = fn,
# #     fixed_params = fixed,
# #     metric = "sse",
# #     method = c("subplex"),
# #     lower = -Inf,
# #     upper = Inf
# #   ),
# #   times = 10, unit = "secs"
# # )
