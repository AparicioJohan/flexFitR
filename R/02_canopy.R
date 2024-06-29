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
#' @param results An object of class \code{read_HTP}, containing the results of the \code{read_HTP()} function.
#' @param canopy A string specifying the canopy trait to be modeled. Default is \code{"Canopy"}.
#' @param plot_id An optional vector of plot IDs to filter the data. Default is \code{NULL}, meaning all plots are used.
#' @param correct_max Logical. If \code{TRUE}, adds the maximum value after reaching the local maximum. Default is \code{TRUE}.
#' @param add_zero Logical. If \code{TRUE}, adds a zero value to the time series. Default is \code{TRUE}.
#' @param method A character vector of optimization methods to be used, as specified in the \code{optimx} package. Default is \code{c("subplex", "pracmanm", "anms")}.
#' @param return_method Logical. If \code{TRUE}, includes the selected optimization method in the output table. Default is \code{FALSE}.
#' @param parameters A named vector specifying the initial values for the parameters to be optimized. Default is \code{c(t1 = 45, t2 = 80)}.
#' @param fn_sse A function to be minimized (or maximized), with the first argument being the vector of parameters over which minimization is to take place. It should return a scalar result. Default is \link{sse_piwise}.
#' @param fn Object of class call. e.g. \code{quote(fn_piwise(time, t1, t2, k))} to calculate the area under the curve (AUC). Always use time as first argument.
#' @param n_points Number of time points to approximate the AUC. 1000 by default.
#' @param max_time Maximum time value for calculating the AUC. \code{NULL} by default takes the last time point.
#' @return An object of class \code{canopy_HTP}, which is a list containing the following elements:
#' \describe{
#'   \item{\code{param}}{A data frame containing the optimized parameters and related information.}
#'   \item{\code{dt}}{A data frame with the corrected and possibly zero-augmented canopy data.}
#'   \item{\code{fn}}{The call used to calculate the AUC.}
#'   \item{\code{max_time}}{Maximum time value used for calculating the AUC.}
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
#' out$param$slope <- out$param$k / out$param$deltaT
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
                       fn_sse = sse_piwise,
                       fn = quote(fn_piwise(time, t1, t2, k)),
                       n_points = 1000,
                       max_time = NULL) {
  if (!inherits(results, "read_HTP")) {
    stop("The object should be of read_HTP class")
  }
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
          fn = fn_sse,
          t = data$time,
          y = data$corrected,
          method = method
        ) |>
          mutate(k = max(data$corrected)) |>
          rownames_to_column(var = "method") |>
          arrange(value) |>
          rename(sse = value) |>
          select(2:(length(parameters) + 1), k, method, sse) |>
          slice(1)
      ),
      .groups = "drop"
    ) |>
    unnest(cols = res)

  if (is.null(max_time)) {
    max_time <- max(dt$time, na.rm = TRUE)
  }

  # AUC
  sq <- seq(0, max_time, length.out = n_points)
  auc <- full_join(
    x = expand.grid(time = sq, plot = unique(dt$plot)),
    y = param,
    by = "plot"
  ) |>
    group_by(time, plot) |>
    mutate(hat = !!fn) |>
    group_by(plot) |>
    mutate(trapezoid_area = (lead(hat) + hat) / 2 * (lead(time) - time)) |>
    filter(!is.na(trapezoid_area)) |>
    summarise(total_area = sum(trapezoid_area))
  param <- full_join(param, auc, by = "plot")

  if (!return_method) {
    param <- select(param, -method)
  }
  out <- list(param = param, dt = dt, fn = fn, max_time = max_time)
  class(out) <- "canopy_HTP"
  return(invisible(out))
}
