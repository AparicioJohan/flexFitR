#' Print an object of class \code{modeler}
#'
#' @description Prints information about \code{modeler} function.
#'
#' @aliases print.modeler
#' @usage \method{print}{modeler}(x, ...)
#' @param x An object fitted with the function \code{modeler()}.
#' @param ... Options used by the tibble package to format the output. See
#' `tibble::print()` for more details.
#' @author Johan Aparicio [aut]
#' @method print modeler
#' @return an object inheriting from class \code{modeler}.
#' @importFrom utils head
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
#'     subset = c(1:5)
#'   )
#' plot(mod_1, id = c(1:4))
#' print(mod_1)
print.modeler <- function(x, ...) {
  param <- select(x$param, -all_of(c(x$keep, "fn_name")))
  trait <- unique(x$dt$var)
  cat("\nCall:\n")
  .list_names <- unique.data.frame(select(x$param, uid, fn_name)) |>
    group_by(fn_name) |>
    summarise(n = n()) |>
    pull(n, fn_name)
  for (i in seq_along(.list_names)) {
    call <- create_call(names(.list_names)[i])
    grps <- ifelse(
      test = length(.list_names) > 1,
      yes = paste0(" | uid (", .list_names[i], ")"),
      no = ""
    )
    chr <- paste0(trait, " ~ ", deparse(call), grps)
    cat(sub("(x", paste0("(", x$x_var), x = chr, fixed = TRUE), "\n")
  }
  cat("\n")
  cat("Residuals (`Standardized`):\n")
  resum <- summary(x$dt$.std_resid)
  print(resum)
  cat("\n")
  cat("Optimization Results `head()`:\n")
  print(as.data.frame(head(param, 4)), digits = 3, row.names = FALSE)
  cat("\n")
  cat("Metrics:\n")
  total_time <- x$execution
  dt <- x$metrics |>
    group_by(uid) |>
    arrange(sse) |>
    slice(1) |>
    ungroup()
  conv <- dt |>
    summarise(conv = round(sum(convergence %in% 0) / n() * 100, 2)) |>
    mutate(conv = paste0(conv, "%")) |>
    pull(conv)
  ite <- dt |>
    summarise(ite = round(mean(fevals, na.rm = TRUE), 2)) |>
    mutate(ite = paste0(ite, " (id)")) |>
    pull(ite)
  info <- data.frame(
    Groups = length(unique(dt$uid)),
    `Timing` = round(total_time, 4),
    Convergence = conv,
    `Iterations` = ite,
    check.names = FALSE
  )
  print(info, row.names = FALSE)
  cat("\n")
}
