#' Predict an object of class \code{modeler}
#'
#' @description Generate model predictions from an object of class \code{modeler}.
#' This function allows for flexible prediction types, including point predictions,
#' area under the curve (AUC), and first or second order derivatives.
#'
#' @aliases predict.modeler
#' @param object An object of class \code{modeler}, typically the result of calling
#' the \code{modeler()} function.
#' @param x A numeric value or vector specifying the points at which predictions
#' are made. For \code{type = "auc"}, \code{x} must be a vector of length 2 that
#' specifies the interval over which to calculate the AUC.
#' @param id Optional unique identifier to filter predictions by a specific group. Default is \code{NULL}.
#' @param type A character string specifying the type of prediction. Default is "point".
#' \describe{
#'   \item{\code{"point"}}{Predicts the value of \code{y} for the given \code{x}.}
#'   \item{\code{"auc"}}{Calculates the area under the curve (AUC) for the fitted model over the interval specified by \code{x}.}
#'   \item{\code{"fd"}}{Returns the first derivative (rate of change) of the model at the given \code{x} value(s).}
#'   \item{\code{"sd"}}{Returns the second derivative of the model at the given \code{x} value(s).}
#' }
#' @param se_interval A character string specifying the type of interval for
#' standard error calculation. Options are \code{"confidence"} (default) or
#' \code{"prediction"}.
#' @param n_points An integer specifying the number of points used to approximate
#' the area under the curve (AUC) when \code{type = "auc"}. Default is \code{1000}.
#' @param metadata Logical. If \code{TRUE}, metadata is included with the
#' predictions. Default is \code{FALSE}.
#' @param ... Additional parameters for future functionality.
#' @author Johan Aparicio [aut]
#' @method predict modeler
#' @return A \code{data.frame} containing the predicted values,
#' their associated standard errors, and optionally the metadata.
#' @export
#' @examples
#' library(flexFitR)
#' data(dt_potato_20)
#' mod_1 <- dt_potato_20 |>
#'   modeler(
#'     x = DAP,
#'     y = Canopy,
#'     grp = Plot,
#'     fn = "fn_piwise",
#'     parameters = c(t1 = 45, t2 = 80, k = 0.9),
#'     subset = c(15, 2, 45),
#'     options = list(add_zero = TRUE, max_as_last = TRUE)
#'   )
#' print(mod_1)
#' # Point Prediction
#' predict(mod_1, x = 45, type = "point", id = 2)
#' # AUC Prediction
#' predict(mod_1, x = c(0, 108), type = "auc", id = 2)
#' # First Derivative
#' predict(mod_1, x = 45, type = "fd", id = 2)
#' # Second Derivative
#' predict(mod_1, x = 45, type = "sd", id = 2)
#' @import ggplot2
#' @import dplyr
predict.modeler <- function(object,
                            x = NULL,
                            id = NULL,
                            type = c("point", "auc", "fd", "sd"),
                            se_interval = c("confidence", "prediction"),
                            n_points = 1000,
                            metadata = FALSE, ...) {
  # Check the class of object
  if (!inherits(object, "modeler")) {
    stop("The object should be of class 'modeler'.")
  }
  se_interval <- match.arg(se_interval)
  type <- match.arg(type)
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
  # List of models
  fit_list <- object$fit
  id <- which(unlist(lapply(fit_list, function(x) x$uid)) %in% uid)
  fit_list <- fit_list[id]
  # Point Estimation
  if (type == "point") {
    if (is.null(x)) {
      stop("Argument x is required for predictions.")
    }
    limit_inf <- min(data$x, na.rm = TRUE)
    limit_sup <- max(data$x, na.rm = TRUE)
    if (!all(limit_inf <= x & x <= limit_sup)) {
      stop("x needs to be in the interval <", limit_inf, ", ", limit_sup, ">")
    }
    predictions <- do.call(
      what = rbind,
      args = suppressWarnings(
        lapply(
          X = fit_list,
          FUN = .delta_method,
          x_new = x,
          curve = object$fun,
          se_interval = se_interval
        )
      )
    ) |>
      as_tibble()
  }
  # Area under the curve
  if (type == "auc") {
    if (!is.numeric(n_points) || n_points <= 0) {
      stop("n_points should be a positive numeric value.")
    }
    if (is.null(x)) {
      limit_inf <- min(data$x, na.rm = TRUE)
      limit_sup <- max(data$x, na.rm = TRUE)
    } else {
      if (length(x) < 2) stop("Lenght of x needs to be of size 2 for AUC.")
      limit_inf <- x[1]
      limit_sup <- x[2]
    }
    x <- c(limit_inf, limit_sup)
    predictions <- do.call(
      what = rbind,
      args = suppressWarnings(
        lapply(
          X = fit_list,
          FUN = .delta_method_auc,
          x_new = x,
          curve = object$fun,
          n_points = n_points
        )
      )
    ) |>
      as_tibble()
  }
  # Derivatives
  if (type %in% c("fd", "sd")) {
    if (is.null(x)) {
      stop("Argument x is required for predictions.")
    }
    limit_inf <- min(data$x, na.rm = TRUE)
    limit_sup <- max(data$x, na.rm = TRUE)
    if (!all(limit_inf <= x & x <= limit_sup)) {
      stop("x needs to be in the interval <", limit_inf, ", ", limit_sup, ">")
    }
    predictions <- do.call(
      what = rbind,
      args = suppressWarnings(
        lapply(
          X = fit_list,
          FUN = .delta_method_deriv,
          x_new = x,
          curve = object$fun,
          which = type
        )
      )
    ) |>
      as_tibble()
  }
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

# Delta method point estimation
.delta_method <- function(fit, x_new, curve, se_interval = "confidence") {
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
    if (se_interval == "prediction") {
      std_errors <- sqrt(varerr + std_errors^2)
    }
  } else {
    std_errors <- NA
  }
  # Predictions
  predicted_values <- ff(
    params = estimated_params,
    x_new = x_new,
    curve = curve,
    fixed_params = fix_params
  )
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

# Function for point estimation
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

# Delta method AUC estimation
.delta_method_auc <- function(fit, x_new, curve, n_points = 1000) {
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
    func = ff_auc,
    x = estimated_params,
    x_new = x_new,
    curve = curve,
    fixed_params = fix_params,
    n_points = n_points
  )
  if (!inherits(vcov_mat, "try-error")) {
    std_errors <- sqrt(diag(jac_matrix %*% vcov_mat %*% t(jac_matrix)))
  } else {
    std_errors <- NA
  }
  # Predictions
  predicted_values <- ff_auc(
    params = estimated_params,
    x_new = x_new,
    curve = curve,
    fixed_params = fix_params,
    n_points = n_points
  )
  # Combine results
  results <- data.frame(
    uid = uid,
    x_min = x_new[1],
    x_max = x_new[2],
    predicted.value = predicted_values,
    std.error = std_errors
  )
  results <- full_join(
    x = select(fit$param, uid),
    y = results,
    by = "uid"
  )
}

