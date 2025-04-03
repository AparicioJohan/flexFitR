#' Linear function
#'
#' A basic linear function of the form \code{f(t) = m * t + b}, where \code{m}
#' is the slope and \code{b} is the intercept.
#'
#' @param t A numeric vector of input values (e.g., time).
#' @param m The slope of the line.
#' @param b The intercept (function value when \code{t = 0}).
#'
#' @return A numeric vector of the same length as \code{t}, giving the linear function values.
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
  m * t + b
}

#' Quadratic function
#'
#' A standard quadratic function of the form \code{f(t) = a * t^2 + b * t + c}, where
#' \code{a} controls curvature, \code{b} is the linear coefficient, and \code{c} is the intercept.
#'
#' @param t A numeric vector of input values (e.g., time).
#' @param a The quadratic coefficient (curvature).
#' @param b The linear coefficient (slope at the origin).
#' @param c The intercept (function value when \code{t = 0}).
#'
#' @return A numeric vector of the same length as \code{t}, representing the
#' quadratic function values.
#'
#' @export
#'
#' @details
#' \if{html}{
#' \deqn{
#' f(t; a, b, c) = a \cdot t^2 + b \cdot t + c
#' }
#' }
#'
#' This function represents a second-degree polynomial. The sign of \code{a}
#' determines whether the parabola opens upward (\code{a > 0}) or downward (\code{a < 0}).
#'
#' @examples
#' library(flexFitR)
#' plot_fn(fn = "fn_quad", params = c(a = 1, b = 10, c = 5))
fn_quad <- function(t, a, b, c) {
  a * t^2 + b * t + c
}

