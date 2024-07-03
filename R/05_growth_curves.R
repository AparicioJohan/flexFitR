#' Exponential Linear Function 1
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
#' library(exploreHTP)
#' t <- seq(0, 108, 0.1)
#' y_hat <- sapply(
#'   X = t,
#'   FUN = fn_exp1_lin,
#'   t1 = 35,
#'   t2 = 55,
#'   alpha = 1 / 20,
#'   beta = -1 / 40
#' )
#' plot(t, y_hat, type = "l")
#' lines(t, y_hat, col = "red")
#' abline(v = c(35, 55), lty = 2)
fn_exp1_lin <- function(t, t1, t2, alpha, beta) {
  # beta < 0
  # alpha > 0
  if (t < t1) {
    return(0)
  }
  if (t >= t1 & t <= t2) {
    return(exp(alpha * (t - t1)) - 1)
  }
  if (t > t2) {
    y2 <- exp(alpha * (t2 - t1)) - 1
    return(beta * (t - t2) + y2)
  }
}

#' Exponential Linear Function 2
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
#' library(exploreHTP)
#' t <- seq(0, 108, 0.1)
#' y_hat <- sapply(
#'   X = t,
#'   FUN = fn_exp2_lin,
#'   t1 = 35,
#'   t2 = 55,
#'   alpha = 1 / 600,
#'   beta = -1 / 80
#' )
#' plot(t, y_hat, type = "l")
#' lines(t, y_hat, col = "red")
#' abline(v = c(35, 55), lty = 2)
fn_exp2_lin <- function(t, t1, t2, alpha, beta) {
  # beta < 0
  # alpha > 0
  if (t < t1) {
    return(0)
  }
  if (t >= t1 & t <= t2) {
    return(exp(alpha * (t - t1)^2) - 1)
  }
  if (t > t2) {
    y2 <- exp(alpha * (t2 - t1)^2) - 1
    return(beta * (t - t2) + y2)
  }
}

#' Exponential Exponential Function 1
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
#' library(exploreHTP)
#' t <- seq(0, 108, 0.1)
#' y_hat <- sapply(
#'   X = t,
#'   FUN = fn_exp1_exp,
#'   t1 = 35,
#'   t2 = 55,
#'   alpha = 1 / 20,
#'   beta = -1 / 30
#' )
#' plot(t, y_hat, type = "l")
#' lines(t, y_hat, col = "red")
#' abline(v = c(35, 55), lty = 2)
fn_exp1_exp <- function(t, t1, t2, alpha, beta) {
  # beta < 0
  # alpha > 0
  if (t < t1) {
    return(0)
  }
  if (t >= t1 & t <= t2) {
    return(exp(alpha * (t - t1)) - 1)
  }
  if (t > t2) {
    y2 <- exp(alpha * (t2 - t1)) - 1
    return(y2 * exp(beta * (t - t2)))
  }
}

#' Exponential Exponential Function 2
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
#' library(exploreHTP)
#' t <- seq(0, 108, 0.1)
#' y_hat <- sapply(
#'   X = t,
#'   FUN = fn_exp2_exp,
#'   t1 = 35,
#'   t2 = 55,
#'   alpha = 1 / 600,
#'   beta = -1 / 30
#' )
#' plot(t, y_hat, type = "l")
#' lines(t, y_hat, col = "red")
#' abline(v = c(35, 55), lty = 2)
fn_exp2_exp <- function(t, t1, t2, alpha, beta) {
  # beta < 0
  # alpha > 0
  if (t < t1) {
    return(0)
  }
  if (t >= t1 & t <= t2) {
    return(exp(alpha * (t - t1)^2) - 1)
  }
  if (t > t2) {
    y2 <- exp(alpha * (t2 - t1)^2) - 1
    return(y2 * exp(beta * (t - t2)))
  }
}

