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
#' @param a Numeric value.
#' @param t0 Numeric value.
#' @param k Numeric value.
#'
#' @return A numeric value based on the logistic function.
#' @export
#'
#' @details
#' \if{html}{
#' \deqn{
#' f(t; a, t0, k) = \frac{k}{1 + e^{-a(t - t_0)}}
#' }
#' }
#'
#' @examples
#' library(flexFitR)
#' plot_fn(
#'   fn = "fn_logistic",
#'   params = c(a = 0.199, t0 = 47.7, k = 100),
#'   interval = c(0, 108),
#'   n_points = 2000
#' )
fn_logistic <- function(t, a, t0, k) {
  k / (1 + exp(-a * (t - t0)))
}

#' Exponential-linear function
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
#'   fn = "fn_exp_lin",
#'   params = c(t1 = 35, t2 = 55, alpha = 1 / 20, beta = -1 / 40),
#'   interval = c(0, 108),
#'   n_points = 2000,
#'   auc_label_size = 3
#' )
fn_exp_lin <- function(t, t1, t2, alpha, beta) {
  ifelse(
    test = t < t1,
    yes = 0,
    no = ifelse(
      test = t <= t2,
      yes = exp(alpha * (t - t1)) - 1,
      no = beta * (t - t2) + (exp(alpha * (t2 - t1)) - 1)
    )
  )
}

#' Super-exponential linear function
#'
#' Computes a value based on a super exponential growth curve and linear decay model for time.
#'
#' @param t Numeric. The time value.
#' @param t1 Numeric. The lower threshold time. Assumed to be known.
#' @param t2 Numeric. The upper threshold time.
#' @param alpha Numeric. The parameter for the exponential term. Must be greater
#' than 0.
#' @param beta Numeric. The parameter for the linear term. Must be less than 0.
#'
#' @return A numeric value based on the super exponential linear model.
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
  ifelse(
    test = t < t1,
    yes = 0,
    no = ifelse(
      test = t >= t1 & t <= t2,
      yes = exp(alpha * (t - t1)^2) - 1,
      no = exp(alpha * (t2 - t1)^2) - 1 + beta * (t - t2)
    )
  )
}

#' Double-exponential function
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
#' @return A numeric value based on the double exponential function.
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
#'   fn = "fn_exp_exp",
#'   params = c(t1 = 35, t2 = 55, alpha = 1 / 20, beta = -1 / 30),
#'   interval = c(0, 108),
#'   n_points = 2000,
#'   auc_label_size = 3,
#'   y_auc_label = 0.2
#' )
fn_exp_exp <- function(t, t1, t2, alpha, beta) {
  ifelse(
    test = t < t1,
    yes = 0,
    no = ifelse(
      test = t >= t1 & t <= t2,
      yes = exp(alpha * (t - t1)) - 1,
      no = (exp(alpha * (t2 - t1)) - 1) * exp(beta * (t - t2))
    )
  )
}

#' Super-exponential exponential function
#'
#' Computes a value based on a super exponential growth curve and exponential decay model for time.
#'
#' @param t Numeric. The time value.
#' @param t1 Numeric. The lower threshold time. Assumed to be known.
#' @param t2 Numeric. The upper threshold time.
#' @param alpha Numeric. The parameter for the first exponential term.
#' Must be greater than 0.
#' @param beta Numeric. The parameter for the second exponential term.
#' Must be less than 0.
#'
#' @return A numeric value based on the super double exponential model.
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
  ifelse(
    test = t < t1,
    yes = 0,
    no = ifelse(
      test = t >= t1 & t <= t2,
      yes = exp(alpha * (t - t1)^2) - 1,
      no = (exp(alpha * (t2 - t1)^2) - 1) * exp(beta * (t - t2))
    )
  )
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
#'   fn = "fn_lin_plat",
#'   params = c(t1 = 34.9, t2 = 61.8, k = 100),
#'   interval = c(0, 108),
#'   n_points = 2000,
#'   auc_label_size = 3
#' )
fn_lin_plat <- function(t, t1 = 45, t2 = 80, k = 0.9) {
  ifelse(
    test = t < t1,
    yes = 0,
    no = ifelse(
      test = t >= t1 & t <= t2,
      yes = k / (t2 - t1) * (t - t1),
      no = k
    )
  )
}

