% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/utils_S3_plots.R
\name{plot.modeler}
\alias{plot.modeler}
\title{Plot an object of class \code{modeler}}
\usage{
\method{plot}{modeler}(
  x,
  id = NULL,
  type = 1,
  label_size = 4,
  base_size = 14,
  linewidth = 0.5,
  color = "red",
  color_points = "black",
  parm = NULL,
  n_points = 1000,
  title = NULL,
  add_points = FALSE,
  add_ci = TRUE,
  color_ci = "blue",
  color_pi = "red",
  add_ribbon_ci = FALSE,
  add_ribbon_pi = FALSE,
  color_ribbon_ci = "blue",
  color_ribbon_pi = "red",
  ...
)
}
\arguments{
\item{x}{An object of class \code{modeler}, typically the result of calling \code{modeler()}.}

\item{id}{An optional group ID to filter the data for plotting, useful for avoiding overcrowded plots.}

\item{type}{Numeric value (1-6) to specify the type of plot to generate. Default is 1.
\describe{
  \item{\code{type = 1}}{Plot of raw data with fitted curves.}
  \item{\code{type = 2}}{Plot of coefficients with confidence intervals.}
  \item{\code{type = 3}}{Plot of fitted curves, colored by group.}
  \item{\code{type = 4}}{Plot of fitted curves with confidence intervals.}
  \item{\code{type = 5}}{Plot of first derivative with confidence intervals.}
  \item{\code{type = 6}}{Plot of second derivative with confidence intervals.}
}}

\item{label_size}{Numeric value for the size of labels. Default is 4.}

\item{base_size}{Numeric value for the base font size in pts. Default is 14.}

\item{linewidth}{Numeric value specifying size of line geoms. Default is 0.5.}

\item{color}{Character string specifying the color for the fitted line when \code{type = 1}. Default is "red".}

\item{color_points}{Character string specifying the color for the raw data points when \code{type = 1}. Default is "black".}

\item{parm}{Character vector specifying the parameters to plot for \code{type = 2}. If \code{NULL}, all parameters are included.}

\item{n_points}{Numeric value specifying the number of points for interpolation along the x-axis. Default is 2000.}

\item{title}{Optional character string to add a title to the plot.}

\item{add_points}{Logical value indicating whether to add raw observations to the plot for \code{type = 3 and 4}. Default is \code{FALSE}.}

\item{add_ci}{Logical value indicating whether to add confidence intervals for \code{type = 4, 5, 6}. Default is \code{TRUE}.}

\item{color_ci}{Character string specifying the color of the confidence interval when \code{type = 4, 5, 6}. Default is "blue".}

\item{color_pi}{Character string specifying the color of the prediction interval when \code{type = 4}. Default is "red".}

\item{add_ribbon_ci}{Logical value indicating whether to add a ribbon for confidence intervals in \code{type = 4, 5, 6}. Default is \code{FALSE}.}

\item{add_ribbon_pi}{Logical value indicating whether to add a ribbon for prediction intervals in \code{type = 4}. Default is \code{FALSE}.}

\item{color_ribbon_ci}{Character string specifying the color of the ribbon (ci). Default is "blue".}

\item{color_ribbon_pi}{Character string specifying the color of the ribbon (pi). Default is "red".}

\item{...}{Additional graphical parameters for future extensions.}
}
\value{
A \code{ggplot} object representing the specified plot.
}
\description{
Creates several plots for an object of class \code{modeler}.
}
\examples{
library(flexFitR)
data(dt_potato)
# Example 1
mod_1 <- dt_potato |>
  modeler(
    x = DAP,
    y = Canopy,
    grp = Plot,
    fn = "fn_lin_plat",
    parameters = c(t1 = 45, t2 = 80, k = 0.9),
    subset = c(1:3)
  )
print(mod_1)
plot(mod_1, id = 1:2)
plot(mod_1, id = 1:3, type = 2, label_size = 10)
}
\author{
Johan Aparicio [aut]
}
