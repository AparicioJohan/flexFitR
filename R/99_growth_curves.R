#' Linear function
#'
#' Computes a value based on a linear function.
#'
#' @param t Numeric value.
#' @param m Numeric value for the slope coefficient.
#' @param b Numeric value for the intercept coefficient.
#'
#' @return A numeric value based on the linear function.
#' @export
#'
#' @details
#' \if{html}{
#' \deqn{
#' f(t; m, b) = m \cdot t + b
#' }
#' }
#'
#' @examples
#' library(flexFitR)
#' plot_fn(
#'   fn = "fn_lin",
#'   params = c(m = 2, b = 10),
#'   interval = c(0, 108),
#'   n_points = 2000
#' )
fn_lin <- function(t, m, b) {
  y <- m * t + b
  return(y)
}

#' Quadratic function
#'
#' Computes a value based on a quadratic function..
#'
#' @param t Numeric value.
#' @param a Numeric value for coefficient a.
#' @param b Numeric value for coefficient b.
#' @param c Numeric value for coefficient c.
#'
#' @return A numeric value based on the linear function.
#' @export
#'
#' @details
#' \if{html}{
#' \deqn{
#' f(t; a, b, c) = a \cdot t^2 + b \cdot t + c
#' }
#' }
#'
#' @examples
#' library(flexFitR)
#' plot_fn(fn = "fn_quad", params = c(a = 1, b = 10, c = 5))
fn_quad <- function(t, a, b, c) {
  y <- a * t^2 + b * t + c
  return(y)
}

#' Logistic function
#'
#' Computes a value based on a logistic function.
#'
#' @param t Numeric value.
#' @param L Numeric value.
#' @param k Numeric value.
#' @param t0 Numeric value.
#'
#' @return A numeric value based on the logistic function.
#' @export
#'
#' @details
#' \if{html}{
#' \deqn{
#' f(t; L, k, t0) = \frac{L}{1 + e^{-k(t - t_0)}}
#' }
#' }
#'
#' @examples
#' library(flexFitR)
#' plot_fn(
#'   fn = "fn_logistic",
#'   params = c(L = 100, k = 0.199, t0 = 47.7),
#'   interval = c(0, 108),
#'   n_points = 2000
#' )
fn_logistic <- function(t, L, k, t0) {
  y <- L / (1 + exp(-k * (t - t0)))
  return(y)
}

#' Exponential linear function 1
#'
#' Computes a value based on an exponential growth curve and linear decay model for time.
#'
#' @param t Numeric. The time value.
#' @param t1 Numeric. The lower threshold time. Assumed to be known.
#' @param t2 Numeric. The upper threshold time.
#' @param alpha Numeric. The parameter for the exponential term. Must be greater
#' than 0.
#' @param beta Numeric. The parameter for the linear term. Must be less than 0.
#'
#' @return A numeric value based on the exponential linear model.
#' If \code{t} is less than \code{t1}, the function returns 0.
#' If \code{t} is between \code{t1} and \code{t2} (inclusive),
#' the function returns \code{exp(alpha * (t - t1)) - 1}.
#' If \code{t} is greater than \code{t2}, the function returns
#' \code{beta * (t - t2) + (exp(alpha * (t2 - t1)) - 1)}.
#' @export
#'
#' @details
#' \if{html}{
#' \deqn{
#' f(t; t_1, t_2, \alpha, \beta) =
#' \begin{cases}
#' 0 & \text{if } t < t_1 \\
#' e^{\alpha \cdot (t - t_1)} - 1 & \text{if } t_1 \leq t \leq t_2 \\
#' \beta \cdot (t - t_2) + \left(e^{\alpha \cdot (t_2 - t_1)} - 1\right) & \text{if } t > t_2
#' \end{cases}
#' }
#' }
#'
#' @examples
#' library(flexFitR)
#' plot_fn(
#'   fn = "fn_exp1_lin",
#'   params = c(t1 = 35, t2 = 55, alpha = 1 / 20, beta = -1 / 40),
#'   interval = c(0, 108),
#'   n_points = 2000,
#'   auc_label_size = 3
#' )
fn_exp1_lin <- function(t, t1, t2, alpha, beta) {
  if (t < t1) {
    return(0)
  }
  if (t >= t1 && t <= t2) {
    return(exp(alpha * (t - t1)) - 1)
  }
  if (t > t2) {
    y2 <- exp(alpha * (t2 - t1)) - 1
    return(beta * (t - t2) + y2)
  }
}

