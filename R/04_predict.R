#' Predict an object of class \code{modeler}
#'
#' @description Model predictions for an object of class \code{modeler}
#' @aliases predict.modeler
#' @param object An object inheriting from class \code{modeler} resulting of
#' executing the function \code{modeler()}
#' @param x A numeric time point to make the prediction. Can be more than one.
#' @param id A unique identifier to filter by. \code{NULL} by default.
#' @param metadata \code{TRUE} or \code{FALSE}. Whether to bring the metadata or not when calculating the coefficients.
#' @param ... Further parameters. For future improvements.
#' @author Johan Aparicio [aut]
#' @method predict modeler
#' @return A data.frame object with predicted values.
#' @export
#' @examples
#' library(exploreHTP)
#' data(dt_potato)
#' explorer <- explorer(dt_potato, x = DAP, y = c(Canopy, GLI_2), id = Plot)
#' mod_1 <- dt_potato |>
#'   modeler(
#'     x = DAP,
#'     y = Canopy,
#'     grp = Plot,
#'     id = c(15, 2, 45),
#'     fn = "fn_piwise",
#'     parameters = c(t1 = 45, t2 = 80, k = 0.9),
#'     add_zero = TRUE,
#'     max_as_last = TRUE
#'   )
#' mod_1
#' predict(mod_1, x = 45, id = 2)
#' @import ggplot2
#' @import dplyr
predict.modeler <- function(object,
                            x = NULL,
                            id = NULL,
                            metadata = FALSE, ...) {
  # Check the class of object
  if (!inherits(object, "modeler")) {
    stop("The object should be of class 'modeler'.")
  }
  if (is.null(x)) {
    stop("Argument x is required for predictions.")
  }
  keep <- object$keep
  data <- object$dt
  dt <- object$param
  if (!is.null(id)) {
    if (!all(id %in% unique(data$uid))) {
      stop("ids not found in object.")
    }
    uid <- id
  } else {
    uid <- unique(data$uid)
  }
  limit_inf <- min(data$x, na.rm = TRUE)
  limit_sup <- object$max_x
  if (!all(limit_inf <= x & x <= limit_sup)) {
    stop("x needs to be in the interval <", limit_inf, ", ", limit_sup, ">")
  }
  .delta_method <- function(fit, x_new, curve) {
    tt <- fit$hessian
    rdf <- (fit$n_obs - fit$p)
    varerr <- fit$param$sse / rdf
    vcov_mat <- try(solve(tt) * 2 * varerr, silent = TRUE)
    best <- fit$details$method
    estimated_params <- coef(fit$kkopt)[best, ]
    uid <- fit$uid
    fix_params <- fit$type |>
      filter(type == "fixed") |>
      pull(value, name = parameter)
    if (length(fix_params) == 0) fix_params <- NA
    jac_matrix <- numDeriv::jacobian(
      func = ff,
      x = estimated_params,
      x_new = x_new,
      curve = curve,
      fixed_params = fix_params
    )
    if (!inherits(vcov_mat, "try-error")) {
      std_errors <- sqrt(diag(jac_matrix %*% vcov_mat %*% t(jac_matrix)))
    } else {
      std_errors <- NA
    }
    # Confidence intervals for predictions
    z_value <- qnorm(0.975)
    predicted_values <- ff(
      params = estimated_params,
      x_new = x_new,
      curve = curve,
      fixed_params = fix_params
    )
    ci_lower <- predicted_values - z_value * std_errors
    ci_upper <- predicted_values + z_value * std_errors
    # Combine results
    results <- data.frame(
      uid = uid,
      x_new = x_new,
      predicted.value = predicted_values,
      std.error = std_errors
    )
    results <- full_join(
      x = select(fit$param, uid),
      y = results,
      by = "uid"
    )
  }
  fit_list <- object$fit
  id <- which(unlist(lapply(fit_list, function(x) x$uid)) %in% uid)
  fit_list <- fit_list[id]
  predictions <- do.call(
    what = rbind,
    args = suppressWarnings(
      lapply(fit_list, FUN = .delta_method, x_new = x, curve = object$fun)
    )
  ) |>
    as_tibble()
  if (metadata) {
    predictions |>
      left_join(
        y = select(dt, uid, all_of(keep)),
        by = "uid"
      ) |>
      relocate(all_of(keep), .after = uid)
  } else {
    return(predictions)
  }
}

ff <- function(params, x_new, curve, fixed_params = NA) {
  arg <- names(formals(curve))[-1]
  values <- paste(params, collapse = ", ")
  if (!any(is.na(fixed_params))) {
    names(params) <- arg[!arg %in% names(fixed_params)]
    values <- paste(
      paste(names(params), params, sep = " = "),
      collapse = ", "
    )
    fix <- paste(
      paste(names(fixed_params), fixed_params, sep = " = "),
      collapse = ", "
    )
    values <- paste(values, fix, sep = ", ")
  }
  string <- paste("sapply(x_new, FUN = ", curve, ", ", values, ")", sep = "")
  y_hat <- eval(parse(text = string))
  return(y_hat)
}

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
#' library(exploreHTP)
#' data(dt_potato)
#' explorer <- explorer(dt_potato, x = DAP, y = c(Canopy, GLI_2), id = Plot)
#' mod_1 <- dt_potato |>
#'   modeler(
#'     x = DAP,
#'     y = Canopy,
#'     grp = Plot,
#'     id = c(15, 2, 45),
#'     fn = "fn_piwise",
#'     parameters = c(t1 = 45, t2 = 80, k = 0.9),
#'     add_zero = TRUE,
#'     max_as_last = TRUE
#'   )
#' mod_1
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
#' library(exploreHTP)
#' data(dt_potato)
#' mod_1 <- dt_potato |>
#'   modeler(
#'     x = DAP,
#'     y = Canopy,
#'     grp = Plot,
#'     id = c(15, 2, 45),
#'     fn = "fn_piwise",
#'     parameters = c(t1 = 45, t2 = 80, k = 0.9),
#'     add_zero = TRUE,
#'     max_as_last = TRUE
#'   )
#' mod_1
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
#' library(exploreHTP)
#' data(dt_potato)
#' mod_1 <- dt_potato |>
#'   modeler(
#'     x = DAP,
#'     y = Canopy,
#'     grp = Plot,
#'     id = c(15, 35, 45),
#'     fn = "fn_piwise",
#'     parameters = c(t1 = 45, t2 = 80, k = 0.9),
#'     add_zero = TRUE,
#'     max_as_last = TRUE
#'   )
#' mod_1
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
  ci_table <- coef.modeler(x, df = TRUE, id = id) |>
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
