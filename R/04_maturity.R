#' Maturity Modelling
#'
#' @param x An object of class \code{read_HTP}, containing the results of the \code{read_HTP()} function.
#' @param index A string specifying the canopy trait to be modeled. Default is \code{"GLI"}.
#' @param canopy A string specifying the canopy trait to be modeled. Default is \code{"Canopy"}.
#' @param id An optional vector of plot IDs to filter the data. Default is \code{NULL}, meaning all plots are used.
#' @param ... Additional arguments passed to the \code{modeler_HTP()} function.
#' @return An object of class \code{modeler_HTP}, which is a list containing the following elements:
#' \describe{
#'   \item{\code{param}}{A data frame containing the optimized parameters and related information.}
#'   \item{\code{dt}}{A data frame with the corrected and possibly zero-augmented canopy data.}
#'   \item{\code{fn}}{The call used to calculate the AUC.}
#'   \item{\code{max_time}}{Maximum time value used for calculating the AUC.}
#' }
#' @export
#'
#' @examples
#' library(exploreHTP)
#' data(dt_potato)
#' results <- read_HTP(
#'   data = dt_potato,
#'   x = "DAP",
#'   y = c("Canopy", "GLI_2"),
#'   id = "Plot",
#'   .keep = c("Gen", "Row", "Range")
#' )
#' mat <- maturity_HTP(
#'   x = results,
#'   index = "GLI_2",
#'   canopy = "Canopy",
#'   id = c(195, 40)
#' )
#' plot(mat, plot_id = c(195, 40))
#' print(mat)
#' @import optimx
#' @import tibble
#' @import dplyr
maturity_HTP <- function(x,
                         index = "GLI",
                         canopy = "Canopy",
                         id = NULL,
                         ...) {
  if (!inherits(x, "read_HTP")) {
    stop("The object should be of read_HTP class")
  }
  traits <- unique(x$dt_long$var)
  if (!canopy %in% traits) {
    stop(canopy, " not found in x. Please verify the spelling.")
  }
  if (!index %in% traits) {
    stop(index, " not found in x. Please verify the spelling.")
  }
  plots <- unique(x$dt_long$uid)
  if (!is.null(id)) {
    if (!all(id %in% plots)) {
      stop("plot_id not found in data.")
    } else {
      plots <- id
    }
  }
  fixed_params <- x$dt_long |>
    filter(var %in% canopy & uid %in% plots) |>
    group_by(uid) |>
    summarise(k = max(y), .groups = "drop")
  time <- unique(x$dt_long$x)
  t1 <- as.numeric(quantile(time, 0.3))
  t2 <- as.numeric(quantile(time, 0.6))
  t3 <- as.numeric(quantile(time, 0.8))
  k <- mean(fixed_params$k, na.rm = TRUE)
  mod_1 <- modeler_HTP(
    x = x,
    index = canopy,
    id = plots,
    parameters = c(t1 = t1, t2 = t2, k = k),
    fn = "fn_piwise",
    fixed_params = fixed_params,
    max_as_last = TRUE
  )
  initials <- mod_1$param |>
    select(uid, t1, t2) |>
    mutate(dt = t3 - t2, k = 0.32, beta = -0.01)
  out <- modeler_HTP(
    x = x,
    index = index,
    id = plots,
    initial_vals = initials,
    fn = "fn_lin_pl_lin2",
    method = c("nlminb", "L-BFGS-B"),
    lower = c(-Inf, -Inf, 0, -Inf, -Inf),
    upper = c(Inf, Inf, Inf, Inf, 0),
    ...
  )
  out$param$t3 <- out$param$t2 + out$param$dt
  return(out)
}


