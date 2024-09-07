#' Variance-Covariance matrix for an object of class \code{modeler}
#'
#' @description vcov for an object of class \code{modeler}
#' @aliases vcov.modeler
#' @param x An object inheriting from class \code{modeler} resulting of
#' executing the function \code{modeler()}
#' @param id A unique identifier to filter by. \code{NULL} by default.
#' @param ... Further parameters. For future improvements.
#' @author Johan Aparicio [aut]
#' @method vcov modeler
#' @return A list object with matrices of the estimated covariances between the parameter estimates.
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
#'     subset = c(15, 2, 45),
#'     add_zero = TRUE,
#'     max_as_last = TRUE
#'   )
#' print(mod_1)
#' vcov(mod_1)
#' @import dplyr
#' @importFrom stats pt
vcov.modeler <- function(x, id = NULL, ...) {
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
  .get_vcov <- function(fit) {
    hessian <- fit$hessian
    rdf <- (fit$n_obs - fit$p)
    varerr <- fit$param$sse / rdf
    mat_hess <- try((solve(hessian) * 2 * varerr), silent = TRUE)
    if (inherits(mat_hess, "try-error")) mat_hess <- NA
    mat_hess <- list(mat_hess)
    names(mat_hess) <- fit$uid
    return(mat_hess)
  }
  fit_list <- x$fit
  id <- which(unlist(lapply(fit_list, function(x) x$uid)) %in% uid)
  fit_list <- fit_list[id]
  vcov_out <- do.call(
    what = c,
    args = suppressWarnings(lapply(fit_list, FUN = .get_vcov))
  )
  return(vcov_out)
}
