#' @noRd
correct_maximun <- function(results,
                            var = "Canopy",
                            add_zero = TRUE) {
  dt_can <- results$dt_long |>
    filter(trait %in% var) |>
    group_by(plot, genotype, row, range) |>
    mutate(
      loc_max_at = paste(local_min_max(value, time)$days_max, collapse = "_"),
      loc_max = as.numeric(local_min_max(value, time)$days_max[1])
    ) |>
    mutate(
      corrected = ifelse(time <= loc_max, value, value[time == loc_max])
    ) |>
    ungroup()
  if (add_zero) {
    dt_can <- dt_can |>
      mutate(time = 0, value = 0, corrected = 0) |>
      unique.data.frame() |>
      rbind.data.frame(dt_can) |>
      arrange(plot, time)
  }
  return(dt_can)
}

#' Canopy Modelling
#'
#' @description
#' This function performs canopy modelling based on time series data from high-throughput phenotyping (HTP). It optimizes parameters to fit a specified function to the canopy data over time, potentially correcting maximum values and adding a zero point to the series.
#'
#' @param results An object of class \code{exploreHTP}, containing the results of the \code{read_HTP()} function.
#' @param canopy A string specifying the canopy trait to be modeled. Default is \code{"Canopy"}.
#' @param plot_id An optional vector of plot IDs to filter the data. Default is \code{NULL}, meaning all plots are used.
#' @param correct_max Logical. If \code{TRUE}, adds the maximum value after reaching the local maximum. Default is \code{TRUE}.
#' @param add_zero Logical. If \code{TRUE}, adds a zero value to the time series. Default is \code{TRUE}.
#' @param method A character vector of optimization methods to be used, as specified in the \code{optimx} package. Default is \code{c("subplex", "pracmanm", "anms")}.
#' @param return_method Logical. If \code{TRUE}, includes the selected optimization method in the output table. Default is \code{FALSE}.
#' @param parameters A named vector specifying the initial values for the parameters to be optimized. Default is \code{c(t1 = 45, t2 = 80)}.
#' @param fn A function to be minimized (or maximized), with the first argument being the vector of parameters over which minimization is to take place. It should return a scalar result. Default is \link{sse_piwise}.
#'
#' @return A list with two elements:
#' \describe{
#'   \item{\code{param}}{A data frame containing the optimized parameters and related information.}
#'   \item{\code{dt}}{A data frame with the corrected and possibly zero-augmented canopy data.}
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
#'   traits = c("Canopy", "PH"),
#'   row = "Row",
#'   range = "Range"
#' )
#' names(results)
#' out <- canopy_HTP(
#'   results = results,
#'   canopy = "Canopy",
#'   plot_id = c(22, 40),
#'   correct_max = TRUE,
#'   add_zero = TRUE
#' )
#' names(out)
#' plot(out, c(22, 40))
#' out$param$deltaT <- out$param$t2 - out$param$t1
#' out$param$slope <- out$param$max / out$param$deltaT
#' out$param
#' @import optimx
#' @import tibble
canopy_HTP <- function(results,
                       canopy = "Canopy",
                       plot_id = NULL,
                       correct_max = TRUE,
                       add_zero = TRUE,
                       method = c("subplex", "pracmanm", "anms"),
                       return_method = FALSE,
                       parameters = c(t1 = 45, t2 = 80),
                       fn = sse_piwise) {
  if (correct_max) {
    dt <- correct_maximun(results, var = canopy, add_zero = add_zero)
  } else {
    dt <- results$dt_long |>
      filter(trait %in% canopy) |>
      droplevels() |>
      mutate(corrected = value)
    if (add_zero) {
      dt <- dt |>
        mutate(time = 0, value = 0, corrected = 0) |>
        unique.data.frame() |>
        rbind.data.frame(dt) |>
        arrange(plot, time)
    }
  }
  if (!is.null(plot_id)) {
    dt <- dt |>
      filter(plot %in% plot_id) |>
      droplevels()
  }
  param <- dt |>
    nest_by(plot, genotype, row, range) |>
    summarise(
      res = list(
        opm(
          par = parameters,
          fn = fn,
          t = data$time,
          y = data$corrected,
          method = method
        ) |>
          mutate(max = max(data$corrected)) |>
          rownames_to_column(var = "method") |>
          arrange(value) |>
          rename(sse = value) |>
          select(2:(length(parameters) + 1), max, method, sse) |>
          slice(1)
      ),
      .groups = "drop"
    ) |>
    unnest(cols = res)
  if (!return_method) {
    param <- select(param, -method)
  }
  out <- list(param = param, dt = dt)
  class(out) <- "canopy_HTP"
  return(out)
}
