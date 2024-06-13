#' @noRd
fun_piece_wise <- function(t, t1 = 45, t2 = 80, k = 0.9) {
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

#' @noRd
SSE <- function(params, t, y) {
  t1 <- params[1]
  t2 <- params[2]
  k <- max(y)
  y_hat <- sapply(t, FUN = fun_piece_wise, t1 = t1, t2 = t2, k = k)
  sse <- sum((y - y_hat)^2)
  return(sse)
}

#' @noRd
correct_maximun <- function(results,
                            trait_to_corr = "Canopy",
                            add_zero = TRUE) {
  dt_can <- results$dt_long |>
    filter(trait %in% trait_to_corr) |>
    group_by(plot, genotype, row, range) |>
    mutate(
      local_max_at = paste(local_min_max(value, time)$days_max, collapse = "_"),
      local_max = as.numeric(local_min_max(value, time)$days_max[1])
    ) |>
    mutate(
      corrected = ifelse(time <= local_max, value, value[time == local_max])
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
#' @param return_method TRUE or FALSE. To return the method selected for the
#' optimization in the table. FALSE by default.
#' @param method A vector of the methods to be used, each as a character string.
#' See optimx package. c("subplex", "pracmanm", "anms") by default.
#'
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
#' out$param
#' @import optimx
#' @import tibble
canopy_HTP <- function(results,
                       canopy = "Canopy",
                       plot_id = NULL,
                       correct_max = TRUE,
                       add_zero = TRUE,
                       return_method = FALSE,
                       method = c("subplex", "pracmanm", "anms")) {
  if (correct_max) {
    dt <- correct_maximun(
      results = results,
      trait_to_corr = canopy,
      add_zero = add_zero
    )
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
          par = c("t1" = 45, "t2" = 80),
          fn = SSE,
          t = data$time,
          y = data$corrected,
          method = method
        ) |>
          mutate(max = max(data$corrected)) |>
          rownames_to_column(var = "method") |>
          arrange(value) |>
          rename(SSE = value) |>
          select(t1:t2, max, method, SSE) |>
          slice(1)
      ),
      .groups = "drop"
    ) |>
    unnest(cols = res) |>
    mutate(deltaT = t2 - t1, slope = max / deltaT, intercept = -slope * t1)
  if (!return_method) {
    param <- select(param, -method)
  }
  out <- list(param = param, dt = dt)
  class(out) <- "canopy_HTP"
  return(out)
}