#' Exponential linear function 2
#'
#' Computes a value based on an exponential growth curve and linear decay model for time.
#'
#' @param t Numeric. The time value.
#' @param t1 Numeric. The lower threshold time. Assumed to be known.
#' @param t2 Numeric. The upper threshold time.
#' @param alpha Numeric. The parameter for the exponential term. Must be greater
#' than 0.
#' @param beta Numeric. The parameter for the linear term. Must be less than 0.
#'
#' @return A numeric value based on the exponential linear model.
#' If \code{t} is less than \code{t1}, the function returns 0.
#' If \code{t} is between \code{t1} and \code{t2} (inclusive),
#' the function returns \code{exp(alpha * (t - t1)^2) - 1}.
#' If \code{t} is greater than \code{t2}, the function returns
#' \code{beta * (t - t2) + (exp(alpha * (t2 - t1)^2) - 1)}.
#' @export
#'
#' @details
#' \if{html}{
#' \deqn{
#' f(t; t_1, t_2, \alpha, \beta) =
#' \begin{cases}
#' 0 & \text{if } t < t_1 \\
#' e^{\alpha \cdot (t - t_1)^2} - 1 & \text{if } t_1 \leq t \leq t_2 \\
#' \beta \cdot (t - t_2) + \left(e^{\alpha \cdot (t_2 - t_1)^2} - 1\right) & \text{if } t > t_2
#' \end{cases}
#' }
#' }
#'
#' @examples
#' library(flexFitR)
#' plot_fn(
#'   fn = "fn_exp2_lin",
#'   params = c(t1 = 35, t2 = 55, alpha = 1 / 600, beta = -1 / 80),
#'   interval = c(0, 108),
#'   n_points = 2000,
#'   auc_label_size = 3
#' )
fn_exp2_lin <- function(t, t1, t2, alpha, beta) {
  if (t < t1) {
    return(0)
  }
  if (t >= t1 && t <= t2) {
    return(exp(alpha * (t - t1)^2) - 1)
  }
  if (t > t2) {
    y2 <- exp(alpha * (t2 - t1)^2) - 1
    return(beta * (t - t2) + y2)
  }
}

#' Exponential exponential function 1
#'
#' Computes a value based on an exponential growth curve and exponential decay model for time.
#'
#' @param t Numeric. The time value.
#' @param t1 Numeric. The lower threshold time. Assumed to be known.
#' @param t2 Numeric. The upper threshold time.
#' @param alpha Numeric. The parameter for the first exponential term.
#' Must be greater than 0.
#' @param beta Numeric. The parameter for the second exponential term.
#' Must be less than 0.
#'
#' @return A numeric value based on the double exponential model.
#' If \code{t} is less than \code{t1}, the function returns 0.
#' If \code{t} is between \code{t1} and \code{t2} (inclusive),
#' the function returns \code{exp(alpha * (t - t1)) - 1}.
#' If \code{t} is greater than \code{t2}, the function returns
#' \code{(exp(alpha * (t2 - t1)) - 1) * exp(beta * (t - t2))}.
#' @export
#'
#' @details
#' \if{html}{
#' \deqn{
#' f(t; t_1, t_2, \alpha, \beta) =
#' \begin{cases}
#' 0 & \text{if } t < t_1 \\
#' e^{\alpha \cdot (t - t_1)} - 1 & \text{if } t_1 \leq t \leq t_2 \\
#' \left(e^{\alpha \cdot (t_2 - t_1)} - 1\right) \cdot e^{\beta \cdot (t - t_2)} & \text{if } t > t_2
#' \end{cases}
#' }
#' }
#'
#' @examples
#' library(flexFitR)
#' plot_fn(
#'   fn = "fn_exp1_exp",
#'   params = c(t1 = 35, t2 = 55, alpha = 1 / 20, beta = -1 / 30),
#'   interval = c(0, 108),
#'   n_points = 2000,
#'   auc_label_size = 3,
#'   y_auc_label = 0.2
#' )
fn_exp1_exp <- function(t, t1, t2, alpha, beta) {
  if (t < t1) {
    return(0)
  }
  if (t >= t1 && t <= t2) {
    return(exp(alpha * (t - t1)) - 1)
  }
  if (t > t2) {
    y2 <- exp(alpha * (t2 - t1)) - 1
    return(y2 * exp(beta * (t - t2)))
  }
}

