#' Plant Height Modelling
#'
#' @param results Object of class exploreHTP
#' @param canopy Object of class canopy_HTP
#' @param plant_height A string specifying the Plant Height trait to be modeled. Default is \code{"PH"}.
#' @param plot_id Optional Plot ID. NULL by default
#' @param add_zero TRUE or FALSE. Add zero to the time series.TRUE by default.
#' @param method A vector of the methods to be used, each as a character string.
#' See optimx package. c("subplex", "pracmanm", "anms") by default.
#' @param return_method TRUE or FALSE. To return the method selected for the
#' optimization in the table. FALSE by default.
#' @param parameters (Optional)	Initial values for the parameters to be
#' optimized over. c(45, 80) by default.
#' @param fn A function to be minimized (or maximized), with first argument the
#' vector of parameters over which minimization is to take place.
#' It should return a scalar result. Default is \link{sse_exp2_exp}.

#' @return data.frame
#' @export
#'
#' @examples
#' library(exploreHTP)
#' data(dt_chips)
#' results <- read_HTP(
#'   data = dt_chips,
#'   genotype = "Gen",
#'   time = "DAP",
#'   plot = "Plot",
#'   traits = c("Canopy", "PH"),
#'   row = "Row",
#'   range = "Range"
#' )
#' names(results)
#' out <- canopy_HTP(
#'   results = results,
#'   canopy = "Canopy",
#'   plot_id = c(60, 150),
#'   correct_max = TRUE,
#'   add_zero = TRUE
#' )
#' names(out)
#' plot(out, plot_id = c(60, 150))
#' ph_1 <- height_HTP(
#'   results = results,
#'   canopy = out,
#'   plant_height = "PH",
#'   add_zero = TRUE,
#'   method = c("nlminb", "anms", "mla", "pracmanm", "subplex"),
#'   return_method = TRUE,
#'   parameters = c(t2 = 67, alpha = 1 / 600, beta = -1 / 80),
#'   fn = sse_exp2_exp
#' )
#' plot(
#'   x = ph_1,
#'   plot_id = c(60, 150),
#'   fn = quote(fn_exp2_exp(time, t1, t2, alpha, beta))
#' )
#' ph_1$param
#'
#' ph_2 <- height_HTP(
#'   results = results,
#'   canopy = out,
#'   plant_height = "PH",
#'   add_zero = TRUE,
#'   method = c("nlminb", "anms", "mla", "pracmanm", "subplex"),
#'   return_method = TRUE,
#'   parameters = c(t2 = 67, alpha = 1 / 600, beta = -1 / 80),
#'   fn = sse_exp2_lin
#' )
#' plot(
#'   x = ph_2,
#'   plot_id = c(60, 150),
#'   fn = quote(fn_exp2_lin(time, t1, t2, alpha, beta))
#' )
#' ph_2$param
#' @import optimx
#' @import tibble
height_HTP <- function(results,
                       canopy,
                       plant_height = "PH",
                       plot_id = NULL,
                       add_zero = TRUE,
                       method = c("subplex", "pracmanm", "anms"),
                       return_method = FALSE,
                       parameters = c(t2 = 67, alpha = 1 / 600, beta = -1 / 80),
                       fn = sse_exp2_exp) {
  param <- canopy$param |>
    select(plot:range, t1, t2) |>
    rename(DMC = t2)

  dt <- results$dt_long |>
    filter(trait %in% plant_height) |>
    filter(!is.na(value)) |>
    filter(plot %in% param$plot) |>
    full_join(param, by = c("plot", "row", "range", "genotype"))

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

  param_ph <- dt |>
    nest_by(plot, genotype, row, range) |>
    summarise(
      res = list(
        opm(
          par = parameters,
          fn = fn,
          t = data$time,
          y = data$value,
          t1 = unique(data$t1),
          method = method
        ) |>
          mutate(t1 = unique(data$t1)) |>
          rownames_to_column(var = "method") |>
          arrange(value) |>
          rename(sse = value) |>
          select(2:(length(parameters) + 1), t1, method, sse) |>
          slice(1)
      ),
      .groups = "drop"
    ) |>
    unnest(cols = res)
  if (!return_method) {
    param_ph <- select(param_ph, -method)
  }
  out <- list(param = param_ph, dt = dt)
  class(out) <- "height_HTP"
  return(out)
}
