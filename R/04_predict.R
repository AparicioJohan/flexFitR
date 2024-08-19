#' Predict an object of class \code{modeler_HTP}
#'
#' @description Model predictions for an object of class \code{modeler_HTP}
#' @aliases predict.modeler_HTP
#' @param object An object inheriting from class \code{modeler_HTP} resulting of
#' executing the function \code{modeler_HTP()}
#' @param x A numeric time point to make the prediction. Can be more than one.
#' @param id A numeric to filter by unique identifier. NULL by default.
#' @param metadata TRUE or FALSE. Whether to bring the metadata or not when calculating the coefficients.
#' @param ... Further parameters. For future improvements.
#' @author Johan Aparicio [aut]
#' @method predict modeler_HTP
#' @return A data.frame object with predicted values.
#' @export
#' @examples
#' library(exploreHTP)
#' data(dt_potato)
#' explorer <- read_HTP(dt_potato, x = DAP, y = c(Canopy, GLI_2), id = Plot)
#' mod_1 <- dt_potato |>
#'   modeler_HTP(
#'     x = DAP,
#'     y = Canopy,
#'     by = Plot,
#'     id = c(15, 2, 45),
#'     parameters = c(t1 = 45, t2 = 80, k = 0.9),
#'     fn = "fn_piwise",
#'     max_as_last = TRUE
#'   )
#' mod_1
#' predict(mod_1, x = 45, id = 2)
#' @import ggplot2
#' @import dplyr
predict.modeler_HTP <- function(object,
                                x = NULL,
                                id = NULL,
                                metadata = FALSE, ...) {
  # Check the class of object
  if (!inherits(object, "modeler_HTP")) {
    stop("The object should be of class 'modeler_HTP'.")
  }
  if (is.null(x)) {
    stop("Argument x is required for predictions.")
  }
  keep <- object$.keep
  data <- object$dt
  dt <- object$param
  if (!is.null(id)) {
    if (!all(id %in% unique(data$uid))) {
      stop("plot_ids not found in object.")
    }
    uid <- id
  } else {
    uid <- unique(data$uid)
  }
  fn <- object$fn
  limit_inf <- min(data$x, na.rm = TRUE)
  limit_sup <- object$max_time
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

#' Coefficients of an object of class \code{modeler_HTP}
#'
#' @description Coefficients for an object of class \code{modeler_HTP}
#' @aliases coef.modeler_HTP
#' @param x An object inheriting from class \code{modeler_HTP} resulting of
#' executing the function \code{modeler_HTP()}
#' @param id A numeric Id to filter by.
#' @param metadata TRUE or FALSE. Whether to bring the metadata or not when calculating the coefficients.
#' @param ... Further parameters. For future improvements.
#' @author Johan Aparicio [aut]
#' @method coef modeler_HTP
#' @return A data.frame object with coefficients and standard errors.
#' @export
#' @examples
#' library(exploreHTP)
#' data(dt_potato)
#' explorer <- read_HTP(dt_potato, x = DAP, y = c(Canopy, GLI_2), id = Plot)
#' mod_1 <- dt_potato |>
#'   modeler_HTP(
#'     x = DAP,
#'     y = Canopy,
#'     by = Plot,
#'     id = c(15, 2, 45),
#'     parameters = c(t1 = 45, t2 = 80, k = 0.9),
#'     fn = "fn_piwise",
#'     max_as_last = TRUE
#'   )
#' mod_1
#' coef(mod_1, id = 2)
#' @import dplyr
#' @importFrom stats pt
coef.modeler_HTP <- function(x, id = NULL, metadata = FALSE, ...) {
  # Check the class of x
  if (!inherits(x, "modeler_HTP")) {
    stop("The object should be of class 'modeler_HTP'.")
  }
  keep <- x$.keep
  dt <- x$param
  if (!is.null(id)) {
    if (!all(id %in% unique(dt$uid))) {
      stop("plot_ids not found in x.")
    }
    uid <- id
  } else {
    uid <- unique(dt$uid)
  }
  .get_coef <- function(fit) {
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
        `Pr(>|t|)` = pt(abs(`t value`), rdf, lower.tail = FALSE)
      )
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
    args = suppressWarnings(lapply(fit_list, FUN = .get_coef))
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


#' Variance-Covariance matrix for an object of class \code{modeler_HTP}
#'
#' @description vcov for an object of class \code{modeler_HTP}
#' @aliases vcov.modeler_HTP
#' @param x An object inheriting from class \code{modeler_HTP} resulting of
#' executing the function \code{modeler_HTP()}
#' @param id A numeric Id to filter by.
#' @param ... Further parameters. For future improvements.
#' @author Johan Aparicio [aut]
#' @method vcov modeler_HTP
#' @return A list object with matrices of the estimated covariances between the parameter estimates.
#' @export
#' @examples
#' library(exploreHTP)
#' data(dt_potato)
#' mod_1 <- dt_potato |>
#'   modeler_HTP(
#'     x = DAP,
#'     y = Canopy,
#'     by = Plot,
#'     id = c(15, 2, 45),
#'     parameters = c(t1 = 45, t2 = 80, k = 0.9),
#'     fn = "fn_piwise",
#'     max_as_last = TRUE
#'   )
#' mod_1
#' vcov(mod_1)
#' @import dplyr
#' @importFrom stats pt
vcov.modeler_HTP <- function(x, id = NULL, ...) {
  # Check the class of x
  if (!inherits(x, "modeler_HTP")) {
    stop("The object should be of class 'modeler_HTP'.")
  }
  dt <- x$param
  if (!is.null(id)) {
    if (!all(id %in% unique(dt$uid))) {
      stop("plot_ids not found in x.")
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
