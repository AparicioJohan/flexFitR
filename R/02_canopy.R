#' Canopy Modelling
#'
#' @description
#' This function performs canopy modelling based on time series data from high-throughput phenotyping (HTP). It optimizes parameters to fit a specified function to the canopy data over time, potentially correcting maximum values and adding a zero point to the series.
#'
#' @param x An object of class \code{read_HTP}, containing the results of the \code{read_HTP()} function.
#' @param index A string specifying the canopy trait to be modeled. Default is \code{"Canopy"}.
#' @param id An optional vector of plot IDs to filter the data. Default is \code{NULL}, meaning all plots are used.
#' @param ... Additional arguments passed to the \code{modeler_HTP()} function.
#' @return An object of class \code{modeler_HTP}, which is a list containing the following elements:
#' \describe{
#'   \item{\code{param}}{A data frame containing the optimized parameters and related information.}
#'   \item{\code{dt}}{A data frame with data used and fitted values.}
#'   \item{\code{fn}}{The call used to calculate the AUC.}
#'   \item{\code{metrics}}{Metrics and summary of the models.}
#'   \item{\code{max_time}}{Maximum time value used for calculating the AUC.}
#'   \item{\code{execution}}{Execution time.}
#'   \item{\code{response}}{Response variable.}
#'   \item{\code{.keep}}{Metadata to keep across.}
#'   \item{\code{fun}}{Function being optimized}
#'   \item{\code{fit}}{List with the fitted models.}
#' }
#' @export
#'
#' @examples
#' library(exploreHTP)
#' data(dt_potato)
#' results <- dt_potato |>
#'   read_HTP(
#'     x = DAP,
#'     y = c(Canopy, PH),
#'     id = Plot,
#'     .keep = c(Gen, Row, Range)
#'   )
#' mod <- canopy_HTP(x = results, index = "Canopy", id = c(22, 40))
#' plot(mod, c(22, 40))
#' print(mod)
#' @import optimx
#' @import tibble
canopy_HTP <- function(x, index = "Canopy", id = NULL, ...) {
  if (!inherits(x, "read_HTP")) {
    stop("The object should be of read_HTP class")
  }
  traits <- unique(x$dt_long$var)
  if (!index %in% traits) {
    stop("Index not found in x. Please verify the spelling.")
  }
  plots <- unique(x$dt_long$uid)
  if (!is.null(id)) {
    if (!all(id %in% plots)) {
      stop("plot_id not found in data.")
    } else {
      plots <- id
    }
  }
  fixed_params <- x$dt_long |>
    filter(var %in% index & uid %in% plots) |>
    group_by(uid) |>
    summarise(k = max(y, na.rm = TRUE), .groups = "drop")
  time <- unique(x$dt_long$x)
  t1 <- as.numeric(quantile(time, 0.3))
  t2 <- as.numeric(quantile(time, 0.6))
  k <- mean(fixed_params$k, na.rm = TRUE)
  out <- modeler_HTP(
    x = x,
    index = index,
    id = plots,
    parameters = c(t1 = t1, t2 = t2, k = k),
    fn = "fn_piwise",
    fixed_params = fixed_params,
    max_as_last = TRUE,
    ...
  )
  out$param$dt <- out$param$t2 - out$param$t1
  out$param$slope <- out$param$k / out$param$dt
  return(out)
}

#' @noRd
max_as_last <- function(data, .keep) {
  dt_can <- data |>
    group_by(uid, across(all_of(.keep))) |>
    mutate(
      loc_max_at = paste(local_min_max(y, x)$days_max, collapse = "_"),
      loc_max = as.numeric(local_min_max(y, x)$days_max[1])
    ) |>
    mutate(loc_max = ifelse(is.na(loc_max), max(x, na.rm = TRUE), loc_max)) |>
    mutate(
      y = ifelse(x <= loc_max, y, y[x == loc_max])
    ) |>
    select(-loc_max_at, -loc_max) |>
    ungroup()
  return(dt_can)
}

#' @noRd
local_min_max <- function(x, days) {
  up <- c(x[-1], NA)
  down <- c(NA, x[-length(x)])
  a <- cbind(x, up, down)
  minima <- which(apply(a, 1, min) == a[, 1])
  maxima <- which(apply(a, 1, max) == a[, 1])
  list(
    minima = minima,
    days_min = days[minima],
    maxima = maxima,
    days_max = days[maxima]
  )
}
