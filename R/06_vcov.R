#' Variance-Covariance matrix for an object of class \code{modeler}
#'
#' @description Extract the variance-covariance matrix for the parameter estimates
#' from an object of class \code{modeler}.
#' @aliases vcov.modeler
#' @param x An object of class \code{modeler}, typically the result of calling
#' the \code{modeler()} function.
#' @param id An optional unique identifier to filter by a specific group.
#' Default is \code{NULL}.
#' @param ... Additional parameters for future functionality.
#' @author Johan Aparicio [aut]
#' @method vcov modeler
#' @return A list of matrices, where each matrix represents the variance-covariance
#' matrix of the estimated parameters for each group or fit.
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
#'     subset = c(15, 2, 45)
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
