#' Predict an object of class \code{modeler_HTP}
#'
#' @description Model predictions for an object of class \code{modeler_HTP}
#' @aliases predict.modeler_HTP
#' @param x An object inheriting from class \code{modeler_HTP} resulting of
#' executing the function \code{modeler_HTP()}
#' @param time A numeric time point to make the prediction. Can be more than one.
#' @param plot_id A numeric to filter by Plot Id.
#' @param ... Further parameters. For future improvements.
#' @author Johan Aparicio [aut]
#' @method predict modeler_HTP
#' @return A data.frame object with predicted values.
#' @export
#' @examples
#' library(exploreHTP)
#' data(dt_potato)
#' results <- read_HTP(
#'   data = dt_potato,
#'   genotype = "Gen",
#'   time = "DAP",
#'   plot = "Plot",
#'   traits = c("Canopy", "GLI_2"),
#'   row = "Row",
#'   range = "Range"
#' )
#' mod <- modeler_HTP(
#'   x = results,
#'   index = "Canopy",
#'   plot_id = 1:2,
#'   parameters = c(t1 = 45, t2 = 80, k = 0.9),
#'   fn = "fn_piwise",
#'   parallel = TRUE
#' )
#' mod
#' predict(mod, time = 45, plot_id = 2)
#' @import ggplot2
#' @import dplyr
predict.modeler_HTP <- function(x,
                                time = NULL,
                                plot_id = NULL, ...) {
  # Check the class of x
  if (!inherits(x, "modeler_HTP")) {
    stop("The object should be of class 'modeler_HTP'.")
  }
  if (is.null(time)) {
    stop("Argument time is required for predictions.")
  }
  data <- x$dt
  param <- x$param
  dt <- full_join(data, y = param, by = c("plot", "row", "range", "genotype"))
  if (!all(param$plot %in% dt$plot)) {
    stop("All plots are required to calculate standard errors.")
  }
  if (!is.null(plot_id)) {
    if (!all(plot_id %in% unique(dt$plot))) {
      stop("plot_ids not found in x.")
    }
  } else {
    plot_id <- unique(dt$plot)
  }
  fn <- x$fn
  limit_inf <- min(data$time, na.rm = TRUE)
  limit_sup <- x$max_time
  if (!all(limit_inf <= time & time <= limit_sup)) {
    stop("time needs to be in the interval <", limit_inf, ", ", limit_sup, ">")
  }
  fit_list <- x$fit
  .delta_method <- function(fit, time, curve) {
    tt <- fit$hessian
    vcov_mat <- solve(tt)
    best <- fit$details$method
    estimated_params <- coef(fit$kkopt)[best, ]
    plot <- fit$plot_id
    fix_params <- fit$type |>
      filter(type == "fixed") |>
      pull(value, name = parameter)
    if (length(fix_params) == 0) fix_params <- NA
    jac_matrix <- numDeriv::jacobian(
      func = ff,
      x = estimated_params,
      time = time,
      curve = curve,
      fixed_params = fix_params
    )
    pred_std_errors <- sqrt(diag(jac_matrix %*% vcov_mat %*% t(jac_matrix)))
    # Confidence intervals for predictions
    z_value <- qnorm(0.975)
    predicted_values <- ff(
      params = estimated_params,
      time = time,
      curve = curve,
      fixed_params = fix_params
    )
    ci_lower <- predicted_values - z_value * pred_std_errors
    ci_upper <- predicted_values + z_value * pred_std_errors
    # Combine results
    results <- data.frame(
      plot = plot,
      time = time,
      predicted.value = predicted_values,
      standard.error = pred_std_errors,
      ci_lower = ci_lower,
      ci_upper = ci_upper
    )
    results <- full_join(
      x = select(fit$param, plot:range),
      y = results,
      by = "plot"
    )
  }
  predictions <- do.call(
    what = rbind,
    args = lapply(fit_list, FUN = .delta_method, time = time, curve = x$fun)
  ) |>
    filter(plot %in% plot_id) |>
    as_tibble()
  return(predictions)
}


ff <- function(params, time, curve, fixed_params = NA) {
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
  string <- paste("sapply(time, FUN = ", curve, ", ", values, ")", sep = "")
  y_hat <- eval(parse(text = string))
  return(y_hat)
}