#' Exponential exponential Function 2
#'
#' Computes a value based on an exponential growth curve and exponential decay model for time.
#'
#' @param t Numeric. The time value.
#' @param t1 Numeric. The lower threshold time. Assumed to be known.
#' @param t2 Numeric. The upper threshold time.
#' @param alpha Numeric. The parameter for the first exponential term.
#' Must be greater than 0.
#' @param beta Numeric. The parameter for the second exponential term.
#' Must be less than 0.
#'
#' @return A numeric value based on the double exponential model.
#' If \code{t} is less than \code{t1}, the function returns 0.
#' If \code{t} is between \code{t1} and \code{t2} (inclusive),
#' the function returns \code{exp(alpha * (t - t1)^2) - 1}.
#' If \code{t} is greater than \code{t2}, the function returns
#' \code{(exp(alpha * (t2 - t1)^2) - 1) * exp(beta * (t - t2))}.
#' @export
#'
#' @details
#' \if{html}{
#' \deqn{
#' f(t; t_1, t_2, \alpha, \beta) =
#' \begin{cases}
#' 0 & \text{if } t < t_1 \\
#' e^{\alpha \cdot (t - t_1)^2} - 1 & \text{if } t_1 \leq t \leq t_2 \\
#' \left(e^{\alpha \cdot (t_2 - t_1)^2} - 1\right) \cdot e^{\beta \cdot (t - t_2)} & \text{if } t > t_2
#' \end{cases}
#' }
#' }
#'
#' @examples
#' library(flexFitR)
#' plot_fn(
#'   fn = "fn_exp2_exp",
#'   params = c(t1 = 35, t2 = 55, alpha = 1 / 600, beta = -1 / 30),
#'   interval = c(0, 108),
#'   n_points = 2000,
#'   auc_label_size = 3,
#'   y_auc_label = 0.15
#' )
fn_exp2_exp <- function(t, t1, t2, alpha, beta) {
  if (t < t1) {
    return(0)
  }
  if (t >= t1 && t <= t2) {
    return(exp(alpha * (t - t1)^2) - 1)
  }
  if (t > t2) {
    y2 <- exp(alpha * (t2 - t1)^2) - 1
    return(y2 * exp(beta * (t - t2)))
  }
}

#' Linear plateau function
#'
#' Computes a value based on a linear growth curve reaching a plateau for time.
#'
#' @param t Numeric. The time value.
#' @param t1 Numeric. The lower threshold time. Default is 45.
#' @param t2 Numeric. The upper threshold time. Default is 80.
#' @param k Numeric. The maximum value of the function. Default is 0.9. Assumed to be known.
#' @return A numeric value based on the threshold model.
#' If \code{t} is less than \code{t1}, the function returns 0.
#' If \code{t} is between \code{t1} and \code{t2} (inclusive),
#' the function returns a value between 0 and \code{k} in a linear trend.
#' If \code{t} is greater than \code{t2}, the function returns \code{k}.
#' @export
#'
#' @details
#' \if{html}{
#' \deqn{
#' f(t; t_1, t_2, k) =
#' \begin{cases}
#' 0 & \text{if } t < t_1 \\
#' \dfrac{k}{t_2 - t_1} \cdot (t - t_1) & \text{if } t_1 \leq t \leq t_2 \\
#' k & \text{if } t > t_2
#' \end{cases}
#' }
#' }
#'
#' @examples
#' library(flexFitR)
#' plot_fn(
#'   fn = "fn_linear_sat",
#'   params = c(t1 = 34.9, t2 = 61.8, k = 100),
#'   interval = c(0, 108),
#'   n_points = 2000,
#'   auc_label_size = 3
#' )
fn_linear_sat <- function(t, t1 = 45, t2 = 80, k = 0.9) {
  if (t < t1) {
    y <- 0
  } else if (t >= t1 && t <= t2) {
    y <- k / (t2 - t1) * (t - t1)
  } else {
    y <- k
  }
  return(y)
}

