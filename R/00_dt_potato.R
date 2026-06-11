#' Drone-derived data from a potato breeding trial (2020)
#'
#' Canopy and Green Leaf Index for a potato trial arranged in a p-rep design.
#'
#' @format A tibble with 1372 rows and 8 variables:
#' \describe{
#'   \item{Trial}{chr trial name}
#'   \item{Plot}{dbl denoting the unique plot id}
#'   \item{Row}{dbl denoting the row coordinate}
#'   \item{Range}{dbl denoting range coordinate}
#'   \item{gid}{chr denoting the genotype id}
#'   \item{DAP}{dbl denoting Days after planting}
#'   \item{Canopy}{dbl Canopy UAV-Derived}
#'   \item{GLI}{dbl Green Leaf Index UAV-Derived}
#' }
#' @source UW - Potato Breeding Program 2020
"dt_potato"

#' Drone-derived data from a potato breeding trial (2022)
#'
#' Ground cover and plant height for a potato trial arranged in a p-rep design.
#'
#' @format A tibble with 1764 rows and 9 variables:
#' \describe{
#'   \item{Trial}{chr trial name}
#'   \item{Plot}{dbl denoting the unique plot id}
#'   \item{Row}{dbl denoting the row coordinate}
#'   \item{Range}{dbl denoting range coordinate}
#'   \item{gid}{chr denoting the genotype id}
#'   \item{DAP}{dbl denoting Days after planting}
#'   \item{GC}{dbl UAV-Derived Ground Cover}
#'   \item{PH}{dbl UAV-Derived Plant Height}
#'   \item{Yield}{Total Yield}
#' }
#' @source UW - Potato Breeding Program 2022
"dt_potato_22"
