#' Combine objects of class \code{modeler}
#'
#' @description Combine objects of class \code{modeler}. Use with caution, some
#' functions might not work as expected.
#' @aliases c.modeler
#' @param ... Objects of class \code{modeler}, typically the result of calling \code{modeler()}.
#' @author Johan Aparicio [aut]
#' @method c modeler
#' @return A \code{modeler} object.
#' @export
#' @examples
#' library(flexFitR)
#' data(dt_potato)
#' mod_1 <- dt_potato |>
#'   modeler(
#'     x = DAP,
#'     y = Canopy,
#'     grp = Plot,
#'     fn = "fn_logistic",
#'     parameters = c(L = 100, k = 4, t0 = 40),
#'     subset = 1:2
#'   )
#' mod_2 <- dt_potato |>
#'   modeler(
#'     x = DAP,
#'     y = Canopy,
#'     grp = Plot,
#'     fn = "fn_lin_plat",
#'     parameters = c(t1 = 45, t2 = 80, k = 100),
#'     subset = 1:2
#'   )
#' mod <- c(mod_1, mod_2)
#' print(mod)
#' plot(mod, id = 1:2)
#' @import dplyr
c.modeler <- function(...) {
  .models <- list(...)
  if (length(.models) == 0) stop("You must provide a model")
  param_mat <- do.call(
    what = rbind,
    args = lapply(.models, coef.modeler, metadata = TRUE)
  ) |>
    as_tibble()
  dt <- do.call(rbind, args = lapply(.models, \(x) x$dt)) |>
    as_tibble()
  metrics <- do.call(rbind, args = lapply(.models, \(x) x$metrics)) |>
    as_tibble()
  time <- sum(unlist(lapply(.models, \(x) x$execution)))
  variable <- unique(unlist(lapply(.models, \(x) x$response)))
  x_var <- unique(unlist(lapply(.models, \(x) x$x_var)))
  metadata <- unique(unlist(lapply(.models, \(x) x$keep)))
  fn <- unique(dt$fn_name)
  objt <- do.call(c, args = lapply(.models, \(x) x$fit))
  out <- list(
    param = param_mat,
    dt = dt,
    metrics = metrics,
    execution = time,
    response = variable,
    x_var = x_var,
    keep = metadata,
    fun = fn,
    parallel = NULL,
    fit = objt
  )
  class(out) <- "modeler"
  return(invisible(out))
}


#' Subset an object of class \code{modeler}
#'
#' @description Subset an object of class \code{modeler}
#' @aliases subset.modeler
#' @param x An object of class \code{modeler}, typically the result of calling \code{modeler()}.
#' @param id Unique identifier to filter a \code{modeler} object by a specific group. Default is \code{NULL}.
#' @param ... Additional parameters for future functionality.
#' @author Johan Aparicio [aut]
#' @method subset modeler
#' @return A \code{modeler} object.
#' @export
#' @examples
#' library(flexFitR)
#' data(dt_potato)
#' mod <- dt_potato |>
#'   modeler(
#'     x = DAP,
#'     y = Canopy,
#'     grp = Plot,
#'     fn = "fn_logistic",
#'     parameters = c(L = 100, k = 4, t0 = 40),
#'     subset = 1:2
#'   )
#' print(mod)
#' mod_new <- subset(mod, id = 2)
#' print(mod_new)
#' @import dplyr
subset.modeler <- function(x, id = NULL, ...) {
  # Check the class of object
  if (!inherits(x, "modeler")) {
    stop("The x should be of class 'modeler'.")
  }
  if (!is.null(id)) {
    if (!all(id %in% unique(x$dt$uid))) {
      stop("ids not found in object.")
    }
  } else {
    id <- unique(x$dt$uid)
  }
  param_mat <- filter(x$param, uid %in% id)
  dt <- filter(x$dt, uid %in% id)
  metrics <- filter(x$metrics, uid %in% id)
  time <- x$execution
  variable <- x$response
  x_var <- x$x_var
  metadata <- x$keep
  fn <- unique(dt$fn_name)
  paralell <- x$parallel
  # List of models
  objt <- x$fit
  pos <- which(unlist(lapply(objt, function(x) x$uid)) %in% id)
  objt <- objt[pos]
  out <- list(
    param = param_mat,
    dt = dt,
    metrics = metrics,
    execution = time,
    response = variable,
    x_var = x_var,
    keep = metadata,
    fun = fn,
    parallel = paralell,
    fit = objt
  )
  class(out) <- "modeler"
  return(invisible(out))
}
