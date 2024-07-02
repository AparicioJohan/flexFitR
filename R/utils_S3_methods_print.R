#' Print an object of class \code{modeler_HTP}
#'
#' @description Prints information about \code{modeler_HTP} function.
#'
#' @aliases print.modeler_HTP
#' @usage \method{print}{modeler_HTP}(x, ...)
#' @param x An object fitted with the function \code{modeler_HTP()}.
#' @param ... Options used by the tibble package to format the output. See
#' `tibble::print()` for more details.
#' @author Johan Aparicio [aut]
#' @method print modeler_HTP
#' @return an object inheriting from class \code{modeler_HTP}.
#' @importFrom utils head
#' @export
#' @examples
#' library(exploreHTP)
#' data(dt_potato)
#' results <- read_HTP(
#'   data = dt_potato,
#'   genotype = "Gen",
#'   time = "DAP",
#'   plot = "Plot",
#'   traits = c("Canopy", "PH"),
#'   row = "Row",
#'   range = "Range"
#' )
#' out <- canopy_HTP(x = results, index = "Canopy", plot_id = c(22, 40))
#' plot(out, plot_id = c(22, 40))
#' print(out)
print.modeler_HTP <- function(x, ...) {
  param <- select(x$param, -c(row, range))
  cat("Call:\n")
  print(x$fn)
  cat("\n")
  cat("Sum of Squares Error:\n")
  print(summary(param$sse))
  cat("\n")
  cat("Optimization Results `head()`:\n")
  print(as.data.frame(head(param, 4)), digits = 3, row.names = FALSE)
  cat("\n")
  cat("Metrics:\n")
  total_time <- sum(x$metrics$xtime)
  dt <- x$metrics |>
    group_by(plot, genotype) |>
    arrange(sse) |>
    slice(1) |>
    ungroup()
  conv <- dt |>
    summarise(conv = round(sum(convergence %in% 0) / n() * 100, 2)) |>
    mutate(conv = paste0(conv, "%")) |>
    pull(conv)
  ite <- dt |>
    summarise(ite = mean(fevals, na.rm = TRUE)) |>
    mutate(ite = paste0(ite, " (plot)")) |>
    pull(ite)
  info <- data.frame(
    Plots = nrow(dt),
    `Timing` = paste0(round(total_time, 4), " (min)"),
    Convergence = conv,
    `Iterations` = ite,
    check.names = FALSE
  )
  print(info, row.names = FALSE)
}
