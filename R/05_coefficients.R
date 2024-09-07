#' Coefficients of an object of class \code{modeler}
#'
#' @description Coefficients for an object of class \code{modeler}
#' @aliases coef.modeler
#' @param x An object inheriting from class \code{modeler} resulting of
#' executing the function \code{modeler()}
#' @param id A unique identifier to filter by. \code{NULL} by default.
#' @param metadata TRUE or FALSE. Whether to bring the metadata or not when calculating the coefficients.
#' @param df TRUE or FALSE. Whether to return the degrees of freedom or not when calculating the coefficients. \code{FALSE} by default.
#' @param ... Further parameters. For future improvements.
#' @author Johan Aparicio [aut]
#' @method coef modeler
#' @return A data.frame object with coefficients and standard errors.
#' @export
#' @examples
#' library(flexFitR)
#' data(dt_potato)
#' explorer <- explorer(dt_potato, x = DAP, y = c(Canopy, GLI_2), id = Plot)
#' mod_1 <- dt_potato |>
#'   modeler(
#'     x = DAP,
#'     y = Canopy,
#'     grp = Plot,
#'     fn = "fn_piwise",
#'     parameters = c(t1 = 45, t2 = 80, k = 0.9),
#'     subset = c(15, 2, 45),
#'     add_zero = TRUE,
#'     max_as_last = TRUE
#'   )
#' print(mod_1)
#' coef(mod_1, id = 2)
#' @import dplyr
#' @importFrom stats pt
coef.modeler <- function(x,
                         id = NULL,
                         metadata = FALSE,
                         df = FALSE, ...) {
  # Check the class of x
  if (!inherits(x, "modeler")) {
    stop("The object should be of class 'modeler'.")
  }
  keep <- x$keep
  dt <- x$param
  if (!is.null(id)) {
    if (!all(id %in% unique(dt$uid))) {
      stop("ids not found in x.")
    }
    uid <- id
  } else {
    uid <- unique(dt$uid)
  }
  .get_coef <- function(fit, df) {
    hessian <- fit$hessian
    rdf <- (fit$n_obs - fit$p)
    varerr <- fit$param$sse / rdf
    mat_hess <- try(sqrt(diag(solve(hessian)) * 2 * varerr), silent = TRUE)
    if (inherits(mat_hess, "try-error")) mat_hess <- NA
    ccoef <- coef(fit$kkopt) |>
      as.data.frame() |>
      tibble::rownames_to_column("method") |>
      dplyr::filter(method == fit$param$method) |>
      tidyr::pivot_longer(
        cols = -method,
        names_to = "coefficient",
        values_to = "solution"
      ) |>
      dplyr::mutate(std.error = mat_hess) |>
      dplyr::select(-method) |>
      dplyr::mutate(uid = fit$uid, .before = coefficient) |>
      dplyr::mutate(
        `t value` = solution / std.error,
        `Pr(>|t|)` = 2 * pt(abs(`t value`), rdf, lower.tail = FALSE)
      )
    if (df) {
      ccoef <- mutate(ccoef, rdf = rdf)
    }
    ccoef <- full_join(
      x = select(fit$param, uid),
      y = ccoef,
      by = "uid"
    )
    return(ccoef)
  }
  fit_list <- x$fit
  id <- which(unlist(lapply(fit_list, function(x) x$uid)) %in% uid)
  fit_list <- fit_list[id]
  coeff <- do.call(
    what = rbind,
    args = suppressWarnings(lapply(fit_list, FUN = .get_coef, df))
  ) |>
    as_tibble()
  if (metadata) {
    coeff |>
      left_join(
        y = select(dt, uid, all_of(keep)),
        by = "uid"
      ) |>
      relocate(all_of(keep), .after = uid)
  } else {
    return(coeff)
  }
}
