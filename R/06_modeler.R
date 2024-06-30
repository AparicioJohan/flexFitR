#' Modeler HTP
#'
#' @param x An object of class \code{read_HTP}, containing the results of the \code{read_HTP()} function.
#' @param index A string specifying the trait to be modeled. Default is \code{"GLI"}.
#' @param plot_id An optional vector of plot IDs to filter the data. Default is \code{NULL}, meaning all plots are used.
#' @param add_zero \code{TRUE} or \code{FALSE}. Add zero to the time series.\code{TRUE} by default.
#' @param check_negative Logical. Convert negative values to zero. \code{TRUE} by default.
#' @param max_as_last Logical. If \code{TRUE}, adds the maximum value after reaching the local maximum. Default is \code{FALSE}.
#' @param method A vector of the methods to be used, each as a character string.
#' See optimx package. c("subplex", "pracmanm", "anms") by default.
#' @param return_method \code{TRUE} or \code{FALSE}. To return the method selected for the
#' optimization in the table. \code{FALSE} by default.
#' @param parameters A named vector specifying the initial values for the parameters to be optimized. c(t1 = 38.7, t2 = 62, t3 = 90, k = 0.32, beta = -0.01) by default which is the same for all the plots.
#' @param lower Bounds on the variables for methods such as "L-BFGS-B" that can handle box (or bounds) constraints.
#' @param upper Bounds on the variables for methods such as "L-BFGS-B" that can handle box (or bounds) constraints.
#' @param initial_vals A data.frame with columns <plot, genotype, t1, t2, ... , and all the initial parameters>. Specific initial values per plot.
#' @param fixed_params A data.frame with columns <plot, genotype, t1, t2, ... , and all the fixed parameters>.
#' @param fn String character with the name of the function "fn_lin_pl_lin".
#' @param n_points Number of time points to approximate the Area Under the Curve (AUC). 1000 by default.
#' @param max_time Maximum time value for calculating the AUC. \code{NULL} by default takes the last time point.
#' @return An object of class \code{modeler_HTP}, which is a list containing the following elements:
#' \describe{
#'   \item{\code{param}}{A data frame containing the optimized parameters and related information.}
#'   \item{\code{dt}}{A data frame with data used.}
#'   \item{\code{fn}}{The call used to calculate the AUC.}
#'   \item{\code{max_time}}{Maximum time value used for calculating the AUC.}
#' }
#' @export
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
#' names(results)
#' mat <- modeler_HTP(
#'   x = results,
#'   index = "GLI_2",
#'   plot_id = c(195),
#'   parameters = c(t1 = 38.7, t2 = 62, t3 = 90, k = 0.32, beta = -0.01),
#'   fn = "fn_lin_pl_lin",
#' )
#' plot(mat, plot_id = c(195))
#' mat$param
#'
#' can <- modeler_HTP(
#'   x = results,
#'   index = "Canopy",
#'   plot_id = c(195),
#'   parameters = c(t1 = 45, t2 = 80, k = 0.9),
#'   fn = "fn_piwise"
#' )
#' plot(can, plot_id = c(195))
#' can$param
#'
#' fixed_params <- results$dt_long |>
#'   filter(trait %in% "Canopy") |>
#'   group_by(plot, genotype) |>
#'   summarise(k = max(value, na.rm = TRUE), .groups = "drop")
#' can <- modeler_HTP(
#'   x = results,
#'   index = "Canopy",
#'   plot_id = c(195),
#'   parameters = c(t1 = 45, t2 = 80, k = 0.9),
#'   fn = "fn_piwise",
#'   fixed_params = fixed_params
#' )
#' plot(can, plot_id = c(195))
#' can$param
#' @import optimx
#' @import tibble
#' @import dplyr
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
                        max_time = NULL) {
  if (!inherits(x, "read_HTP")) {
    stop("The object should be of read_HTP class")
  }
  traits <- unique(x$dt_long$trait)
  if (!index %in% traits) {
    stop("Index not found in x. Please verify the spelling.")
  }
  args <- try(expr = names(formals(fn))[-1], silent = TRUE)
  if (inherits(args, "try-error")) {
    stop("Please verify the function you provide: '", fn, "'. It was not found.")
  }
  if (!is.null(initial_vals)) {
    nam_ini_vals <- colnames(initial_vals)
    if (!all(nam_ini_vals[1:2] %in% c("plot", "genotype"))) {
      stop("initial_vals should contain c('plot', 'genotype')")
    }
    if (!sum(nam_ini_vals[-c(1:2)] %in% args) == length(args)) {
      stop("initial_vals should have the same parameters as the function: ", fn)
    }
  }
  if (!is.null(fixed_params)) {
    nam_fix_params <- colnames(fixed_params)
    if (!all(nam_fix_params[1:2] %in% c("plot", "genotype"))) {
      stop("fixed_params should contain c('plot', 'genotype')")
    }
    if (!any(nam_fix_params[-c(1:2)] %in% args)) {
      stop("fixed_params should have at least one parameter of: ", fn)
    }
    if (sum(nam_fix_params[-c(1:2)] %in% args) == length(args)) {
      stop("fixed_params can not have all parameters of the function: ", fn)
    }
  }
  if (is.null(parameters) & is.null(fixed_params)) {
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
    dt <- max_as_last(dt, index = index)
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

  param_mat <- dt_nest |>
    summarise(
      res = list(
        opm(
          par = initials,
          fn = sse_generic,
          t = data$time,
          y = data$value,
          curve = fn,
          fixed_params = fx_params,
          method = method,
          lower = lower,
          upper = upper
        ) |>
          rownames_to_column(var = "method") |>
          arrange(value) |>
          rename(sse = value) |>
          select(-c(fevals:xtime)) |>
          slice(1) |>
          cbind(t(fx_params))
      ),
      .groups = "drop"
    ) |>
    unnest(cols = res)

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
    summarise(total_area = sum(trapezoid_area))
  param_mat <- full_join(param_mat, auc, by = "plot")

  if (!return_method) {
    param_mat <- select(param_mat, -method)
  }
  out <- list(param = param_mat, dt = dt, fn = density, max_time = max_time)
  class(out) <- "modeler_HTP"
  return(invisible(out))
}
