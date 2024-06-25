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
#' @param fn A function to be minimized (or maximized), with first argument the
#' vector of parameters over which minimization is to take place.
#' It should return a scalar result. Default is \link{sse_lin_pl_lin}.

#' @return data.frame
#' @export
#'
#' @examples
#' # in progress
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
  if (!is.null(plot_id)) {
    dt <- dt |>
      filter(plot %in% plot_id) |>
      droplevels()
  }

  param_mat <- dt |>
    nest_by(plot, genotype, row, range) |>
    summarise(
      res = list(
        opm(
          par = parameters,
          fn = fn,
          t = data$time,
          y = data$value,
          method = method
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