#' Sum of Squares Error Function for Piecewise Model
#'
#' Calculates the sum of squared errors (SSE) between observed values and values
#' predicted by the \link{fn_linear_sat} function. This is the objective function to
#' be minimized in the optimx package.
#'
#' @param params Numeric vector. The parameters for the \code{fn_linear_sat} function,
#' where \code{params[1]} is \code{t1} and \code{params[2]} is \code{t2}.
#' @param t Numeric vector. The time values.
#' @param y Numeric vector. The observed values.
#'
#' @return A numeric value representing the sum of squared errors.
#' @noRd
#'
#' @examples
#' library(flexFitR)
#' x <- c(0, 29, 36, 42, 56, 76, 92, 100, 108)
#' y <- c(0, 0, 4.379, 26.138, 78.593, 100, 100, 100, 100)
#' sse_piwise(params = c(34.9, 61.8), t = x, y = y)
#'
#' y_hat <- sapply(x, FUN = fn_linear_sat, t1 = 34.9, t2 = 61.8, k = 100)
#' sum((y - y_hat)^2)
sse_piwise <- function(params, t, y) {
  t1 <- params[1]
  t2 <- params[2]
  k <- max(y)
  y_hat <- sapply(t, FUN = fn_linear_sat, t1 = t1, t2 = t2, k = k)
  sse <- sum((y - y_hat)^2)
  return(sse)
}


#' Linear plateau linear function
#'
#' @param t Numeric. The time value.
#' @param t1 Numeric. The lower threshold time. Default is 45.
#' @param t2 Numeric. The upper threshold time before plateau. Default is 80.
#' @param t3 Numeric. The lower threshold time after plateau. Default is 45.
#' @param k Numeric. The maximum value of the function. Default is 0.9.
#' @param beta Numeric. Slope of the linear decay.
#'
#' @return A numeric value based on the linear plateau linear model.
#' @export
#'
#' @details
#' \if{html}{
#' \deqn{
#' f(t; t_1, t_2, t_3, k, \beta) =
#' \begin{cases}
#' 0 & \text{if } t < t_1 \\
#' \dfrac{k}{t_2 - t_1} \cdot (t - t_1) & \text{if } t_1 \leq t \leq t_2 \\
#' k & \text{if } t_2 \leq t \leq t_3 \\
#' k + \beta \cdot (t - t_3) & \text{if } t > t_3
#' \end{cases}
#' }
#' }
#'
#' @examples
#' library(flexFitR)
#' plot_fn(
#'   fn = "fn_lin_pl_lin",
#'   params = c(t1 = 38.7, t2 = 62, t3 = 90, k = 0.32, beta = -0.01),
#'   interval = c(0, 108),
#'   n_points = 2000,
#'   auc_label_size = 3
#' )
fn_lin_pl_lin <- function(t, t1, t2, t3, k, beta) {
  if (t < t1) {
    return(0)
  }
  if (t >= t1 && t <= t2) {
    y <- k / (t2 - t1) * (t - t1)
  }
  if (t >= t2 && t <= t3) {
    y <- k
  }
  if (t >= t3) {
    y <- k + beta * (t - t3)
  }
  return(y)
}

#' Linear plateau linear with constrains
#'
#' @param t Numeric. The time value.
#' @param t1 Numeric. The lower threshold time.
#' @param t2 Numeric. The upper threshold time before plateau.
#' @param dt Numeric. dt = t3 - t2.
#' @param k Numeric. The maximum value of the function.
#' @param beta Numeric. Slope of the linear decay.
#'
#' @return A numeric value based on the linear plateau linear model.
#' @export
#'
#' @details
#' \if{html}{
#' \deqn{
#' f(t; t_1, t_2, dt, k, \beta) =
#' \begin{cases}
#' 0 & \text{if } t < t_1 \\
#' \dfrac{k}{t_2 - t_1} \cdot (t - t_1) & \text{if } t_1 \leq t \leq t_2 \\
#' k & \text{if } t_2 \leq t \leq (t_2 + dt) \\
#' k + \beta \cdot (t - (t_2 + dt)) & \text{if } t > (t_2 + dt)
#' \end{cases}
#' }
#' }
#'
#' @examples
#' library(flexFitR)
#' plot_fn(
#'   fn = "fn_lin_pl_lin2",
#'   params = c(t1 = 38.7, t2 = 62, dt = 28, k = 0.32, beta = -0.01),
#'   interval = c(0, 108),
#'   n_points = 2000,
#'   auc_label_size = 3
#' )
fn_lin_pl_lin2 <- function(t, t1, t2, dt, k, beta) {
  if (t < t1) {
    return(0)
  }
  if (t >= t1 && t <= t2) {
    y <- k / (t2 - t1) * (t - t1)
  }
  if (t >= t2 && t <= (t2 + dt)) {
    y <- k
  }
  if (t >= (t2 + dt)) {
    y <- k + beta * (t - (t2 + dt))
  }
  return(y)
}