# #' Maturity Modelling
# #'
# #' @param results An object of class \code{read_HTP}, containing the results of the \code{read_HTP()} function.
# #' @param canopy An object of class \code{canopy_HTP}, containing the results of the \code{canopy_HTP()} function.
# #' @param index A string specifying the trait to be modeled. Default is \code{"GLI"}.
# #' @param plot_id An optional vector of plot IDs to filter the data. Default is \code{NULL}, meaning all plots are used.
# #' @param add_zero \code{TRUE} or \code{FALSE}. Add zero to the time series.\code{TRUE} by default.
# #' @param check_negative Logical. Convert negative values to zero. \code{TRUE} by default.
# #' @param method A vector of the methods to be used, each as a character string.
# #' See optimx package. c("subplex", "pracmanm", "anms") by default.
# #' @param return_method \code{TRUE} or \code{FALSE}. To return the method selected for the
# #' optimization in the table. \code{FALSE} by default.
# #' @param parameters (Optional)	Initial values for the parameters to be
# #' optimized over. c(t1 = 38.7, t2 = 62, t3 = 90, k = 0.32, beta = -0.01) by default.
# #' @param lower Bounds on the variables for methods such as "L-BFGS-B" that can handle box (or bounds) constraints.
# #' @param upper Bounds on the variables for methods such as "L-BFGS-B" that can handle box (or bounds) constraints.
# #' @param initial_vals \code{TRUE} or \code{FALSE}. Whether the user wants to use t1 and t2 from the
# #' Canopy model as initial values or not. Only works if the function \code{fn} uses t1 and t2 as parameters.
# #' \code{FALSE} by default.
# #' @param fn_sse A function to be minimized (or maximized), with first argument the
# #' vector of parameters over which minimization is to take place.
# #' It should return a scalar result. Default is \link{sse_lin_pl_lin}.
# #' @param fn Object of class call. e.g. \code{quote(fn_lin_pl_lin(time, t1, t2, t3, k, beta))} to calculate the area under the curve (AUC). Always use time as first argument.
# #' @param n_points Number of time points to approximate the AUC. 1000 by default.
# #' @param max_time Maximum time value for calculating the AUC. \code{NULL} by default takes the last time point.
# #' @return An object of class \code{maturity_HTP}, which is a list containing the following elements:
# #' \describe{
# #'   \item{\code{param}}{A data frame containing the optimized parameters and related information.}
# #'   \item{\code{dt}}{A data frame with data used.}
# #'   \item{\code{fn}}{The call used to calculate the AUC.}
# #'   \item{\code{max_time}}{Maximum time value used for calculating the AUC.}
# #' }
# #' @export
# #'
# #' @examples
# #' library(exploreHTP)
# #' data(dt_potato)
# #' dt_potato <- dt_potato
# #' results <- read_HTP(
# #'   data = dt_potato,
# #'   genotype = "Gen",
# #'   time = "DAP",
# #'   plot = "Plot",
# #'   traits = c("Canopy", "GLI_2"),
# #'   row = "Row",
# #'   range = "Range"
# #' )
# #' names(results)
# #' out <- canopy_HTP(
# #'   x = results,
# #'   index = "Canopy",
# #'   plot_id = c(195, 40)
# #' )
# #' mat <- maturity_HTP(
# #'   results = results,
# #'   canopy = out,
# #'   index = "GLI_2",
# #'   parameters = c(t1 = 38.7, t2 = 62, t3 = 90, k = 0.32, beta = -0.01),
# #'   fn_sse = sse_lin_pl_lin,
# #'   fn = quote(fn_lin_pl_lin(time, t1, t2, t3, k, beta))
# #' )
# #' plot(mat, plot_id = c(195, 40))
# #' mat$param
# #' @import optimx
# #' @import tibble
# #' @import dplyr
# maturity_HTP <- function(results,
#                          canopy,
#                          index = "GLI",
#                          plot_id = NULL,
#                          add_zero = TRUE,
#                          check_negative = TRUE,
#                          method = c("subplex", "pracmanm", "anms"),
#                          return_method = FALSE,
#                          parameters = c(t1 = 38.7, t2 = 62, t3 = 90, k = 0.32, beta = -0.01),
#                          lower = -Inf,
#                          upper = Inf,
#                          initial_vals = FALSE,
#                          fn_sse = sse_lin_pl_lin,
#                          fn = quote(fn_lin_pl_lin(time, t1, t2, t3, k, beta)),
#                          n_points = 1000,
#                          max_time = NULL) {
#   param <- canopy$param |>
#     select(plot:range, t1, t2) |>
#     rename(DE = t1, DMC = t2)
#
#   dt <- results$dt_long |>
#     filter(trait %in% index) |>
#     filter(!is.na(value)) |>
#     filter(plot %in% param$plot) |>
#     full_join(param, by = c("plot", "row", "range", "genotype"))
#
#   if (check_negative) {
#     dt <- mutate(dt, value = ifelse(value < 0, 0, value))
#   }
#
#   if (add_zero) {
#     dt <- dt |>
#       mutate(time = 0, value = 0) |>
#       unique.data.frame() |>
#       rbind.data.frame(dt) |>
#       arrange(plot, time)
#   }
#
#   if (initial_vals) {
#     init <- canopy$param |>
#       select(plot, genotype, t1, t2) |>
#       cbind(data.frame(t(parameters[-c(1:2)]))) |>
#       pivot_longer(
#         cols = -c(plot, genotype),
#         names_to = "coef",
#         values_to = "val"
#       ) |>
#       nest_by(plot, genotype, .key = "param") |>
#       mutate(param = list(pull(param, val, coef)))
#   } else {
#     init <- canopy$param |>
#       select(plot, genotype) |>
#       cbind(data.frame(t(parameters))) |>
#       pivot_longer(
#         cols = -c(plot, genotype),
#         names_to = "coef",
#         values_to = "val"
#       ) |>
#       nest_by(plot, genotype, .key = "param") |>
#       mutate(param = list(pull(param, val, coef)))
#   }
#
#   if (!is.null(plot_id)) {
#     dt <- droplevels(filter(dt, plot %in% plot_id))
#     init <- droplevels(filter(init, plot %in% plot_id))
#   }
#
#   dt_nest <- dt |>
#     nest_by(plot, genotype, row, range) |>
#     full_join(init, by = c("plot", "genotype"))
#
#   param_mat <- dt_nest |>
#     summarise(
#       res = list(
#         opm(
#           par = param,
#           fn = fn_sse,
#           t = data$time,
#           y = data$value,
#           method = method,
#           lower = lower,
#           upper = upper
#         ) |>
#           rownames_to_column(var = "method") |>
#           arrange(value) |>
#           rename(sse = value) |>
#           select(2:(length(parameters) + 1), method, sse) |>
#           slice(1)
#       ),
#       .groups = "drop"
#     ) |>
#     unnest(cols = res)
#
#   if (is.null(max_time)) {
#     max_time <- max(dt$time, na.rm = TRUE)
#   }
#
#   # AUC
#   sq <- seq(0, max_time, length.out = n_points)
#   auc <- full_join(
#     x = expand.grid(time = sq, plot = unique(dt$plot)),
#     y = param_mat,
#     by = "plot"
#   ) |>
#     group_by(time, plot) |>
#     mutate(hat = !!fn) |>
#     group_by(plot) |>
#     mutate(trapezoid_area = (lead(hat) + hat) / 2 * (lead(time) - time)) |>
#     filter(!is.na(trapezoid_area)) |>
#     summarise(total_area = sum(trapezoid_area))
#   param_mat <- full_join(param_mat, auc, by = "plot")
#
#   if (!return_method) {
#     param_mat <- select(param_mat, -method)
#   }
#   out <- list(param = param_mat, dt = dt, fn = fn, max_time = max_time)
#   class(out) <- "maturity_HTP"
#   return(invisible(out))
# }
