% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/14_tangent.R
\name{compute_tangent}
\alias{compute_tangent}
\title{Compute tangent line(s) from a \code{modeler} object}
\usage{
compute_tangent(object, x = NULL, id = NULL)
}
\arguments{
\item{object}{A fitted object of class \code{modeler}, created by \code{\link{modeler}()}.}

\item{x}{A numeric vector of x-values at which to compute tangent lines.
A data.frame is also accepted with columns <uid, x>.}

\item{id}{Optional vector of \code{uid}s indicating which groups to compute tangent lines for. If \code{NULL}, all groups are used.}
}
\value{
A tibble with one row per tangent line and the following columns:
\itemize{
  \item \code{uid}: unique identifier of the group.
  \item \code{fn_name}: Name of the fitted function.
  \item \code{x}: x-value where the tangent line is evaluated.
  \item \code{y}: Fitted y-value at x.
  \item \code{slope}: First derivative (slope of tangent) at x.
  \item \code{intercept}: y-intercept of the tangent line.
}
}
\description{
Computes the slope and intercept of the tangent line(s) to a fitted curve
at one or more specified x-values.
}
\examples{
library(flexFitR)
library(ggplot2)
data(dt_potato)
mod <- dt_potato |>
  modeler(
    x = DAP,
    y = Canopy,
    grp = Plot,
    fn = "fn_logistic",
    parameters = c(a = 4, t0 = 40, k = 100),
    subset = 2
  )
plot(mod)
tl <- compute_tangent(mod, x = c(48.35, 65))
print(tl)
plot(mod) +
  geom_abline(
    data = tl,
    mapping = aes(slope = slope, intercept = intercept),
    linetype = 2,
    color = "blue"
  ) +
  geom_point(
    data = tl,
    mapping = aes(x = x, y = y),
    shape = 8,
    color = "blue",
    size = 2
  )
}