#' Logistic function
#'
#' A standard logistic function commonly used to model sigmoidal growth. The
#' curve rises from near zero to a maximum value \code{k}, with inflection point
#' at \code{t0} and growth rate \code{a}.
#'
#' @param t A numeric vector of input values (e.g., time).
#' @param a The growth rate (steepness of the curve). Higher values lead to a steeper rise.
#' @param t0 The time of the inflection point (midpoint of the transition).
#' @param k The upper asymptote or plateau (maximum value as \code{t → ∞}).
#'
#' @return A numeric vector of the same length as \code{t}, representing the logistic function values.
#' @export
#'
#' @details
#' \if{html}{
#' \deqn{
#' f(t; a, t0, k) = \frac{k}{1 + e^{-a(t - t_0)}}
#' }
#' }
#'
#' This is a classic sigmoid (S-shaped) curve that is symmetric around the
#' inflection point \code{t0}.
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
#' A piecewise function that models a response with an initial exponential
#' growth phase followed by a linear phase. Commonly used to describe processes
#' with rapid early increases that slow into a linear trend, while maintaining
#' continuity.
#'
#' @param t A numeric vector of input values (e.g., time).
#' @param t1 The onset time of the response. The function is 0 for all values less than \code{t1}.
#' @param t2 The transition time between exponential and linear phases. Must be greater than \code{t1}.
#' @param alpha The exponential growth rate during the exponential phase.
#' @param beta The slope of the linear phase after \code{t2}.
#'
#' @return A numeric vector of the same length as \code{t}, representing the function values.
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
#' The exponential segment starts from 0 at \code{t1}, and the linear segment
#' continues smoothly from the end of the exponential part. This ensures value
#' continuity at \code{t2}, but not necessarily smoothness in slope.
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
#' A piecewise function that models an initial exponential growth phase based on
#' a squared time difference, followed by a linear phase.
#'
#' @param t A numeric vector of input values (e.g., time).
#' @param t1 The onset time of the response. The function is 0 for all values less than \code{t1}.
#' @param t2 The transition time between exponential and linear phases. Must be greater than \code{t1}.
#' @param alpha The exponential growth rate controlling the curvature of the exponential phase.
#' @param beta The slope of the linear phase after \code{t2}.
#'
#' @return A numeric vector of the same length as \code{t}, representing the function values.
#'
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
#' The exponential section rises gradually from 0 at \code{t1} and accelerates
#' as time increases. The linear section starts at \code{t2} with a value
#' matching the end of the exponential phase, ensuring continuity but not
#' necessarily matching the derivative.
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
#' A piecewise function with two exponential phases. The first exponential phase
#' occurs between \code{t1} and \code{t2}, and the second phase continues after
#' \code{t2} with a potentially different growth rate. The function ensures
#' continuity at the transition point but not necessarily smoothness (in derivative).
#'
#' @param t A numeric vector of input values (e.g., time).
#' @param t1 The onset time of the response. The function is 0 for all values less than \code{t1}.
#' @param t2 The transition time between the two exponential phases. Must be greater than \code{t1}.
#' @param alpha The exponential growth rate during the first phase (\code{t1} to \code{t2}).
#' @param beta The exponential growth rate after \code{t2}.
#'
#' @return A numeric vector of the same length as \code{t}, representing the function values.
#'
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
#' The function rises from 0 starting at \code{t1} with exponential growth rate
#' \code{alpha}, and transitions to a second exponential phase with rate
#' \code{beta} at \code{t2}. The value at the transition point is preserved,
#' ensuring continuity.
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
#' A piecewise function that models an initial exponential phase with quadratic time dependence,
#' followed by a second exponential phase with a different growth rate.
#'
#' @param t A numeric vector of input values (e.g., time).
#' @param t1 The onset time of the response. The function is 0 for all values less than \code{t1}.
#' @param t2 The transition time between the two exponential phases. Must be greater than \code{t1}.
#' @param alpha The curvature-controlled exponential rate during the first phase (\code{t1} to \code{t2}).
#' @param beta The exponential growth rate after \code{t2}.
#'
#' @return A numeric vector of the same length as \code{t}, representing the function values.
#'
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
#' A simple piecewise function that models a linear increase from zero to a plateau.
#' The function rises linearly between two time points and then levels off at a constant value.
#'
#' @param t A numeric vector of input values (e.g., time).
#' @param t1 The onset time of the response. The function is 0 for all values less than \code{t1}.
#' @param t2 The time at which the plateau begins. Must be greater than \code{t1}.
#' @param k The height of the plateau. The function linearly increases from
#' 0 to \code{k} between \code{t1} and \code{t2}, then remains constant.
#'
#' @return A numeric vector of the same length as \code{t}, representing the function values.
#'
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
#' This function is continuous but not differentiable at \code{t1} and \code{t2}
#' due to the piecewise transitions. It is often used in agronomy and ecology
#' to describe growth until a resource limit or developmental plateau is reached.
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
#' A piecewise function that models an initial linear increase followed by a logistic saturation.
#'
#' @param t A numeric vector of input values (e.g., time).
#' @param t1 The onset time of the response. The function is 0 for all values less than \code{t1}.
#' @param t2 The transition time between the linear and logistic phases. Must be greater than \code{t1}.
#' @param k The plateau height. The function transitions toward this value in the logistic phase.
#'
#' @return A numeric vector of the same length as \code{t}, representing the function values.
#'
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
#' The linear segment rises from 0 starting at \code{t1}, and the logistic segment begins at \code{t2},
#' smoothly approaching the plateau value \code{k}.
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
#' @param t A numeric vector of input values (e.g., time).
#' @param t1 The onset time of the response. The function is 0 for all values less than \code{t1}.
#' @param t2 The time at which the plateau begins. Must be greater than \code{t1}.
#' @param b The initial slope of the curve at \code{t1}.
#' @param k The plateau height. The function transitions to this constant value at \code{t2}.
#'
#' @return A numeric vector of the same length as \code{t}, representing the function values.
#'
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
#' This function allows the user to specify the initial slope \code{b}. The curvature term
#' is automatically calculated so that the function reaches the plateau value \code{k} exactly
#' at \code{t2}. The transition to the plateau is continuous in value but not necessarily smooth
#' in derivative.
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

