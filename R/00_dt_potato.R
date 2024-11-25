#' Drone-derived data from a potato breeding trial
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
#' @source UW - Potato Breeding Program
"dt_potato"
