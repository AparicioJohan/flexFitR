#' Maturity Modelling
#'
#' @param results Object of class exploreHTP
#' @param canopy Object of class canopy_HTP
#' @param index A string specifying the trait to be modeled. Default is \code{"GLI"}.
#' @param check_negative TRUE of FALSE. Convert negative values to zero.
#' @param plot_id Optional Plot ID. NULL by default
#' @param add_zero TRUE or FALSE. Add zero to the time series.TRUE by default.
#' @param method A vector of the methods to be used, each as a character string.
#' See optimx package. c("subplex", "pracmanm", "anms") by default.
#' @param return_method TRUE or FALSE. To return the method selected for the
#' optimization in the table. FALSE by default.
#' @param parameters (Optional)	Initial values for the parameters to be
#' optimized over. c(t1 = 38.7, t2 = 62, t3 = 90, k = 0.32, beta = -0.01) by default.
#' @param lower Bounds on the variables for methods such as "L-BFGS-B" that can handle box (or bounds) constraints.
#' @param upper Bounds on the variables for methods such as "L-BFGS-B" that can handle box (or bounds) constraints.
#' @param initial_vals TRUE or FALSE. Whether the user wants to use t1 and t2 from the
#' Canopy model as initial values or not. Only works if the function \code{fn} uses t1 and t2 as parameters.
#' FALSE by default.
#' @param fn A function to be minimized (or maximized), with first argument the
#' vector of parameters over which minimization is to take place.
#' It should return a scalar result. Default is \link{sse_lin_pl_lin}.
#' @return A list with two elements:
#' \describe{
#'   \item{\code{param}}{A data frame containing the optimized parameters and related information.}
#'   \item{\code{dt}}{A data frame with data used.}
#' }
#' @export
#'
#' @examples
#' library(exploreHTP)
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
#' out <- canopy_HTP(
#'   results = results,
#'   canopy = "Canopy",
#'   plot_id = c(195, 40),
#'   correct_max = TRUE,
#'   add_zero = TRUE
#' )
#' mat <- maturity_HTP(
#'   results = results,
#'   canopy = out,
#'   index = "GLI_2",
#'   parameters = c(t1 = 38.7, t2 = 62, t3 = 90, k = 0.32, beta = -0.01),
#'   fn = sse_lin_pl_lin
#' )
#' plot(mat, plot_id = c(195, 40))
#' @import optimx
#' @import tibble
maturity_HTP <- function(results,
                         canopy,
                         index = "GLI",
                         check_negative = TRUE,
                         add_zero = TRUE,
                         plot_id = NULL,
                         method = c("subplex", "pracmanm", "anms"),
                         return_method = FALSE,
                         parameters = c(t1 = 38.7, t2 = 62, t3 = 90, k = 0.32, beta = -0.01),
                         lower = -Inf,
                         upper = Inf,
                         initial_vals = FALSE,
                         fn = sse_lin_pl_lin) {
  param <- canopy$param |>
    select(plot:range, t1, t2) |>
    rename(DE = t1, DMC = t2)

  dt <- results$dt_long |>
    filter(trait %in% index) |>
    filter(!is.na(value)) |>
    filter(plot %in% param$plot) |>
    full_join(param, by = c("plot", "row", "range", "genotype"))

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

  if (initial_vals) {
    init <- canopy$param |>
      select(plot, genotype, t1, t2) |>
      cbind(data.frame(t(parameters[-c(1:2)]))) |>
      pivot_longer(
        cols = -c(plot, genotype),
        names_to = "coef",
        values_to = "val"
      ) |>
      nest_by(plot, genotype, .key = "param") |>
      mutate(param = list(pull(param, val, coef)))
  } else {
    init <- canopy$param |>
      select(plot, genotype) |>
      cbind(data.frame(t(parameters))) |>
      pivot_longer(
        cols = -c(plot, genotype),
        names_to = "coef",
        values_to = "val"
      ) |>
      nest_by(plot, genotype, .key = "param") |>
      mutate(param = list(pull(param, val, coef)))
  }

  if (!is.null(plot_id)) {
    dt <- droplevels(filter(dt, plot %in% plot_id))
    init <- droplevels(filter(init, plot %in% plot_id))
  }

  dt_nest <- dt |>
    nest_by(plot, genotype, row, range) |>
    full_join(init, by = c("plot", "genotype"))

  param_mat <- dt_nest |>
    summarise(
      res = list(
        opm(
          par = param,
          fn = fn,
          t = data$time,
          y = data$value,
          method = method,
          lower = lower,
          upper = upper
        ) |>
          rownames_to_column(var = "method") |>
          arrange(value) |>
          rename(sse = value) |>
          select(2:(length(parameters) + 1), method, sse) |>
          slice(1)
      ),
      .groups = "drop"
    ) |>
    unnest(cols = res)
  if (!return_method) {
    param_mat <- select(param_mat, -method)
  }
  out <- list(param = param_mat, dt = dt)
  class(out) <- "maturity_HTP"
  return(out)
}
