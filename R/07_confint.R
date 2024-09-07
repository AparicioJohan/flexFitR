#'  Confidence Intervals for an object of class \code{modeler}
#'
#' @description confint for an object of class \code{modeler}
#' @aliases confint.modeler
#' @param x An object inheriting from class \code{modeler} resulting of
#' executing the function \code{modeler()}
#' @param parm A specification of which parameters are to be given confidence intervals, must be a vector of names. If missing, all parameters are considered.
#' @param level The confidence level required. Default is 0.95.
#' @param id A unique identifier to filter by. \code{NULL} by default.
#' @param ... Further parameters. For future improvements.
#' @author Johan Aparicio [aut]
#' @method confint modeler
#' @return A tibble with columns giving lower and upper confidence limits for each parameter.
#' @export
#' @examples
#' library(flexFitR)
#' data(dt_potato)
#' mod_1 <- dt_potato |>
#'   modeler(
#'     x = DAP,
#'     y = Canopy,
#'     grp = Plot,
#'     fn = "fn_piwise",
#'     parameters = c(t1 = 45, t2 = 80, k = 0.9),
#'     subset = c(15, 35, 45),
#'     add_zero = TRUE,
#'     max_as_last = TRUE
#'   )
#' print(mod_1)
#' confint(mod_1)
#' @import dplyr
#' @importFrom stats qt
confint.modeler <- function(x, parm = NULL, level = 0.95, id = NULL, ...) {
  # Check the class of x
  if (!inherits(x, "modeler")) {
    stop("The object should be of class 'modeler'.")
  }
  dt <- x$param
  if (!is.null(id)) {
    if (!all(id %in% unique(dt$uid))) {
      stop("ids not found in x.")
    }
    uid <- id
  } else {
    uid <- unique(dt$uid)
  }
  ci_table <- coef.modeler(x, df = TRUE, id = uid) |>
    mutate(
      t_value = qt(1 - (1 - level) / 2, df = rdf),
      ci_lower = solution - t_value * std.error,
      ci_upper = solution + t_value * std.error
    ) |>
    select(-c(`t value`, `Pr(>|t|)`, rdf, t_value))
  if (!is.null(parm)) {
    ci_table <- ci_table |> filter(coefficient %in% parm)
  }
  return(ci_table)
}
