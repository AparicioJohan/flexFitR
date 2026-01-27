# Extract residuals from a `modeler` object

Extract residuals from a `modeler` object

## Usage

``` r
# S3 method for class 'modeler'
residuals(object, ...)
```

## Arguments

- object:

  An object of class \`modeler\`

- ...:

  Additional parameters for future functionality.

## Value

A numeric vector of residuals

## Author

Johan Aparicio \[aut\]

## Examples

``` r
library(flexFitR)
data(dt_potato)
mod_1 <- dt_potato |>
  modeler(
    x = DAP,
    y = Canopy,
    grp = Plot,
    fn = "fn_lin_plat",
    parameters = c(t1 = 45, t2 = 80, k = 0.9),
    subset = c(15, 2, 45)
  )
residuals(mod_1)
#>  [1]  0.000000e+00  0.000000e+00  4.300000e-01  1.436906e-09 -1.219902e-09
#>  [6] -6.980000e-01  3.490000e-01  3.490000e-01  0.000000e+00  0.000000e+00
#> [11]  1.329646e+00 -1.899494e+00  5.698481e-01  1.168496e-08  1.168496e-08
#> [16]  1.168496e-08  0.000000e+00  0.000000e+00  5.100000e-02  4.947580e-10
#> [21]  2.610250e-10 -5.021548e-10 -5.021548e-10 -5.021548e-10
```
