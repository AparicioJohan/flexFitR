#' Exponential Linear Function
#'
#' Computes a value based on an exponential linear model for time.
#'
#' @param t Numeric. The time value.
#' @param t1 Numeric. The lower threshold time.
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
#'
#' @details
#' \if{html}{
#' \deqn{
#' f(t) =
#' \begin{cases}
#' 0 & \text{if } t < t_1 \\
#' \exp(\alpha \cdot (t - t_1)^2) - 1 & \text{if } t_1 \leq t \leq t_2 \\
#' \beta \cdot (t - t_2) + \left(\exp(\alpha \cdot (t_2 - t_1)^2) - 1\right) & \text{if } t > t_2
#' \end{cases}
#' }
#' }
#'
#' @examples
#' fn_exp_linear(30, 20, 50, 0.1, -0.01) # Example usage
#'
#' @export
fn_exp_linear <- function(t, t1, t2, alpha, beta) {
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

#' Sum of Squares Error Function for Exponential Linear Model
#'
#' Calculates the sum of squared errors (SSE) between observed values and values
#' predicted by the \code{fn_exp_linear} function.
#'
#' @param params Numeric vector. The parameters for the \code{fn_exp_linear}
#' function, where \code{params[1]} is \code{t2}, \code{params[2]} is \code{alpha},
#' and \code{params[3]} is \code{beta}.
#' @param t Numeric vector. The time values.
#' @param y Numeric vector. The observed values.
#' @param t1 Numeric. The lower threshold time.
#'
#' @return A numeric value representing the sum of squared errors.
#'
#' @examples
#' params <- c(50, 0.1, -0.01)
#' t <- c(10, 20, 30, 40, 50, 60)
#' y <- c(0, 0, 0.2, 0.5, 0.8, 0.9)
#' t1 <- 20
#' fn_sse_lin(params, t, y, t1) # Should return the SSE value
#'
#' @export
fn_sse_lin <- function(params, t, y, t1) {
  t1 <- t1
  t2 <- params[1]
  alpha <- params[2]
  beta <- params[3]
  y_hat <- sapply(t, FUN = fn_exp_linear, t1, t2, alpha, beta)
  sse <- sum((y - y_hat)^2)
  return(sse)
}

#' Exponential Exponential Function
#'
#' Computes a value based on a double exponential model for time.
#'
#' @param t Numeric. The time value.
#' @param t1 Numeric. The lower threshold time.
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
#'
#' @details
#' \if{html}{
#' \deqn{
#' f(t) =
#' \begin{cases}
#' 0 & \text{if } t < t_1 \\
#' \exp(\alpha \cdot (t - t_1)^2) - 1 & \text{if } t_1 \leq t \leq t_2 \\
#' \left(\exp(\alpha \cdot (t_2 - t_1)^2) - 1\right) \cdot \exp(\beta \cdot (t - t_2)) & \text{if } t > t_2
#' \end{cases}
#' }
#' }
#'
#' @examples
#' fn_exp_exp(30, 20, 50, 0.1, -0.01) # Example usage
#' @export
fn_exp_exp <- function(t, t1, t2, alpha, beta) {
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

#' Sum of Squares Error Function for Exponential Exponential Model
#'
#' Calculates the sum of squared errors (SSE) between observed values and values
#' predicted by the \code{fn_exp_exp} function.
#'
#' @param params Numeric vector. The parameters for the \code{fn_exp_exp} function,
#' where \code{params[1]} is \code{t2}, \code{params[2]} is \code{alpha}, and
#' \code{params[3]} is \code{beta}.
#' @param t Numeric vector. The time values.
#' @param y Numeric vector. The observed values.
#' @param t1 Numeric. The lower threshold time.
#'
#' @return A numeric value representing the sum of squared errors.
#'
#' @examples
#' params <- c(50, 0.1, -0.01)
#' t <- c(10, 20, 30, 40, 50, 60)
#' y <- c(0, 0, 0.2, 0.5, 0.8, 0.9)
#' t1 <- 20
#' fn_sse_exp(params, t, y, t1) # Should return the SSE value
#'
#' @export
fn_sse_exp <- function(params, t, y, t1) {
  t1 <- t1
  t2 <- params[1]
  alpha <- params[2]
  beta <- params[3]
  y_hat <- sapply(t, FUN = fn_exp_exp, t1, t2, alpha, beta)
  sse <- sum((y - y_hat)^2)
  return(sse)
}

#' Plant Height Modelling
#'
#' @param results Object of class exploreHTP
#' @param canopy Object of class canopy_HTP
#' @param plant_height  string
#' @param plot_id Optional Plot ID. NULL by default
#' @param add_zero TRUE or FALSE. Add zero to the time series.TRUE by default.
#' @param method A vector of the methods to be used, each as a character string.
#' See optimx package. c("subplex", "pracmanm", "anms") by default.
#' @param return_method TRUE or FALSE. To return the method selected for the
#' optimization in the table. FALSE by default.
#' @param parameters (Optional)	Initial values for the parameters to be
#' optimized over. c(45, 80) by default.
#' @param fn A function to be minimized (or maximized), with first argument the
#' vector of parameters over which minimization is to take place.
#' It should return a scalar result. Default is \link{fn_sse_exp}.

#' @return data.frame
#' @export
#'
#' @examples
#' library(exploreHTP)
#' data(dt_potato)
#' dt_potato <- dt_potato
#' results <- read_HTP(
#'   data = dt_potato,
#'   genotype = "Gen",
#'   time = "DAP",
#'   plot = "Plot",
#'   traits = c("Canopy", "PH"),
#'   row = "Row",
#'   range = "Range"
#' )
#' names(results)
#' out <- canopy_HTP(
#'   results = results,
#'   canopy = "Canopy",
#'   plot_id = c(22, 40),
#'   correct_max = TRUE,
#'   add_zero = TRUE
#' )
#' names(out)
#' plot(out, c(22, 40))
#' out$param
#' @import optimx
#' @import tibble
height_HTP <- function(results,
                       canopy,
                       plant_height = "PH",
                       plot_id = NULL,
                       add_zero = TRUE,
                       method = c("lbfgsb3c", "pracmanm", "anms"),
                       return_method = FALSE,
                       parameters = c(t2 = 67, alpha = 1 / 600, beta = -1 / 80),
                       fn = fn_sse_exp) {
  param <- canopy$param |>
    select(plot:range, t1, t2) |>
    rename(DMC = t2)

  dt <- results$dt_long |>
    filter(trait %in% plant_height) |>
    filter(!is.na(value)) |>
    filter(plot %in% param$plot) |>
    full_join(param, by = c("plot", "row", "range", "genotype"))

  if (add_zero) {
    dt <- dt |>
      mutate(time = 0, value = 0) |>
      unique.data.frame() |>
      rbind.data.frame(dt) |>
      arrange(plot, time)
  }
  if (!is.null(plot_id)) {
    dt <- dt |>
      filter(plot %in% plot_id) |>
      droplevels()
  }

  param_ph <- dt |>
    nest_by(plot, genotype, row, range) |>
    summarise(
      res = list(
        opm(
          par = parameters,
          fn = fn,
          t = data$time,
          y = data$value,
          t1 = unique(data$t1),
          method = method
        ) |>
          mutate(t1 = unique(data$t1)) |>
          rownames_to_column(var = "method") |>
          arrange(value) |>
          rename(sse = value) |>
          select(2:(length(parameters) + 1), t1, method, sse) |>
          slice(1)
      ),
      .groups = "drop"
    ) |>
    unnest(cols = res)
  if (!return_method) {
    param_ph <- select(param_ph, -method)
  }
  out <- list(param = param_ph, dt = dt)
  class(out) <- "height_HTP"
  return(out)
}
