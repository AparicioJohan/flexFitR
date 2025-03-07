% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/00_dt_potato.R
\docType{data}
\name{dt_potato}
\alias{dt_potato}
\title{Drone-derived data from a potato breeding trial}
\format{
A tibble with 1372 rows and 8 variables:
\describe{
  \item{Trial}{chr trial name}
  \item{Plot}{dbl denoting the unique plot id}
  \item{Row}{dbl denoting the row coordinate}
  \item{Range}{dbl denoting range coordinate}
  \item{gid}{chr denoting the genotype id}
  \item{DAP}{dbl denoting Days after planting}
  \item{Canopy}{dbl Canopy UAV-Derived}
  \item{GLI}{dbl Green Leaf Index UAV-Derived}
}
}
\source{
UW - Potato Breeding Program
}
\usage{
dt_potato
}
\description{
Canopy and Green Leaf Index for a potato trial arranged in a p-rep design.
}
\keyword{datasets}