#' Linear Plateau Linear Constrains
#'
#' @param t Numeric. The time value.
#' @param t1 Numeric. The lower threshold time. Default is 45.
#' @param t2 Numeric. The upper threshold time before plateau. Default is 80.
#' @param t3 Numeric. The lower threshold time after plateau. Default is 45.
#' @param k Numeric. The maximum value of the function. Default is 0.9.
#' @param beta Numeric. Slope of the linear decay.
#'
#' @return A numeric value based on the linear plateau linear model.
#' @noRd
#'
#' @details
#' \if{html}{
#' \deqn{
#' f(t; t_1, t_2, t_3, k, \beta) =
#' \begin{cases}
#' 0 & \text{if } t < t_1 \\
#' \dfrac{k}{t_2 - t_1} \cdot (t - t_1) & \text{if } t_1 \leq t \leq t_2 \\
#' k & \text{if } t_2 \leq t \leq t_3 \\
#' k + \beta \cdot (t - t_3) & \text{if } t > t_3
#' \end{cases}
#' }
#' }
#'
#' @examples
#' library(flexFitR)
#' plot_fn(
#'   fn = "fn_lin_pl_lin3",
#'   params = c(t1 = 38.7, t2 = 62, t3 = 90, k = 0.32, beta = -0.01),
#'   interval = c(0, 108),
#'   n_points = 2000,
#'   auc_label_size = 3
#' )
fn_lin_pl_lin3 <- function(t, t1, t2, t3, k, beta) {
  if (t < t1) {
    y <- 0
  }
  if (t >= t1 && t <= t2) {
    y <- k / (t2 - t1) * (t - t1)
  }
  if (t >= t2 && t <= t3) {
    y <- k
  }
  if (t >= t3) {
    y <- k + beta * (t - t3)
  }
  if (t3 - t2 < 0) {
    y <- 1e+200
  }
  return(y)
}


#' @examples
#' params <- c(t1 = 34.9, t2 = 61.8)
#' fixed <- c(k = 90)
#' t <- c(0, 29, 36, 42, 56, 76, 92, 100, 108)
#' y <- c(0, 0, 4.379, 26.138, 78.593, 100, 100, 100, 100)
#' fn <- "fn_linear_sat"
#' minimizer(params, t, y, fn, fixed_params = fixed, metric = "rmse")
#' res <- opm(
#'   par = params,
#'   fn = minimizer,
#'   t = t,
#'   y = y,
#'   curve = fn,
#'   fixed_params = fixed,
#'   metric = "rmse",
#'   method = c("subplex"),
#'   lower = -Inf,
#'   upper = Inf
#' ) |>
#'   cbind(t(fixed))
#' @noRd
minimizer <- function(params,
                      t,
                      y,
                      curve,
                      fixed_params = NA,
                      metric = "sse",
                      trace = FALSE) {
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
  string <- paste("sapply(t, FUN = ", curve, ", ", values, ")", sep = "")
  y_hat <- eval(parse(text = string))
  sse <- eval(parse(text = paste0(metric, "(y, y_hat)"))) # sum((y - y_hat)^2)
  if (trace) cat(paste0("\t", values, ", sse = ", sse, "\n"))
  return(sse)
}

#' @noRd
create_call <- function(fn = "fn_linear_sat") {
  arg <- formals(fn)
  values <- paste(names(arg)[-1], collapse = ", ")
  string <- paste(fn, "(time, ", values, ")", sep = "")
  out <- rlang::parse_expr(string)
  return(out)
}

#' @noRd
create_call <- function(fn = "fn_linear_sat") {
  arg <- formals(fn)
  values <- paste(names(arg)[-1], collapse = ", ")
  string <- paste(fn, "(x, ", values, ")", sep = "")
  out <- rlang::parse_expr(string)
  return(out)
}