#' Linear-logistic function
#'
#' Computes a value based on a linear-logistic growth curve.
#'
#' @param t Numeric. The time value.
#' @param t1 Numeric. The lower threshold time. Default is 45.
#' @param t2 Numeric. The upper threshold time. Default is 80.
#' @param k Numeric. The maximum value of the function. Default is 0.9. Assumed to be known.
#' @return A numeric value based on the linear-logistic growth curve.
#' If \code{t} is less than \code{t1}, the function returns 0.
#' If \code{t} is between \code{t1} and \code{t2} (inclusive),
#' the function returns a value between 0 and \code{k} in a linear trend.
#' If \code{t} is greater than \code{t2}, the function returns a value based on a logistic curve.
#' @export
#'
#' @details
#' \if{html}{
#' \deqn{
#' f(t; t_1, t_2, k) =
#' \begin{cases}
#' 0 & \text{if } t < t_1 \\
#' \dfrac{k}{2(t_2 - t_1)} \cdot (t - t_1) & \text{if } t_1 \leq t \leq t_2 \\
#' \dfrac{k}{1 + e^{-2(t - t_2) / (t_2 - t_1)}} & \text{if } t > t_2
#' \end{cases}
#' }
#' }
#'
#' @examples
#' library(flexFitR)
#' plot_fn(
#'   fn = "fn_lin_logis",
#'   params = c(t1 = 35, t2 = 50, k = 100),
#'   interval = c(0, 108),
#'   n_points = 2000,
#'   auc_label_size = 3
#' )
fn_lin_logis <- function(t, t1, t2, k) {
  ifelse(
    test = t < t1,
    yes = 0,
    no = ifelse(
      test = t > t1 & t < t2,
      yes = k / 2 / (t2 - t1) * (t - t1),
      no = k / (1 + exp(-2 * (t - t2) / (t2 - t1)))
    )
  )
}

