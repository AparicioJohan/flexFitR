% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/03_metrics.R
\name{plot.performance}
\alias{plot.performance}
\title{Plot an object of class \code{performance}}
\usage{
\method{plot}{performance}(
  x,
  id = NULL,
  type = 1,
  rescale = FALSE,
  linewidth = 1,
  base_size = 12,
  return_table = FALSE,
  ...
)
}
\arguments{
\item{x}{An object of class \code{performance}, typically the result of calling \code{performance()}.}

\item{id}{An optional group ID to filter the data for plotting, useful for avoiding overcrowded plots.
This argument is not used when type = 2.}

\item{type}{Numeric value (1-3) to specify the type of plot to generate. Default is 1.
\describe{
  \item{\code{type = 1}}{Radar plot by uid}
  \item{\code{type = 2}}{Radar plot averaging}
  \item{\code{type = 3}}{Line plot by model-metric}
  \item{\code{type = 4}}{Ranking plot by model}
}}

\item{rescale}{Logical. If \code{TRUE}, metrics in type 3 plot are (0, 1) rescaled to improve interpretation.
Higher values are better models. \code{FALSE} by default.}

\item{linewidth}{Numeric value specifying size of line geoms.}

\item{base_size}{Numeric value for the base font size in pts. Default is 12}

\item{return_table}{Logical. If \code{TRUE}, table to generate the plot is
returned. \code{FALSE} by default.}

\item{...}{Additional graphical parameters for future extensions.}
}
\value{
A \code{ggplot} object representing the specified plot.
}
\description{
Creates plots for an object of class \code{performance}
}
\examples{
library(flexFitR)
data(dt_potato)
# Model 1
mod_1 <- dt_potato |>
  modeler(
    x = DAP,
    y = Canopy,
    grp = Plot,
    fn = "fn_lin_plat",
    parameters = c(t1 = 45, t2 = 80, k = 90),
    subset = 40
  )
# Model 2
mod_2 <- dt_potato |>
  modeler(
    x = DAP,
    y = Canopy,
    grp = Plot,
    fn = "fn_logistic",
    parameters = c(a = 0.199, t0 = 47.7, k = 100),
    subset = 40
  )
# Model 3
mod_3 <- dt_potato |>
  modeler(
    x = DAP,
    y = Canopy,
    grp = Plot,
    fn = "fn_lin",
    parameters = c(m = 20, b = 2),
    subset = 40
  )
plot(performance(mod_1, mod_2, mod_3), type = 1)
plot(performance(mod_1, mod_2, mod_3, metrics = c("AICc", "BIC")), type = 3)
}
\author{
Johan Aparicio [aut]
}
