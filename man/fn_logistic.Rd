% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/99_growth_curves.R
\name{fn_logistic}
\alias{fn_logistic}
\title{Logistic function}
\usage{
fn_logistic(t, a, t0, k)
}
\arguments{
\item{t}{A numeric vector of input values (e.g., time).}

\item{a}{The growth rate (steepness of the curve). Higher values lead to a steeper rise.}

\item{t0}{The time of the inflection point (midpoint of the transition).}

\item{k}{The upper asymptote or plateau (maximum value as \code{t -> Inf}).}
}
\value{
A numeric vector of the same length as \code{t}, representing the logistic function values.
}
\description{
A standard logistic function commonly used to model sigmoidal growth. The
curve rises from near zero to a maximum value \code{k}, with inflection point
at \code{t0} and growth rate \code{a}.
}
\details{
\if{html}{
\deqn{
f(t; a, t0, k) = \frac{k}{1 + e^{-a(t - t_0)}}
}
}

This is a classic sigmoid (S-shaped) curve that is symmetric around the
inflection point \code{t0}.
}
\examples{
library(flexFitR)
plot_fn(
  fn = "fn_logistic",
  params = c(a = 0.199, t0 = 47.7, k = 100),
  interval = c(0, 108),
  n_points = 2000
)
}