# Function for AUC estimation
ff_auc <- function(params, x_new, curve, fixed_params = NA, n_points = 1000) {
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
  x <- seq(x_new[1], x_new[2], length.out = n_points)
  string <- paste("sapply(x, FUN = ", curve, ", ", values, ")", sep = "")
  y_hat <- eval(parse(text = string))
  trapezoid_area <- (lead(y_hat) + y_hat) / 2 * (lead(x) - x)
  auc <- sum(trapezoid_area, na.rm = TRUE)
  return(auc)
}

# Delta method for derivative estimation
.delta_method_deriv <- function(fit, x_new, curve, which = "fd") {
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
    func = ff_deriv,
    x = estimated_params,
    x_new = x_new,
    curve = curve,
    fixed_params = fix_params,
    which = which
  )
  if (!inherits(vcov_mat, "try-error")) {
    std_errors <- sqrt(diag(jac_matrix %*% vcov_mat %*% t(jac_matrix)))
  } else {
    std_errors <- NA
  }
  # Predictions
  predicted_values <- ff_deriv(
    params = estimated_params,
    x_new = x_new,
    curve = curve,
    fixed_params = fix_params,
    which = which
  )
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

# Function for derivatives
ff_deriv <- function(params, x_new, curve, fixed_params = NA, which = "fd") {
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
  } else {
    values <- paste(
      paste(names(params), params, sep = " = "),
      collapse = ", "
    )
  }
  string <- paste0(
    "lapply(x_new, FUN = numDeriv::genD, func = ",
    curve, ", ",
    values,
    ", method = 'Richardson', ",
    "method.args = list()",
    ")"
  )
  res <- eval(parse(text = string))
  res <- do.call(what = rbind, args = lapply(res, \(x) x$D))
  if (which == "fd") {
    return(res[, 1])
  } else if (which == "sd") {
    return(res[, 2])
  }
}
