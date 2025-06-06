% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/04_predict.R
\name{.delta_method_deriv}
\alias{.delta_method_deriv}
\title{Delta method for derivative estimation}
\usage{
.delta_method_deriv(fit, x_new, which = "fd")
}
\arguments{
\item{fit}{A fit object which is located inside a modeler object}

\item{x_new}{A vector of x values to evaluate the derivative.}

\item{which}{Can be "fd" for first-derivative or "sd" for second-derivative.}
}
\value{
A data.frame of the evaluated values.
}
\description{
Delta method for derivative estimation
}
\examples{
library(flexFitR)
data(dt_potato)
mod_1 <- dt_potato |>
  modeler(
    x = DAP,
    y = Canopy,
    grp = Plot,
    fn = "fn_lin_plat",
    parameters = c(t1 = 45, t2 = 80, k = 0.9),
    subset = c(15, 2, 45)
  )
print(mod_1)
# First Derivative
predict(mod_1, x = 45, type = "fd", id = 2)
}
\keyword{internal}
