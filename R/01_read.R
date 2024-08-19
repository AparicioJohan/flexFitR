#' Read HTP Data
#'
#' Reads and processes high-throughput phenotyping (HTP) data from a data frame in wide format.
#'
#' This function processes and prepares data to be analyzed with \code{modeler_HTP()}.
#'
#' @param data A data.frame in a wide format containing HTP data.
#' @param x The name of the column in `data` that contains time points.
#' @param y The names of the columns in `data` that contain the variables to be analyzed.
#' @param id The name of the column in `data` that contains IDs or unique identifiers.
#' @param .keep The names of the columns in `data` to keep across the analysis.
#'
#' @return An object of class \code{read_HTP}, which is a list containing the following elements:
#' \describe{
#'   \item{\code{summ_traits}}{A data.frame containing summary statistics for each trait at each time point, including minimum, mean, median, maximum, standard deviation, coefficient of variation, number of non-missing values, percentage of missing values, and percentage of negative values.}
#'   \item{\code{metadata}}{A data.frame summarizing the metadata.}
#'   \item{\code{locals_min_max}}{A data.frame containing the local minima and maxima of the mean y values over time.}
#'   \item{\code{dt_long}}{A data.frame in long format, with columns for uid, .keep, var, x, and y}
#'   \item{\code{.keep}}{A character vector with the names of the variables to keep across.}
#' }
#'
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
#' names(results)
#' head(results$summ_traits)
#' plot(results, label_size = 4, signif = TRUE, n_row = 2)
#' # New data format
#' head(results$dt_long)
#' @import dplyr
#' @import tidyr
#' @importFrom stats sd median
read_HTP <- function(data, x, y, id, .keep) {
  if (is.null(data)) {
    stop("Error: data not found")
  }
  id <- names(select(data, {{ id }}))
  x <- names(select(data, {{ x }}))
  y <- names(select(data, {{ y }}))
  .keep <- names(select(data, {{ .keep }}))
  for (i in y) {
    class_trait <- data[[i]] |> class()
    if (!class_trait %in% c("numeric", "integer")) {
      stop(
        paste0("Class of the trait '", i, "' should be numeric or integer.")
      )
    }
  }
  check_metadata(data, .keep)
  data <- data |>
    select(all_of(c(id, .keep, x, y))) |>
    mutate(uid = .data[[id]], .keep = "unused", .before = 0) |>
    rename(x = all_of(x))
  resum <- summarize_metadata(data, cols = c("uid", "x", .keep))
  dt_long <- data |>
    select(uid, all_of(.keep), x, all_of(y)) |>
    pivot_longer(all_of(y), names_to = "var", values_to = "y") |>
    relocate(x, .after = var)
  summ_traits <- dt_long |>
    group_by(var, x) |>
    summarise(
      Min = suppressWarnings(min(y, na.rm = TRUE)),
      Mean = mean(y, na.rm = TRUE),
      Median = median(y, na.rm = TRUE),
      Max = suppressWarnings(max(y, na.rm = TRUE)),
      SD = sd(y, na.rm = TRUE),
      CV = SD / Mean,
      n = sum(!is.na(y)),
      miss = sum(is.na(y)),
      `miss%` = miss / n(),
      `neg%` = sum(y < 0, na.rm = TRUE) / n,
      .groups = "drop"
    )
  l <- which(is.infinite(summ_traits$Min))
  summ_traits[l, c("Min", "Mean", "Max")] <- NA
  max_min <- dt_long |>
    group_by(var, x) |>
    summarise(mean = mean(y, na.rm = TRUE), .groups = "drop") |>
    arrange(var, x) |>
    group_by(var) |>
    summarise(
      local_min_at = paste(local_min_max(mean, x)$days_min, collapse = "_"),
      local_max_at = paste(local_min_max(mean, x)$days_max, collapse = "_"),
      .groups = "drop"
    )
  out <- list(
    summ_traits = summ_traits,
    metadata = resum,
    locals_min_max = max_min,
    dt_long = dt_long,
    .keep = .keep
  )
  class(out) <- "read_HTP"
  return(out)
}

#' @noRd
check_metadata <- function(data, metadata = NULL) {
  # Check if data is NULL
  if (is.null(data)) {
    stop("The dataset cannot be NULL.")
  }
  if (is.null(metadata)) {
    return()
  }
  # Iterate over each variable in the metadata vector
  for (var in metadata) {
    # Check if the variable exists in the dataset
    if (!var %in% names(data)) {
      stop(paste("Variable", var, "is not found in the dataset."))
    }
    # Check for missing values
    if (any(is.na(data[[var]]))) {
      stop(paste("Variable", var, "contains missing values."))
    }
  }
}

#' @noRd
summarize_metadata <- function(data = NULL, cols = NULL) {
  # Initialize an empty list to store summaries
  summaries <- list()
  # Iterate over each variable in the metadata vector
  for (var in 1:length(cols)) {
    # Extract the variable data
    var_data <- data[[cols[var]]]
    # Create a summary for the variable
    var_summary <- list(
      Column = cols[var],
      Type = class(var_data),
      Unique_Values = length(unique(var_data))
    )
    # Append the summary to the list
    summaries[[var]] <- var_summary
  }
  # Convert the list of summaries to a data frame
  summary_df <- do.call(rbind, lapply(summaries, as.data.frame))
  return(summary_df)
}
