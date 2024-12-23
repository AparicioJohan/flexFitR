#' Transform variables in a data frame
#'
#' This function performs transformations on specified columns of a data frame,
#' including truncating maximum values, handling negative values, and adding a zero
#' to the series. It allows for grouping and supports retaining metadata in the output.
#'
#' @param data A `data.frame` containing the input data for analysis.
#' @param x The name of the column in `data` representing the independent variable (x points).
#' @param y The name of the column(s) in `data` containing variables to transform.
#' @param grp Column(s) in `data` used as grouping variable(s). Defaults to `NULL` (optional).
#' @param metadata Names of columns to retain in the output. Defaults to `NULL` (optional).
#' @param max_as_last Logical. If `TRUE`, appends the maximum value after reaching the maximum. Default is `FALSE`.
#' @param check_negative Logical. If `TRUE`, converts negative values in the data to zero. Default is `FALSE`.
#' @param add_zero Logical. If `TRUE`, adds a zero value to the series at the start. Default is `FALSE`.
#' @param interval A numeric vector of length 2 (start and end) specifying the range to filter the data. Defaults to `NULL`.
#' @return A transformed `data.frame` with the specified modifications applied.
#' @export
#' @examples
#' data(dt_potato)
#' new_data <- series_mutate(
#'   data = dt_potato,
#'   x = DAP,
#'   y = GLI,
#'   grp = gid,
#'   max_as_last = TRUE,
#'   check_negative = TRUE
#' )
series_mutate <- function(data,
                          x,
                          y,
                          grp,
                          metadata,
                          max_as_last = FALSE,
                          check_negative = FALSE,
                          add_zero = FALSE,
                          interval = NULL) {
  # Check if required arguments are provided
  if (missing(data)) {
    stop("Error: `data` argument is missing.")
  }
  if (missing(x) || missing(y)) {
    stop("Error: `x` and `y` columns must be specified.")
  }
  # Extract column names
  x_col <- names(select(data, {{ x }}))
  y_cols <- names(select(data, {{ y }}))
  grp_cols <- names(select(data, {{ grp }}))
  metadata_cols <- names(select(data, {{ metadata }}))
  # Validate interval
  if (!is.null(interval) && length(interval) != 2) {
    stop("Error: `interval` must be a vector of length 2 (start and end).")
  }
  # Handle grouping column
  if (length(grp_cols) == 0) {
    data <- data |> mutate(.grp = 1)
    grp <- ".grp"
  } else if (length(grp_cols) > 1) {
    data <- data |> unite(.grp, grp_cols, sep = "_", remove = FALSE)
    grp <- ".grp"
  }
  # Transformations
  dtnew <- data
  for (var in y_cols) {
    dt <- mutate(dtnew, .y = .data[[var]], .after = all_of(var))
    # Truncate maximum value
    if (max_as_last) {
      dt <- dt |>
        group_by(.data[[grp_cols]]) |>
        mutate(
          max = max(.y, na.rm = TRUE),
          pos = .data[[x_col]][which.max(.y)]
        ) |>
        mutate(.y = ifelse(.data[[x_col]] <= pos, .y, max)) |>
        select(-max, -pos) |>
        ungroup()
    }
    # Mutate negative values
    if (check_negative) {
      dt <- mutate(dt, .y = ifelse(.y < 0, 0, .y))
    }
    # Add zero to the serie
    if (add_zero) {
      if (any(dt[[x_col]] == 0)) {
        dt <- mutate(dt, .y = ifelse(.data[[x_col]] == 0, 0, .y))
      } else {
        tmp <- dt |>
          group_by(across(any_of(c(grp_cols, metadata_cols)))) |>
          transmute(!!x_col := 0, .y = 0) |>
          unique.data.frame() |>
          ungroup()
        cols <- names(tmp)
        dt <- dt |> full_join(tmp, by = cols)
      }
    }
    # Remove temporal variables
    dt <- dt |>
      arrange(across(any_of(c(grp_cols, ".grp", x_col)))) |>
      select(-all_of(var), -any_of(".grp"))
    names(dt)[names(dt) == ".y"] <- var
    dtnew <- dt
  }
  # Filtering Interval
  if (!is.null(interval)) {
    dt <- dt |>
      filter(.data[[x_col]] >= interval[1] & .data[[x_col]] <= interval[2]) |>
      droplevels()
  }
  return(dt)
}

# test <- data |>
#   transform(
#     x = DAP,
#     y = Canopy,
#     grp = Plot,
#     metadata = c(Trial, DAP, Plot, Row, Range, Gen, Yield, VineMaturity),
#     max_as_last = TRUE,
#     check_negative = FALSE,
#     add_zero = TRUE,
#     interval = c(0, 200)
#   ) # |>
#   transform(
#     x = DAP,
#     y = GLI,
#     grp = Plot,
#     metadata = c(Trial, Plot, Row, Range, Gen),
#     max_as_last = FALSE,
#     check_negative = FALSE,
#     add_zero = TRUE,
#     interval = c(0, 200)
#   )
# test
#
# explorer(
#   data = test,
#   x = "DAP",
#   y = "Canopy",
#   id = "Plot"
# ) |> plot(type = "evolution")