#' Piecewise Linear Regression
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
#' library(exploreHTP)
#' t <- seq(0, 108, 0.1)
#' y_hat <- sapply(t, FUN = fn_piwise, t1 = 34.9, t2 = 61.8, k = 100)
#' plot(t, y_hat, type = "l")
#' lines(t, y_hat, col = "red")
#' abline(v = c(34.9, 61.8), lty = 2)
fn_piwise <- function(t, t1 = 45, t2 = 80, k = 0.9) {
  if (is.na(t)) {
    stop("Missing values not allowed for t.")
  }
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
#' predicted by the \link{fn_piwise} function. This is the objective function to
#' be minimized in the optimx package.
#'
#' @param params Numeric vector. The parameters for the \code{fn_piwise} function,
#' where \code{params[1]} is \code{t1} and \code{params[2]} is \code{t2}.
#' @param t Numeric vector. The time values.
#' @param y Numeric vector. The observed values.
#'
#' @return A numeric value representing the sum of squared errors.
#' @noRd
#'
#' @examples
#' library(exploreHTP)
#' x <- c(0, 29, 36, 42, 56, 76, 92, 100, 108)
#' y <- c(0, 0, 4.379, 26.138, 78.593, 100, 100, 100, 100)
#' sse_piwise(params = c(34.9, 61.8), t = x, y = y)
#'
#' y_hat <- sapply(x, FUN = fn_piwise, t1 = 34.9, t2 = 61.8, k = 100)
#' sum((y - y_hat)^2)
sse_piwise <- function(params, t, y) {
  t1 <- params[1]
  t2 <- params[2]
  k <- max(y)
  y_hat <- sapply(t, FUN = fn_piwise, t1 = t1, t2 = t2, k = k)
  sse <- sum((y - y_hat)^2)
  return(sse)
}


#' Linear Plateau Linear
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
#' library(exploreHTP)
#' t <- seq(0, 108, 0.1)
#' y_hat <- sapply(
#'   X = t,
#'   FUN = fn_lin_pl_lin,
#'   t1 = 38.7, t2 = 62, t3 = 90, k = 0.32, beta = -0.01
#' )
#' plot(t, y_hat, type = "l")
#' lines(t, y_hat, col = "red")
#' abline(v = c(38.7, 62), lty = 2)
fn_lin_pl_lin <- function(t, t1, t2, t3, k, beta) {
  if (t < t1) {
    return(0)
  }
  if (t >= t1 & t <= t2) {
    y <- k / (t2 - t1) * (t - t1)
  }
  if (t >= t2 & t <= t3) {
    y <- k
  }
  if (t >= t3) {
    y <- k + beta * (t - t3)
  }
  return(y)
}

#' Linear Plateau Linear with Constrains
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
#' library(exploreHTP)
#' t <- seq(0, 108, 0.1)
#' y_hat <- sapply(
#'   X = t,
#'   FUN = fn_lin_pl_lin2,
#'   t1 = 38.7, t2 = 62, dt = 28, k = 0.32, beta = -0.01
#' )
#' plot(t, y_hat, type = "l")
#' lines(t, y_hat, col = "red")
#' abline(v = c(38.7, 62), lty = 2)
fn_lin_pl_lin2 <- function(t, t1, t2, dt, k, beta) {
  if (t < t1) {
    return(0)
  }
  if (t >= t1 & t <= t2) {
    y <- k / (t2 - t1) * (t - t1)
  }
  if (t >= t2 & t <= (t2 + dt)) {
    y <- k
  }
  if (t >= (t2 + dt)) {
    y <- k + beta * (t - (t2 + dt))
  }
  return(y)
}

#' Linear Plateau Linear with Constrains
#'
#' @param t Numeric. The time value.
#' @param t1 Numeric. The lower threshold time. Default is 45.
#' @param dt Numeric. dt = t3 - t2. Default is 28
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
#' f(t; t_1, dt, t_3, k, \beta) =
#' \begin{cases}
#' 0 & \text{if } t < t_1 \\
#' \dfrac{k}{(t_3 - dt) - t_1} \cdot (t - t_1) & \text{if } t_1 \leq t \leq (t_3 - dt) \\
#' k & \text{if } (t_3 - dt) \leq t \leq t_3 \\
#' k + \beta \cdot (t - t_3) & \text{if } t > t_3
#' \end{cases}
#' }
#' }
#'
#' @examples
#' library(exploreHTP)
#' t <- seq(0, 108, 0.1)
#' y_hat <- sapply(
#'   X = t,
#'   FUN = fn_lin_pl_lin3,
#'   t1 = 38.7, dt = 28, t3 = 90, k = 0.32, beta = -0.01
#' )
#' plot(t, y_hat, type = "l")
#' lines(t, y_hat, col = "red")
#' abline(v = c(38.7, 62), lty = 2)
fn_lin_pl_lin3 <- function(t, t1, dt, t3, k, beta) {
  if (t < t1) {
    return(0)
  }
  if (t >= t1 & t <= t3 - dt) {
    y <- k / ((t3 - dt) - t1) * (t - t1)
  }
  if (t >= (t3 - dt) & t <= t3) {
    y <- k
  }
  if (t >= t3) {
    y <- k + beta * (t - t3)
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
#' library(exploreHTP)
#' t <- seq(0, 108, 0.1)
#' y_hat <- sapply(
#'   X = t,
#'   FUN = fn_lin_pl_lin,
#'   t1 = 38.7, t2 = 62, t3 = 90, k = 0.32, beta = -0.01
#' )
#' plot(t, y_hat, type = "l")
#' lines(t, y_hat, col = "red")
#' abline(v = c(38.7, 62), lty = 2)
fn_lin_pl_lin4 <- function(t, t1, t2, t3, k, beta) {
  if (t < t1) {
    y <- 0
  }
  if (t >= t1 & t <= t2) {
    y <- k / (t2 - t1) * (t - t1)
  }
  if (t >= t2 & t <= t3) {
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
#' fn <- "fn_piwise"
#' sse_generic(params, t, y, fn, fixed = fixed)
#' res <- opm(
#'   par = params,
#'   fn = sse_generic,
#'   t = t,
#'   y = y,
#'   curve = fn,
#'   fixed = fixed,
#'   method = c("subplex"),
#'   lower = -Inf,
#'   upper = Inf
#' ) |>
#'   cbind(t(fixed))
#' @noRd
sse_generic <- function(params, t, y, curve, fixed_params = NA) {
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
  sse <- sum((y - y_hat)^2)
  return(sse)
}

#' @noRd
create_call <- function(fn = "fn_piwise") {
  arg <- formals(fn)
  values <- paste(names(arg)[-1], collapse = ", ")
  string <- paste(fn, "(time, ", values, ")", sep = "")
  out <- rlang::parse_expr(string)
  return(out)
}
