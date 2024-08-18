# Mean Absolute Error (MAE)
#' @noRd
mae <- function(actual, predicted) {
  mean(abs(actual - predicted))
}

# Mean Squared Error (MSE)
#' @noRd
mse <- function(actual, predicted) {
  mean((actual - predicted)^2)
}

# Sum Squared Error (SSE)
#' @noRd
sse <- function(actual, predicted) {
  sum((actual - predicted)^2)
}

# Root Mean Squared Error (RMSE)
#' @noRd
rmse <- function(actual, predicted) {
  sqrt(mean((actual - predicted)^2))
}

# Coefficient of Determination (R^2)
#' @noRd
r_squared <- function(actual, predicted) {
  rss <- sum((predicted - actual)^2) # Residual sum of squares
  tss <- sum((actual - mean(actual))^2) # Total sum of squares
  1 - (rss / tss)
}


#' Metrics for modeler_HTP
#'
#' Computes various performance metrics for a modeler_HTP object.
#' The function calculates Sum of Squared Errors (SSE), Mean Absolute Error (MAE),
#' Mean Squared Error (MSE), Root Mean Squared Error (RMSE), and the Coefficient
#' of Determination (R-squared).
#'
#' @param x An object of class `modeler_HTP` containing the necessary data to compute the metrics.
#' @param .by_id Return the metrics by id? TRUE by default.
#'
#' @return A data frame containing the calculated metrics grouped by plot, row, range, genotype, and trait.
#'
#' @details
#' \if{html}{
#' Sum of Squared Errors (SSE):
#' \deqn{SSE = \sum_{i=1}^{n} (y_i - \hat{y}_i)^2}
#'
#' Mean Absolute Error (MAE):
#' \deqn{MAE = \frac{1}{n} \sum_{i=1}^{n} |y_i - \hat{y}_i|}
#'
#' Mean Squared Error (MSE):
#' \deqn{MSE = \frac{1}{n} \sum_{i=1}^{n} (y_i - \hat{y}_i)^2}
#'
#' Root Mean Squared Error (RMSE):
#' \deqn{RMSE = \sqrt{\frac{1}{n} \sum_{i=1}^{n} (y_i - \hat{y}_i)^2}}
#'
#' Coefficient of Determination (R-squared):
#' \deqn{R^2 = 1 - \frac{\sum_{i=1}^{n} (y_i - \hat{y}_i)^2}{\sum_{i=1}^{n} (y_i - \bar{y})^2}}
#' }
#'
#' @export
#'
#' @examples
#' library(exploreHTP)
#' data(dt_potato)
#' dt_potato <- dt_potato
#' results <- dt_potato |>
#'   read_HTP(
#'     x = DAP,
#'     y = c(Canopy, PH),
#'     id = Plot,
#'     .keep = c(Gen, Row, Range)
#'   )
#' x <- canopy_HTP(x = results, index = "Canopy", id = c(1:2))
#' plot(x, c(1:2))
#' print(x)
#' metrics_HTP(x)
metrics_HTP <- function(x, .by_id = TRUE) {
  if (!inherits(x, "modeler_HTP")) {
    stop("The object should be of modeler_HTP class")
  }
  val_metrics <- x$dt |>
    group_by(uid, var) |>
    summarise(
      SSE = sse(y, .fitted),
      MAE = mae(y, .fitted),
      MSE = mse(y, .fitted),
      RMSE = sqrt(MSE),
      r_squared = r_squared(y, .fitted),
      n = n(),
      .groups = "drop"
    )
  n_plots <- nrow(val_metrics)
  if (!.by_id & n_plots > 1) {
    summ_metrics <- val_metrics |>
      select(var:r_squared) |>
      pivot_longer(cols = SSE:r_squared, names_to = "metric") |>
      group_by(var, metric) |>
      summarise(
        Min = suppressWarnings(min(value, na.rm = TRUE)),
        Mean = mean(value, na.rm = TRUE),
        Median = median(value, na.rm = TRUE),
        Max = suppressWarnings(max(value, na.rm = TRUE)),
        SD = sd(value, na.rm = TRUE),
        CV = SD / Mean,
        .groups = "drop"
      )
    return(summ_metrics)
  } else {
    return(val_metrics)
  }
}
