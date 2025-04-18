% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/04_predict.R
\name{.delta_method_gen}
\alias{.delta_method_gen}
\title{Delta method generic function}
\usage{
.delta_method_gen(fit, formula)
}
\arguments{
\item{fit}{A fit object which is located inside a modeler object}

\item{formula}{A formula specifying a function of the parameters to be estimated (e.g., \code{~ b * 500}). Default is \code{NULL}.}
}
\value{
A data.frame of the evaluated formula.
}
\description{
Delta method generic function
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
# Function of the parameters
predict(mod_1, formula = ~ t2 - t1, id = 2)
}
\keyword{internal}
