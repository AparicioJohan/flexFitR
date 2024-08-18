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
#'   \item{\code{dt}}{A data frame with data used and fitted values.}
#'   \item{\code{fn}}{The call used to calculate the AUC.}
#'   \item{\code{metrics}}{Metrics and summary of the models.}
#'   \item{\code{max_time}}{Maximum time value used for calculating the AUC.}
#'   \item{\code{execution}}{Execution time.}
#'   \item{\code{response}}{Response variable.}
#'   \item{\code{.keep}}{Metadata to keep across.}
#'   \item{\code{fun}}{Function being optimized}
#'   \item{\code{fit}}{List with the fitted models.}
#' }
#' @export
#'
#' @examples
#' library(exploreHTP)
#' data(dt_chips)
#' results <- dt_chips |>
#'   read_HTP(
#'     x = DAP,
#'     y = c(Canopy, PH),
#'     id = Plot,
#'     .keep = c(Gen, Row, Range)
#'   )
#' mod_1 <- height_HTP(
#'   x = results,
#'   height = "PH",
#'   canopy = "Canopy",
#'   id = 60,
#'   fn = "fn_exp2_lin"
#' )
#' print(mod_1)
#' plot(x = mod_1, id = 60)
#' mod_2 <- height_HTP(
#'   x = results,
#'   height = "PH",
#'   canopy = "Canopy",
#'   id = 60,
#'   fn = "fn_exp2_exp"
#' )
#' plot(x = mod_2, id = 60)
#' print(mod_2)
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
