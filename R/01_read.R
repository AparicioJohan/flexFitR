#' Read HTP Data
#'
#' Reads and processes high-throughput phenotyping (HTP) data from a data frame in wide format.
#'
#' This function processes and prepares HTP data to be analyzed.
#'
#' @param data A data.frame in a wide format containing HTP data.
#' @param genotype A character string indicating the column in `data` that contains genotype information.
#' @param time A character string indicating the column in `data` that contains time points.
#' @param plot A character string indicating the column in `data` that contains plot IDs.
#' @param traits A character vector specifying the columns in `data` that contain the traits to be analyzed.
#' @param row A character string indicating the column in `data` that contains row coordinates.
#' @param range A character string indicating the column in `data` that contains range coordinates.
#'
#' @return An object of class \code{read_HTP}, which is a list containing the following elements:
#' \describe{
#'   \item{\code{summ_traits}}{A data.frame containing summary statistics for each trait at each time point, including minimum, mean, median, maximum, standard deviation, coefficient of variation, number of non-missing values, percentage of missing values, and percentage of negative values.}
#'   \item{\code{exp_design_resum}}{A data.frame summarizing the experimental design, including the number of unique genotypes, rows, ranges, and the replication structure.}
#'   \item{\code{locals_min_max}}{A data.frame containing the local minima and maxima of the mean trait values over time.}
#'   \item{\code{dt_long}}{A data.frame in long format, with columns for time, plot, row, range, genotype, trait, and value.}
#' }
#'
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
#'
#' head(results$summ_traits)
#' plot(results, label_size = 4, signif = TRUE, n_row = 2)
#' @import dplyr
#' @import tidyr
#' @importFrom stats sd median
read_HTP <- function(data, genotype, time, plot, traits, row, range) {
  if (is.null(data)) {
    stop("Error: data not found")
  }
  if (is.null(genotype)) {
    stop("No 'genotype' name column provided")
  }
  if (!genotype %in% names(data)) {
    stop(paste("No '", genotype, "' found in the data"))
  }
  if (any(is.na(data[, genotype]))) {
    stop(paste("Missing levels for the genotype factor"))
  }
  if (!time %in% names(data)) {
    stop(paste("No '", time, "' found in the data"))
  }
  if (is.null(traits)) {
    stop("No 'traits' argument provided")
  }
  if (is.null(row)) {
    stop("No 'row' name column provided")
  }
  if (!row %in% names(data)) {
    stop(paste("No '", row, "' found in the data"))
  }
  if (is.null(range)) {
    stop("No 'range' name column provided")
  }
  if (!range %in% names(data)) {
    stop(paste("No '", range, "' found in the data"))
  }
  for (i in traits) {
    if (!i %in% names(data)) {
      stop(paste("No '", i, "' column found"))
    }
    class_trait <- data[[i]] |> class()
    if (!class_trait %in% c("numeric", "integer")) {
      stop(
        paste0("The class of the trait '", i, "' should be numeric or integer.")
      )
    }
  }
  data <- data |>
    select(all_of(c(time, plot, row, range, genotype, traits))) |>
    mutate(
      time = .data[[time]],
      plot = .data[[plot]],
      row = .data[[row]],
      range = .data[[range]],
      genotype = .data[[genotype]],
      .keep = "unused",
      .before = 0
    )

  exp_design_resum <- data |>
    select(plot, genotype, row, range) |>
    unique.data.frame() |>
    group_by(genotype) |>
    mutate(gen_reps = n()) |>
    ungroup() |>
    summarise(
      n = n(),
      n_gen = n_distinct(genotype, na.rm = TRUE),
      n_row = n_distinct(row, na.rm = TRUE),
      n_range = n_distinct(range, na.rm = TRUE),
      num_of_reps = paste(sort(unique(gen_reps)), collapse = "_"),
      num_of_gen = paste(
        table(gen_reps) / sort(unique(gen_reps)),
        collapse = "_"
      )
    )

  dt_long <- data |>
    select(time, plot, row, range, genotype, all_of(traits)) |>
    pivot_longer(all_of(traits), names_to = "trait", values_to = "value")

  summ_traits <- dt_long |>
    group_by(trait, time) |>
    summarise(
      Min = suppressWarnings(min(value, na.rm = TRUE)),
      Mean = mean(value, na.rm = TRUE),
      Median = median(value, na.rm = TRUE),
      Max = suppressWarnings(max(value, na.rm = TRUE)),
      SD = sd(value, na.rm = TRUE),
      CV = SD / Mean,
      n = sum(!is.na(value)),
      miss = sum(is.na(value)),
      `miss%` = miss / n(),
      `neg%` = sum(value < 0, na.rm = TRUE) / n,
      .groups = "drop"
    )

  l <- which(is.infinite(summ_traits$Min))
  summ_traits[l, c("Min", "Mean", "Max")] <- NA

  max_min <- dt_long |>
    group_by(trait, time) |>
    summarise(mean = mean(value, na.rm = TRUE), .groups = "drop") |>
    arrange(trait, time) |>
    group_by(trait) |>
    summarise(
      local_min_at = paste(local_min_max(mean, time)$days_min, collapse = "_"),
      local_max_at = paste(local_min_max(mean, time)$days_max, collapse = "_"),
      .groups = "drop"
    )

  out <- list(
    summ_traits = summ_traits,
    exp_design_resum = exp_design_resum,
    locals_min_max = max_min,
    dt_long = dt_long
  )

  class(out) <- "read_HTP"
  return(out)
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
