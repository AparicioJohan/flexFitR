#' Confidence Intervals for a modeler Object
#'
#' @description Extract confidence intervals for the estimated parameters of an
#' object of class \code{modeler}.
#' @aliases confint.modeler
#' @param x An object of class \code{modeler}, typically the result of calling
#' the \code{modeler()} function.
#' @param parm A character vector specifying which parameters should have
#' confidence intervals calculated. If \code{NULL}, confidence intervals for all
#' parameters are returned. Default is \code{NULL}.
#' @param level A numeric value indicating the confidence level for the intervals.
#' Default is 0.95, corresponding to a 95\% confidence interval.
#' @param id An optional unique identifier to filter by a specific group.
#' Default is \code{NULL}.
#' @param ... Additional parameters for future functionality.
#' @author Johan Aparicio [aut]
#' @method confint modeler
#' @return A \code{tibble} containing the lower and upper confidence limits for
#' each specified parameter.
#' @export
#' @examples
#' library(flexFitR)
#' data(dt_potato)
#' mod_1 <- dt_potato |>
#'   modeler(
#'     x = DAP,
#'     y = Canopy,
#'     grp = Plot,
#'     fn = "fn_linear_sat",
#'     parameters = c(t1 = 45, t2 = 80, k = 0.9),
#'     subset = c(15, 35, 45)
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
