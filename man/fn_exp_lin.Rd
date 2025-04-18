% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/99_growth_curves.R
\name{fn_exp_lin}
\alias{fn_exp_lin}
\title{Exponential-linear function}
\usage{
fn_exp_lin(t, t1, t2, alpha, beta)
}
\arguments{
\item{t}{A numeric vector of input values (e.g., time).}

\item{t1}{The onset time of the response. The function is 0 for all values less than \code{t1}.}

\item{t2}{The transition time between exponential and linear phases. Must be greater than \code{t1}.}

\item{alpha}{The exponential growth rate during the exponential phase.}

\item{beta}{The slope of the linear phase after \code{t2}.}
}
\value{
A numeric vector of the same length as \code{t}, representing the function values.
}
\description{
A piecewise function that models a response with an initial exponential
growth phase followed by a linear phase. Commonly used to describe processes
with rapid early increases that slow into a linear trend, while maintaining
continuity.
}
\details{
\if{html}{
\deqn{
f(t; t_1, t_2, \alpha, \beta) =
\begin{cases}
0 & \text{if } t < t_1 \\
e^{\alpha \cdot (t - t_1)} - 1 & \text{if } t_1 \leq t \leq t_2 \\
\beta \cdot (t - t_2) + \left(e^{\alpha \cdot (t_2 - t_1)} - 1\right) & \text{if } t > t_2
\end{cases}
}
}

The exponential segment starts from 0 at \code{t1}, and the linear segment
continues smoothly from the end of the exponential part. This ensures value
continuity at \code{t2}, but not necessarily smoothness in slope.
}
\examples{
library(flexFitR)
plot_fn(
  fn = "fn_exp_lin",
  params = c(t1 = 35, t2 = 55, alpha = 1 / 20, beta = -1 / 40),
  interval = c(0, 108),
  n_points = 2000,
  auc_label_size = 3
)
}