#' Smooth Quadratic-plateau function
#'
#' A piecewise function that models a quadratic increase from zero to a plateau value.
#' The function is continuous and differentiable, modeling growth
#' processes with a smooth transition to a maximum response.
#'
#' @param t A numeric vector of input values (e.g., time).
#' @param t1 The onset time of the response. The function is 0 for all values less than \code{t1}.
#' @param t2 The time at which the plateau begins. Must be greater than \code{t1}.
#' @param k The plateau height. The function transitions to this constant value at \code{t2}.
#'
#' @return A numeric vector of the same length as \code{t}, representing the function values.
#'
#' @export
#'
#' @details
#' \if{html}{
#' \deqn{
#' f(t; t_1, t_2, k) =
#' \begin{cases}
#' 0 & \text{if } t < t_1 \\
#' -\dfrac{k}{(t_2 - t_1)^2} (t - t_1)^2 + \dfrac{2k}{t_2 - t_1} (t - t_1) & \text{if } t_1 \leq t \leq t_2 \\
#' k & \text{if } t > t_2
#' \end{cases}
#' }
#' }
#'
#' The coefficients of the quadratic section are chosen such that the curve passes through
#' \code{(t1, 0)} and \code{(t2, k)} with a continuous first derivative (i.e., smooth transition).
#'
#' @examples
#' library(flexFitR)
#' plot_fn(
#'   fn = "fn_quad_pl_sm",
#'   params = c(t1 = 35, t2 = 80, k = 100),
#'   interval = c(0, 108),
#'   n_points = 2000,
#'   auc_label_size = 3
#' )
fn_quad_pl_sm <- function(t, t1, t2, k) {
  ifelse(
    test = t < t1,
    yes = 0,
    no = ifelse(
      test = t <= t2,
      yes = (-k / (t2 - t1)^2) * (t - t1)^2 + (2 * k / (t2 - t1)) * (t - t1),
      no = k
    )
  )
}


#' Linear plateau linear function
#'
#' A piecewise function that models an initial linear increase up to a plateau,
#' maintains that plateau for a duration, and then decreases linearly.
#'
#' @param t A numeric vector of input values (e.g., time).
#' @param t1 The onset time of the response. The function is 0 for all values less than \code{t1}.
#' @param t2 The time when the linear growth phase ends and the plateau begins. Must be greater than \code{t1}.
#' @param t3 The time when the plateau ends and the linear decline begins. Must be greater than \code{t2}.
#' @param k The height of the plateau. The first linear phase increases to this value, which remains constant until \code{t3}.
#' @param beta The slope of the final linear phase (typically negative), controlling the rate of decline after \code{t3}.
#'
#' @return A numeric vector of the same length as \code{t}, representing the function values.
#'
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
#' The function transitions continuously between all three phases but is not
#' differentiable at the transition points \code{t1}, \code{t2}, and \code{t3}.
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
#' A piecewise function that models an initial linear increase to a plateau, followed by a specified
#' duration of stability, and then a linear decline. This version parameterizes the plateau using
#' its duration rather than an explicit end time, making it convenient for box type of constraints
#' optimizations.
#'
#' @param t A numeric vector of input values (e.g., time).
#' @param t1 The onset time of the response. The function is 0 for all values less than \code{t1}.
#' @param t2 The time when the linear growth phase ends and the plateau begins. Must be greater than \code{t1}.
#' @param dt The duration of the plateau phase. The plateau ends at \code{t2 + dt}.
#' @param k The height of the plateau. The linear phase increases to this value, which remains constant for \code{dt} units of time.
#' @param beta The slope of the decline phase that begins after the plateau. Typically negative.
#'
#' @return A numeric vector of the same length as \code{t}, representing the function values.
#'
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
                      fixed_params = NA,
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
    "fn_quad_pl_sm",
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
