#'  Extract Log-Likelihood for an object of class \code{modeler}
#'
#' @description logLik for an object of class \code{modeler}
#' @aliases logLik.modeler
#' @param object An object inheriting from class \code{modeler} resulting of
#' executing the function \code{modeler()}
#' @param ... Further parameters. For future improvements.
#' @author Johan Aparicio [aut]
#' @method logLik modeler
#' @return A \code{tibble} with the Log-Likelihood for the fitted models.
#' @export
#' @examples
#' library(flexFitR)
#' dt <- data.frame(X = 1:6, Y = c(12, 16, 44, 50, 95, 100))
#' mo_1 <- modeler(dt, X, Y, fn = "fn_lin", param = c(m = 10, b = -5))
#' plot(mo_1)
#' logLik(mo_1)
logLik.modeler <- function(object, ...) {
  ids <- unlist(x = lapply(object$fit, FUN = \(x) x$uid))
  sse <- object$param$sse
  N <- unlist(x = lapply(object$fit, FUN = \(x) x$n_obs))
  P <- unlist(x = lapply(X = object$fit, FUN = \(x) x$p))
  logL <- 0.5 * (-N * (log(2 * pi) + 1 - log(N) + log(sse)))
  df <- 1L + P
  out <- data.frame(uid = ids, logLik = logL, df = df, nobs = N, p = P)
  return(out)
}

#'  Akaike's An Information Criterion for an object of class \code{modeler}
#'
#' @description Generic function calculating Akaike's ‘An Information Criterion’
#' for fitted model object of class \code{modeler}.
#' @name goodness_of_fit
#' @param object An object inheriting from class \code{modeler} resulting of
#' executing the function \code{modeler()}
#' @param ... Further parameters. For future improvements.
#' @param k Numeric, the penalty per parameter to be used; the default k = 2 is
#' the classical AIC.
#' @author Johan Aparicio [aut]
#' @return A \code{tibble} with columns giving the corresponding AIC and BIC.
#' @examples
#' library(flexFitR)
#' dt <- data.frame(X = 1:6, Y = c(12, 16, 44, 50, 95, 100))
#' mo_1 <- modeler(dt, X, Y, fn = "fn_lin", param = c(m = 10, b = -5))
#' mo_2 <- modeler(dt, X, Y, fn = "fn_quad", param = c(a = 1, b = 10, c = 5))
#' AIC(mo_1)
#' AIC(mo_2)
#' BIC(mo_1)
#' BIC(mo_2)
NULL
#> NULL

#' @aliases AIC.modeler
#' @method AIC modeler
#' @rdname goodness_of_fit
#' @export
AIC.modeler <- function(object, ..., k = 2) {
  logdt <- logLik.modeler(object)
  logdt$AIC <- k * (logdt$df) - 2 * logdt$logLik
  return(logdt)
}

#' @aliases BIC.modeler
#' @method BIC modeler
#' @rdname goodness_of_fit
#' @export
#' @importFrom stats BIC
BIC.modeler <- function(object, ...) {
  logdt <- logLik.modeler(object)
  logdt$BIC <- log(logdt$nobs) * (logdt$df) - 2 * logdt$logLik
  return(logdt)
}

#'  Extra Sum-of-Squares F-Test for \code{modeler} objects
#'
#' @description Perform an extra sum-of-squares F-test to compare two nested
#' models of class \code{modeler}. This test assesses whether the additional
#' parameters in the full model significantly improve the fit compared to the
#' reduced model.
#' @aliases anova.modeler
#' @param reduced_model An object of class \code{modeler} representing the
#' reduced model with fewer parameters.
#' @param full_model An optional object of class \code{modeler} representing
#' the full model with more parameters.
#' @param ... Additional parameters for future functionality.
#' @author Johan Aparicio [aut]
#' @method anova modeler
#' @return A \code{tibble} containing columns with the F-statistic and
#' corresponding p-values, indicating whether the full model provides a
#' significantly better fit than the reduced model.
#' @export
#' @examples
#' library(flexFitR)
#' dt <- data.frame(X = 1:6, Y = c(12, 16, 44, 50, 95, 100))
#' mo_1 <- modeler(dt, X, Y, fn = "fn_lin", param = c(m = 10, b = -5))
#' plot(mo_1)
#' mo_2 <- modeler(dt, X, Y, fn = "fn_quad", param = c(a = 1, b = 10, c = 5))
#' plot(mo_2)
#' anova(mo_1, mo_2)
#' @importFrom stats pf
anova.modeler <- function(reduced_model, full_model = NULL, ...) {
  if (!inherits(reduced_model, "modeler")) {
    stop("The object should be of class 'modeler'.")
  }
  if (is.null(full_model)) {
    stop("anova is only defined for a sequence of two \"modeler\" objects")
  }
  if (!inherits(full_model, "modeler")) {
    stop("full_model should be of class 'modeler'.")
  }
  vars <- c("uid", "var", "x", "y")
  if (!identical(reduced_model$dt[, vars], full_model$dt[, vars])) {
    stop("The models are not fitted to the same dataset.")
  }
  p_breaks <- c(0, 0.001, 0.01, 0.05, Inf)
  p_labels <- c("***", "**", "*", "ns")
  # Calculate Residual Sum of Squares for both models
  rss_reduced <- reduced_model$param$sse
  rss_full <- full_model$param$sse
  # Number of parameters in each model
  p_reduced <- unlist(x = lapply(X = reduced_model$fit, FUN = \(x) x$p))
  p_full <- unlist(x = lapply(X = full_model$fit, FUN = \(x)  x$p))
  if (unique(p_reduced) >= unique(p_full)) {
    stop("The reduced model must have fewer parameters than the full model.")
  }
  # Number of observations
  n <- unlist(x = lapply(full_model$fit, FUN = \(x) x$n_obs))
  # Calculate the F-statistic
  numerator <- (rss_reduced - rss_full) / (p_full - p_reduced)
  denominator <- rss_full / (n - p_full)
  f_statistic <- numerator / denominator
  # DF
  df1 <- p_full - p_reduced
  df2 <- n - p_full
  # Calculate the p-value
  p_value <- pf(q = f_statistic, df1 = df1, df2 = df2, lower.tail = FALSE)
  tag <- cut(x = p_value, right = FALSE, breaks = p_breaks, labels = p_labels)
  # IDs
  ids <- unlist(x = lapply(full_model$fit, FUN = \(x) x$uid))
  # Output results as a tibble
  results <- data.frame(
    uid = ids,
    RSS_reduced = rss_reduced,
    RSS_full = rss_full,
    n = n,
    df1 = df1,
    df2 = df2,
    `F` = f_statistic,
    `Pr(>F)` = p_value,
    "." = tag,
    check.names = FALSE
  ) |>
    as_tibble()
  return(results)
}
