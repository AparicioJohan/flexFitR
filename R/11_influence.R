#' Augment a \code{modeler} object with influence diagnostics
#'
#' @description This function computes various influence diagnostics, including
#'  standardized residuals, studentized residuals, and Cook's distance, for an
#'  object of class \code{modeler}.
#'
#' @param x An object of class \code{modeler}.
#' @param id Optional unique identifier to filter by a specific group. Default is \code{NULL}.
#' @param metadata Logical. If `TRUE`, metadata is included with the predictions. Default is `FALSE`.
#' @param ... Additional parameters for future functionality.
#' @author Johan Aparicio [aut]
#' @return A tibble containing the following columns:
#'   \item{uid}{Unique identifier for the group.}
#'   \item{fn_name}{Function name associated with the model.}
#'   \item{x}{Predictor variable values.}
#'   \item{y}{Observed response values.}
#'   \item{.fitted}{Fitted values from the model.}
#'   \item{.resid}{Raw residuals (observed - fitted).}
#'   \item{.hat}{Leverage values for each observation.}
#'   \item{.cooksd}{Cook's distance for each observation.}
#'   \item{.std.resid}{Standardized residuals.}
#'   \item{.stud.resid}{Studentized residuals.}
#' @export
#' @examples
#' library(flexFitR)
#' data(dt_potato)
#' mod_1 <- dt_potato |>
#'   modeler(
#'     x = DAP,
#'     y = Canopy,
#'     grp = Plot,
#'     fn = "fn_logistic",
#'     parameters = c(L = 100, k = 4, t0 = 40),
#'     subset = 2
#'   )
#' print(mod_1)
#' augment(mod_1)
#' @import dplyr
augment <- function(x, id = NULL, metadata = TRUE, ...) {
  # Check the class of x
  if (!inherits(x, "modeler")) {
    stop("The x should be of class 'modeler'.")
  }
  if (!is.null(id)) {
    if (!all(id %in% unique(x$dt$uid))) {
      stop("ids not found in x.")
    }
    uid <- id
  } else {
    uid <- unique(x$dt$uid)
  }
  dt <- x$param
  # List of models
  fit_list <- x$fit
  pos <- which(unlist(lapply(fit_list, function(x) x$uid)) %in% uid)
  fit_list <- fit_list[pos]
  .influence_residuals <- function(fit) {
    curve <- fit$fn_name
    rdf <- (fit$n_obs - fit$p)
    stderr <- sqrt(fit$param$sse / rdf)
    n <- fit$n_obs
    p <- fit$p
    x_vals <- fit$x
    y_vals <- fit$y
    estimated_params <- fit$type |>
      filter(type == "estimable") |>
      pull(value, name = parameter)
    uid <- fit$uid
    fix_params <- fit$type |>
      filter(type == "fixed") |>
      pull(value, name = parameter)
    if (length(fix_params) == 0) fix_params <- NA
    # Jacobian
    jac_matrix <- numDeriv::jacobian(
      func = ff,
      x = estimated_params,
      x_new = x_vals,
      curve = curve,
      fixed_params = fix_params
    )
    jtj_inv <- try(solve(t(jac_matrix) %*% jac_matrix), silent = TRUE)
    if (!inherits(jtj_inv, "try-error")) {
      H <- jac_matrix %*% jtj_inv %*% t(jac_matrix)
      hii <- diag(H)
    } else {
      hii <- NA
    }
    # Fitted values
    fitted.values <- ff(
      params = estimated_params,
      x_new = x_vals,
      curve = curve,
      fixed_params = fix_params
    )
    # Residuals
    raw_res <- y_vals - fitted.values
    rstandard <- raw_res / stderr
    rstudent <- raw_res / (stderr * sqrt(1 - hii))
    rstudent[is.infinite(rstudent)] <- NaN
    # Cook D
    cooks_d <- (raw_res^2 / (p * stderr^2)) * (hii / (1 - hii)^2)
    cooks_d[is.infinite(cooks_d)] <- NaN
    results <- data.frame(
      uid = uid,
      fn_name = curve,
      x = x_vals,
      y = y_vals,
      .fitted = fitted.values,
      .resid = raw_res,
      .hat = hii,
      .cooksd = cooks_d,
      .std.resid = rstandard,
      .stud.resid = rstudent
    )
    return(results)
  }
  influence <- do.call(
    what = rbind,
    args = suppressWarnings(lapply(X = fit_list, FUN = .influence_residuals))
  ) |>
    as_tibble()
  if (metadata) {
    keep <- x$keep
    influence |>
      left_join(
        y = unique.data.frame(select(dt, uid, all_of(keep))),
        by = "uid"
      ) |>
      relocate(all_of(keep), .after = fn_name)
  } else {
    return(influence)
  }
}