#' Quadratic-plateau function
#'
#' Computes a value based on a quadratic-plateau growth curve.
#'
#' @param t Numeric. The time value.
#' @param t1 Numeric. The lower threshold time. Default is 45.
#' @param t2 Numeric. The upper threshold time. Default is 80.
#' @param b Numeric.
#' @param k Numeric. The maximum value of the function. Default is 0.9. Assumed to be known.
#' @return A numeric value based on quadratic-plateau growth curve.
#' If \code{t} is less than \code{t1}, the function returns 0.
#' If \code{t} is between \code{t1} and \code{t2} (inclusive),
#' the function returns a value between 0 and \code{k} in a linear trend.
#' If \code{t} is greater than \code{t2}, the function returns a value based on a logistic curve.
#' @export
#'
#' @details
#' \if{html}{
#' \deqn{
#' f(t; t_1, t_2, b, k) =
#' \begin{cases}
#' 0 & \text{if } t < t_1 \\
#' b (t - t_1) + \frac{k - b (t_2 - t_1)}{(t_2 - t_1)^2} (t - t_1)^2 & \text{if } t_1 \leq t \leq t_2 \\
#' k & \text{if } t > t_2
#' \end{cases}
#' }
#' }
#'
#' @examples
#' library(flexFitR)
#' plot_fn(
#'   fn = "fn_quad_plat",
#'   params = c(t1 = 35, t2 = 80, b = 4, k = 100),
#'   interval = c(0, 108),
#'   n_points = 2000,
#'   auc_label_size = 3
#' )
fn_quad_plat <- function(t, t1 = 45, t2 = 80, b = 1, k = 100) {
  c <- suppressWarnings((k - b * (t2 - t1)) / (t2 - t1)^2)
  ifelse(
    test = t < t1,
    yes = 0,
    no = ifelse(
      test = t >= t1 & t <= t2,
      yes = b * (t - t1) + c * (t - t1)^2,
      no = k
    )
  )
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
  ifelse(
    test = t < t1,
    yes = 0,
    no = ifelse(
      test = t >= t1 & t <= t2,
      yes = k / (t2 - t1) * (t - t1),
      no = ifelse(
        test = t > t2 & t <= t3,
        yes = k,
        no = k + beta * (t - t3)
      )
    )
  )
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
  ifelse(
    test = t < t1,
    yes = 0,
    no = ifelse(
      test = t >= t1 & t <= t2,
      yes = k / (t2 - t1) * (t - t1),
      no = ifelse(
        test = t > t2 & t <= (t2 + dt),
        yes = k,
        no = k + beta * (t - (t2 + dt))
      )
    )
  )
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
#' fn <- "fn_lin_plat"
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
#' @importFrom stats setNames
minimizer <- function(params,
                      t,
                      y,
                      curve,
                      fixed_params,
                      trace = FALSE) {
  # Extract curve parameter names
  args <- names(formals(curve))
  arg_names <- args[-1]
  # Combine fixed and free parameters
  full_params <- setNames(rep(NA, length(arg_names)), arg_names)
  if (!any(is.na(fixed_params))) {
    full_params[names(fixed_params)] <- fixed_params
  }
  free_param_names <- setdiff(arg_names, names(fixed_params))
  full_params[free_param_names] <- params
  # Create argument list
  curve_args <- as.list(full_params)
  # Evaluate curve function
  x_val <- setNames(list(t), args[1])
  y_hat <- do.call(curve, c(x_val, curve_args))
  # Evaluate metric
  score <- sse(y, y_hat)
  # Optional tracing
  if (trace) {
    str <- paste(
      names(full_params),
      signif(unlist(full_params), 4),
      sep = " = ",
      collapse = ", "
    )
    cat(paste0("\t", str, ", sse = ", signif(score, 6), "\n"))
  }
  return(score)
}
# minimizer <- function(params,
#                       t,
#                       y,
#                       curve,
#                       fixed_params = NA,
#                       metric = "sse",
#                       trace = FALSE) {
#   arg <- names(formals(curve))[-1]
#   values <- paste(params, collapse = ", ")
#   if (!any(is.na(fixed_params))) {
#     names(params) <- arg[!arg %in% names(fixed_params)]
#     values <- paste(
#       paste(names(params), params, sep = " = "),
#       collapse = ", "
#     )
#     fix <- paste(
#       paste(names(fixed_params), fixed_params, sep = " = "),
#       collapse = ", "
#     )
#     values <- paste(values, fix, sep = ", ")
#   }
#   string <- paste("sapply(t, FUN = ", curve, ", ", values, ")", sep = "")
#   y_hat <- eval(parse(text = string))
#   sse <- eval(parse(text = paste0(metric, "(y, y_hat)"))) # sum((y - y_hat)^2)
#   if (trace) cat(paste0("\t", values, ", sse = ", sse, "\n"))
#   return(sse)
# }

#' @noRd
create_call <- function(fn = "fn_lin_plat") {
  arg <- formals(fn)
  values <- paste(names(arg)[-1], collapse = ", ")
  string <- paste(fn, "(x, ", values, ")", sep = "")
  out <- rlang::parse_expr(string)
  return(out)
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
    "fn_lin_plat",
    "fn_lin_logis",
    "fn_quad_plat",
    "fn_lin_pl_lin",
    "fn_lin_pl_lin2",
    "fn_exp_exp",
    "fn_exp_lin",
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
    "spg",
    "ucminf",
    "newuoa",
    "bobyqa",
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
    "nlnm"
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
    "BB",
    "ucminf",
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
    "nloptr"
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
