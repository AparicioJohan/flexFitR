% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/10_combining.R
\name{c.modeler}
\alias{c.modeler}
\title{Combine objects of class \code{modeler}}
\usage{
\method{c}{modeler}(...)
}
\arguments{
\item{...}{Objects of class \code{modeler}, typically the result of calling \code{modeler()}.}
}
\value{
A \code{modeler} object.
}
\description{
Combine objects of class \code{modeler}. Use with caution, some
functions might not work as expected.
}
\examples{
library(flexFitR)
data(dt_potato)
mod_1 <- dt_potato |>
  modeler(
    x = DAP,
    y = Canopy,
    grp = Plot,
    fn = "fn_logistic",
    parameters = c(a = 0.199, t0 = 47.7, k = 100),
    subset = 1:2
  )
mod_2 <- dt_potato |>
  modeler(
    x = DAP,
    y = Canopy,
    grp = Plot,
    fn = "fn_lin_plat",
    parameters = c(t1 = 45, t2 = 80, k = 100),
    subset = 1:2
  )
mod <- c(mod_1, mod_2)
print(mod)
plot(mod, id = 1:2)
}
\author{
Johan Aparicio [aut]
}