#' @noRd
fn_logis <- function(t, t0, t1, t2) {
  t0 / (1 + exp((t1 - t) / t2))
}

# library(flexFitR)
# t <- seq(0, 108, 0.1)
# y_hat <- sapply(
#   X = t,
#   FUN = fn_logistic2,
#   t1 = 38.7, t2 = 62, L = 0.1, k = 0.9
# )
# plot(t, y_hat, type = "l")
# lines(t, y_hat, col = "red")
# abline(v = c(38.7, 62), lty = 2)
#' @noRd
fn_logistic2 <- function(t, t1, t2, L, k) {
  # L is the maximum plant height
  # k is the growth rate
  if (t < t1) {
    return(0)
  }
  return(L / (1 + exp(-k * (t - (t1 + t2) / 2))))
}

# t <- seq(0, 108, 0.1)
# y_hat <- sapply(
#   X = t,
#   FUN = fn_linexp,
#   t1 = 38.7, t2 = 62, a = 0.1, b = 2, c = 0.1
# )
# plot(t, y_hat, type = "l")
# lines(t, y_hat, col = "red")
# abline(v = c(38.7, 62), lty = 2)
#' @noRd
fn_linexp <- function(t, t1, t2, a, b, c) {
  # a, b, c are model parameters
  if (t < t1) {
    return(0)
  }
  if (t >= t1 && t <= t2) {
    return(a + b * (t - t1))
  }
  if (t > t2) {
    y2 <- a + b * (t2 - t1)
    return(y2 * exp(-c * (t - t2)))
  }
}


#' Print available functions in flexFitR
#'
#' @return A vector with available functions
#' @export
#'
#' @examples
#' library(flexFitR)
#' list_funs()
list_funs <- function() {
  c(
    "fn_lin",
    "fn_quad",
    "fn_logistic",
    "fn_linear_sat",
    "fn_lin_pl_lin",
    "fn_lin_pl_lin2",
    "fn_exp1_exp",
    "fn_exp1_lin",
    "fn_exp2_exp",
    "fn_exp2_lin"
  )
}

#' Print available methods in flexFitR
#'
#' @param bounds If TRUE, returns methods for box (or bounds) constraints. FALSE  by default.
#' @param check_package If TRUE, ensures solvers are installed. FALSE  by default.
#' @return A vector with available methods
#' @export
#'
#' @examples
#' library(flexFitR)
#' list_methods()
list_methods <- function(bounds = FALSE, check_package = FALSE) {
  methods <- c(
    "BFGS",
    "CG",
    "Nelder-Mead",
    "L-BFGS-B",
    "nlm",
    "nlminb",
    "lbfgsb3c",
    "Rcgmin",
    "Rtnmin",
    "Rvmmin",
    "snewton",
    "snewtonm",
    "spg",
    "ucminf",
    "newuoa",
    "bobyqa",
    "uobyqa",
    "nmkb",
    "hjkb",
    "hjn",
    "lbfgs",
    "subplex",
    "ncg",
    "nvm",
    "mla",
    "slsqp",
    "tnewt",
    "anms",
    "pracmanm",
    "nlnm",
    "snewtm"
  )
  packages <- c(
    "stats",
    "stats",
    "stats",
    "stats",
    "stats",
    "stats",
    "lbfgsb3c",
    "optimx",
    "optimx",
    "optimx",
    "optimx",
    "optimx",
    "BB",
    "ucminf",
    "minqa",
    "minqa",
    "minqa",
    "dfoptim",
    "dfoptim",
    "optimx",
    "lbfgs",
    "subplex",
    "optimx",
    "optimx",
    "marqLevAlg",
    "nloptr",
    "nloptr",
    "pracma",
    "pracma",
    "nloptr",
    "optimx"
  )
  names(methods) <- packages
  if (check_package) {
    ensure_packages(packages)
  }
  if (bounds) {
    b_methods <- c(
      "BFGS",
      "CG",
      "Nelder-Mead",
      "nlm",
      "ucminf",
      "newuoa",
      "lbfgs",
      "subplex",
      "mla",
      "anms",
      "pracmanm"
    )
    methods <- methods[!methods %in% b_methods]
  }
  return(methods)
}
