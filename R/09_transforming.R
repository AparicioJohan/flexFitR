# data <- dt_potato_20 # |>  filter(Plot %in% 1)
# x <- "DAP"
# y <- "Canopy"
# grp <- "Plot"
# metadata <- c("Trial", "Row", "Range", "Gen")
# # metadata <- NULL
# max_as_last <- FALSE
# check_negative <- FALSE
# add_zero <- FALSE
# interval <- c(40, 90)

#' @noRd
transform <- function(data = NULL,
                      x = NULL,
                      y = NULL,
                      grp = NULL,
                      metadata = NULL,
                      max_as_last = FALSE,
                      check_negative = FALSE,
                      add_zero = FALSE,
                      interval = NULL) {
  if (is.null(data)) {
    stop("Error: data not found")
  }
  dt <- mutate(data, .y = .data[[y]], .after = all_of(y))
  if (max_as_last) {
    dt <- dt |>
      group_by(.data[[grp]]) |>
      mutate(max = max(.y, na.rm = TRUE), pos = .data[[x]][which.max(.y)]) |>
      mutate(.y = ifelse(.data[[x]] <= pos, .y, max)) |>
      select(-max, -pos) |>
      ungroup()
  }
  if (check_negative) {
    dt <- mutate(dt, .y = ifelse(.y < 0, 0, .y))
  }
  if (add_zero) {
    dt <- dt |>
      group_by(.data[[grp]]) |>
      mutate(across(!metadata, ~NA)) |>
      mutate(!!x := 0, .y = 0) |>
      unique.data.frame() |>
      ungroup() |>
      rbind.data.frame(dt)
  }
  if (!is.null(interval)) {
    dt <- dt |>
      filter(.data[[x]] >= interval[1] & .data[[x]] <= interval[2]) |>
      droplevels()
  }
  dt <- select(dt, -all_of(y))
  names(dt)[names(dt) == ".y"] <- y
  return(dt)
}

# test <- transform(
#   data = data,
#   x = "DAP",
#   y = "Canopy",
#   grp = "Plot",
#   metadata = c("Trial", "Row", "Range", "Gen"),
#   max_as_last = FALSE,
#   check_negative = FALSE,
#   add_zero = TRUE,
#   interval = c(0, 200)
# )
#
# explorer(
#   data = test,
#   x = "DAP",
#   y = "Canopy",
#   id = "Plot"
# ) |> plot(type = "evolution")
