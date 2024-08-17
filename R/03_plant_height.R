#' Plant Height Modelling
#'
#' @param x An object of class \code{read_HTP}, containing the results of the \code{read_HTP()} function.
#' @param height A string specifying the plant height trait to be modeled. Default is \code{"PH"}.
#' @param canopy A string specifying the canopy trait to be modeled. Default is \code{"Canopy"}.
#' @param id An optional vector of plot IDs to filter the data. Default is \code{NULL}, meaning all plots are used.
#' @param fn One of the following options: "fn_exp1_exp", "fn_exp1_lin", "fn_exp2_exp", "fn_exp2_lin".
#' @param ... Additional arguments passed to the \code{modeler_HTP()} function.
#' @return An object of class \code{modeler_HTP}, which is a list containing the following elements:
#' \describe{
#'   \item{\code{param}}{A data frame containing the optimized parameters and related information.}
#'   \item{\code{dt}}{A data frame with data used.}
#'   \item{\code{fn}}{The call used to calculate the AUC.}
#'   \item{\code{max_time}}{Maximum time value used for calculating the AUC.}
#' }
#' @export
#'
#' @examples
#' library(exploreHTP)
#' data(dt_chips)
#' results <- read_HTP(
#'   data = dt_chips,
#'   x = "DAP",
#'   y = c("Canopy", "PH"),
#'   id = "Plot",
#'   .keep = c("Gen", "Row", "Range")
#' )
#' ph_1 <- height_HTP(
#'   x = results,
#'   height = "PH",
#'   canopy = "Canopy",
#'   id = 60,
#'   fn = "fn_exp2_lin"
#' )
#' print(ph_1)
#' plot(x = ph_1, id = 60)
#' ph_2 <- height_HTP(
#'   x = results,
#'   height = "PH",
#'   canopy = "Canopy",
#'   id = 60,
#'   fn = "fn_exp2_exp"
#' )
#' plot(x = ph_2, id = 60)
#' print(ph_2)
#' @import optimx
#' @import tibble
height_HTP <- function(x,
                       height = "PH",
                       canopy = "Canopy",
                       id = NULL,
                       fn = c("fn_exp1_exp", "fn_exp1_lin", "fn_exp2_exp", "fn_exp2_lin"),
                       ...) {
  fn <- match.arg(fn)
  if (!inherits(x, "read_HTP")) {
    stop("The object should be of read_HTP class")
  }
  traits <- unique(x$dt_long$var)
  if (!canopy %in% traits) {
    stop(canopy, " not found in x. Please verify the spelling.")
  }
  if (!height %in% traits) {
    stop(height, " not found in x. Please verify the spelling.")
  }
  plots <- unique(x$dt_long$uid)
  if (!is.null(id)) {
    if (!all(id %in% plots)) {
      stop("Id not found in data.")
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
  fixed_params <- mod_1$param |>
    select(uid, t1)
  initials <- mod_1$param |>
    select(uid, t1, t2) |>
    mutate(alpha = 1 / 600, beta = -1 / 30)
  out <- modeler_HTP(
    x = x,
    index = height,
    id = plots,
    fn = fn,
    initial_vals = initials,
    fixed_params = fixed_params,
    ...
  )
  return(out)
}


# #' Plant Height Modelling
# #'
# #' @param results An object of class \code{read_HTP}, containing the results of the \code{read_HTP()} function.
# #' @param canopy An object of class \code{canopy_HTP}, containing the results of the \code{canopy_HTP()} function.
# #' @param plant_height A string specifying the Plant Height trait to be modeled. Default is \code{"PH"}.
# #' @param plot_id An optional vector of plot IDs to filter the data. Default is \code{NULL}, meaning all plots are used.
# #' @param add_zero \code{TRUE} or \code{FALSE}. Add zero to the time series. \code{TRUE} by default.
# #' @param method A character vector of optimization methods to be used, as specified in the \code{optimx} package. Default is \code{c("subplex", "pracmanm", "anms")}.
# #' @param return_method Logical. If \code{TRUE}, includes the selected optimization method in the output table. Default is \code{FALSE}.
# #' @param parameters A named vector specifying the initial values for the parameters to be optimized.
# #' Default is c(t2 = 67, alpha = 1 / 600, beta = -1 / 80). The first parameter, t1, is assumed to be known and is calculated from the Canopy Model.
# #' @param fn_sse A function to be minimized (or maximized), with first argument the vector of parameters over which minimization is to take place.
# #' It should return a scalar result. Default is \link{sse_exp2_exp}.
# #' @param fn Object of class call. e.g. \code{quote(fn_exp2_exp(time, t1, t2, alpha, beta))} to calculate the area under the curve (AUC). Always use time as first argument.
# #' @param n_points Number of time points to approximate the AUC. 1000 by default.
# #' @param max_time Maximum time value for calculating the AUC. \code{NULL} by default takes the last time point.
# #' @return An object of class \code{height_HTP}, which is a list containing the following elements:
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
# #' data(dt_chips)
# #' results <- read_HTP(
# #'   data = dt_chips,
# #'   genotype = "Gen",
# #'   time = "DAP",
# #'   plot = "Plot",
# #'   traits = c("Canopy", "PH"),
# #'   row = "Row",
# #'   range = "Range"
# #' )
# #' names(results)
# #' out <- canopy_HTP(
# #'   x = results,
# #'   index = "Canopy",
# #'   plot_id = c(60, 150)
# #' )
# #' names(out)
# #' plot(out, plot_id = c(60, 150))
# #' ph_1 <- height_HTP(
# #'   results = results,
# #'   canopy = out,
# #'   plant_height = "PH",
# #'   add_zero = TRUE,
# #'   method = c("nlminb", "anms", "mla", "pracmanm", "subplex"),
# #'   return_method = TRUE,
# #'   parameters = c(t2 = 67, alpha = 1 / 600, beta = -1 / 80),
# #'   fn_sse = sse_exp2_exp,
# #'   fn = quote(fn_exp2_exp(time, t1, t2, alpha, beta))
# #' )
# #' plot(x = ph_1, plot_id = c(60, 150))
# #' ph_1$param
# #'
# #' ph_2 <- height_HTP(
# #'   results = results,
# #'   canopy = out,
# #'   plant_height = "PH",
# #'   add_zero = TRUE,
# #'   method = c("nlminb", "anms", "mla", "pracmanm", "subplex"),
# #'   return_method = TRUE,
# #'   parameters = c(t2 = 67, alpha = 1 / 600, beta = -1 / 80),
# #'   fn_sse = sse_exp2_lin,
# #'   fn = quote(fn_exp2_lin(time, t1, t2, alpha, beta))
# #' )
# #' plot(x = ph_2, plot_id = c(60, 150))
# #' ph_2$param
# #' @import optimx
# #' @import tibble
#  height_HTP <- function(results,
#                        canopy,
#                        plant_height = "PH",
#                        plot_id = NULL,
#                        add_zero = TRUE,
#                        method = c("subplex", "pracmanm", "anms"),
#                        return_method = FALSE,
#                        parameters = c(t2 = 67, alpha = 1 / 600, beta = -1 / 80),
#                        fn_sse = sse_exp2_exp,
#                        fn = quote(fn_exp2_exp(time, t1, t2, alpha, beta)),
#                        n_points = 1000,
#                        max_time = NULL) {
#   param <- canopy$param |>
#     select(plot:range, t1, t2) |>
#     rename(DMC = t2)
#
#   dt <- results$dt_long |>
#     filter(trait %in% plant_height) |>
#     filter(!is.na(value)) |>
#     filter(plot %in% param$plot) |>
#     full_join(param, by = c("plot", "row", "range", "genotype"))
#
#   if (add_zero) {
#     dt <- dt |>
#       mutate(time = 0, value = 0) |>
#       unique.data.frame() |>
#       rbind.data.frame(dt) |>
#       arrange(plot, time)
#   }
#   if (!is.null(plot_id)) {
#     dt <- dt |>
#       filter(plot %in% plot_id) |>
#       droplevels()
#   }
#
#   param_ph <- dt |>
#     nest_by(plot, genotype, row, range) |>
#     summarise(
#       res = list(
#         opm(
#           par = parameters,
#           fn = fn_sse,
#           t = data$time,
#           y = data$value,
#           t1 = unique(data$t1),
#           method = method
#         ) |>
#           mutate(t1 = unique(data$t1)) |>
#           rownames_to_column(var = "method") |>
#           arrange(value) |>
#           rename(sse = value) |>
#           select(2:(length(parameters) + 1), t1, method, sse) |>
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
#     y = param_ph,
#     by = "plot"
#   ) |>
#     group_by(time, plot) |>
#     mutate(hat = !!fn) |>
#     group_by(plot) |>
#     mutate(trapezoid_area = (lead(hat) + hat) / 2 * (lead(time) - time)) |>
#     filter(!is.na(trapezoid_area)) |>
#     summarise(total_area = sum(trapezoid_area))
#   param_ph <- full_join(param_ph, auc, by = "plot")
#
#   if (!return_method) {
#     param_ph <- select(param_ph, -method)
#   }
#   out <- list(param = param_ph, dt = dt, fn = fn, max_time = max_time)
#   class(out) <- "height_HTP"
#   return(invisible(out))
#  }
