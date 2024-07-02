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
#' \donttest{
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
#' out <- canopy_HTP(x = results, index = "Canopy", plot_id = c(22, 40))
#' plot(out, c(22, 40))
#' print(out)
#' }
print.modeler_HTP <- function(x, ...) {
  cat("-------------------------------------------------------------------------\n")
  cat("Optimization Results:\n")
  cat("-------------------------------------------------------------------------\n")
  print(head(x$param))
  cat(
    "\n-------------------------------------------------------------------------\n"
  )
  cat("Target Function:\n")
  cat("-------------------------------------------------------------------------\n")
  print(x$fn)
  cat("\n")
}
