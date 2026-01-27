# Extract fitted values from a `modeler` object

Extract fitted values from a `modeler` object

## Usage

``` r
# S3 method for class 'modeler'
fitted(object, ...)
```

## Arguments

- object:

  An object of class \`modeler\`

- ...:

  Additional parameters for future functionality.

## Value

A numeric vector of fitted values.

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
fitted(mod_1)
#>  [1]   0.000000   0.000000   0.000000  11.449000  55.376000  99.678000
#>  [7]  99.678000  99.678000   0.000000   0.000000   3.366354  26.482494
#> [13]  80.420152 100.000000 100.000000 100.000000   0.000000   0.000000
#> [19]   0.000000  14.184000  67.222000 100.000000 100.000000 100.000000
```
