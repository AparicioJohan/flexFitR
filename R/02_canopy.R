#' Piece-wise Regression
#'
#' @param t Numeric value.
#' @param t1 First break point.
#' @param t2 t value to reach the maximum value.
#' @param k Maximum y value.
#' @return Numeric value.
#' @export
#'
#' @examples
#' library(exploreHTP)
#' x <- seq(0, 108, 0.1)
#' y_hat <- sapply(x, FUN = fn_canopy, t1 = 34.9, t2 = 61.8, k = 100)
#' plot(x, y_hat, type = "l")
#' lines(x, y_hat, col = "red")
#' abline(v = c(34.9, 61.8), lty = 2)
fn_canopy <- function(t, t1 = 45, t2 = 80, k = 0.9) {
  if (is.na(t)) {
    stop("Missing values not allowed for t.")
  }
  if (t < t1) {
    y <- 0
  } else if (t >= t1 && t <= t2) {
    y <- k / (t2 - t1) * (t - t1)
  } else {
    y <- k
  }
  return(y)
}

#' Sum of Squares Error Function
#'
#' Function to be minimized in the optimx package.
#'
#' @param params Numeric vector with two parameters.
#' @param t Independent variable.
#' @param y Response variable.
#'
#' @return sum of squares error
#' @export
#'
#' @examples
#' library(exploreHTP)
#' x <- c(0, 29, 36, 42, 56, 76, 92, 100, 108)
#' y <- c(0, 0, 4.379, 26.138, 78.593, 100, 100, 100, 100)
#' fn_sse(params = c(34.9, 61.8), t = x, y = y)
#'
#' y_hat <- sapply(x, FUN = fn_canopy, t1 = 34.9, t2 = 61.8, k = 100)
#' sum((y - y_hat)^2)
fn_sse <- function(params, t, y) {
  t1 <- params[1]
  t2 <- params[2]
  k <- max(y)
  y_hat <- sapply(t, FUN = fn_canopy, t1 = t1, t2 = t2, k = k)
  sse <- sum((y - y_hat)^2)
  return(sse)
}

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
#' @param results Object of class exploreHTP
#' @param canopy  string
#' @param plot_id Optional Plot ID. NULL by default
#' @param correct_max Add maximum value after reaching the local maximum. TRUE
#' by default.
#' @param add_zero TRUE or FALSE. Add zero to the time series.TRUE by default.
#' @param method A vector of the methods to be used, each as a character string.
#' See optimx package. c("subplex", "pracmanm", "anms") by default.
#' @param return_method TRUE or FALSE. To return the method selected for the
#' optimization in the table. FALSE by default.
#' @param parameters (Optional)	Initial values for the parameters to be
#' optimized over. c(45, 80) by default.
#' @param fn A function to be minimized (or maximized), with first argument the
#' vector of parameters over which minimization is to take place.
#' It should return a scalar result.

#' @return data.frame
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
                       fn = fn_sse) {
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
