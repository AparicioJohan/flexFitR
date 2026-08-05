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



#' Soybean canopy cover from UAV imagery year 2022 (Keller et all., 2026)
#'
#' @description
#' Canopy cover time series for 78 soybean plots grown at the ETH Zurich Field
#' Phenotyping Platform (FIP) site in Eschikon, Switzerland, during the 2022
#' season. Canopy cover was derived from high-throughput field images and is
#' expressed as the fraction of ground covered by the crop.
#'
#' @format A tibble with 2,793 rows and 7 variables:
#' \describe{
#'   \item{location}{Character. Trial site. Always \code{"Eschikon"}.}
#'   \item{Year}{Numeric. Growing season. Always \code{2022}.}
#'   \item{sowing_date}{Date. Date of sowing (\code{2022-04-21}).}
#'   \item{harvest_date}{Date. Date of harvest (\code{2022-09-23}).}
#'   \item{plot.UID}{Character. Unique plot identifier, 78 levels.}
#'   \item{time_since_sowing}{Numeric. Days elapsed since sowing, ranging from
#'     0 to 151 over 30 measurement dates.}
#'   \item{Canopy_cover}{Numeric. Fraction of ground covered by the canopy,
#'     ranging from 0 to 0.95. Contains 59 missing values.}
#' }
#'
#' @details
#'
#' Every plot includes an anchor observation at \code{time_since_sowing = 0}
#' with \code{Canopy_cover = 0}, added with
#' \code{\link{series_mutate}(add_zero = TRUE)} when the dataset was assembled.
#'
#' @source
#' Derived from the \code{Soybean_CanopyCover_data.csv} file of the FIP 1.0
#' soybean data collection, subset to the 2022 season:
#' \url{https://www.research-collection.ethz.ch/entities/researchdata/2f3b96fb-7d41-4851-ae72-3781a3df2e8f}
#'
#' @references
#' Keller, B., Kirchgessner, N., Oppliger, C., Kronenberg, L., Roth, L.,
#' Zumsteg, O., Corrado, S., Liebisch, F., Aasen, H., Storni, N., Tschurr, F.,
#' Zellweger, H., Betrix, C. A., Barendregt, C., Hund, A., & Walter, A. (2026).
#' FIP 1.0 soybean data: Insights on soybean growth from eight years of
#' high-throughput image field phenotyping. \emph{Scientific Data}, 13(1), 476.
#' \doi{10.1038/s41597-026-06663-z}
#'
#' @examples
#' library(flexFitR)
#' data(dt_soybean_22)
#' head(dt_soybean_22)
#'
#' # Temporal evolution of all plots
#' explorer(dt_soybean_22, x = time_since_sowing, y = Canopy_cover, id = plot.UID) |>
#'   plot(type = "evolution", add_avg = TRUE)
"dt_soybean_22"

