# Coefficients for an object of class `modeler`

Extract the estimated coefficients from an object of class `modeler`.

## Usage

``` r
# S3 method for class 'modeler'
coef(object, id = NULL, metadata = FALSE, df = FALSE, ...)
```

## Arguments

- object:

  An object of class `modeler`, typically the result of calling the
  [`modeler()`](https://apariciojohan.github.io/flexFitR/reference/modeler.md)
  function.

- id:

  An optional unique identifier to filter by a specific group. Default
  is `NULL`.

- metadata:

  Logical. If `TRUE`, metadata is included along with the coefficients.
  Default is `FALSE`.

- df:

  Logical. If `TRUE`, the degrees of freedom for the fitted model are
  returned alongside the coefficients. Default is `FALSE`.

- ...:

  Additional parameters for future functionality.

## Value

A `data.frame` containing the model's estimated coefficients, standard
errors, and optional metadata or degrees of freedom if specified.

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
print(mod_1)
#> 
#> Call:
#> Canopy ~ fn_lin_plat(DAP, t1, t2, k) 
#> 
#> Residuals (`Standardized`):
#>    Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
#> -1.7789  0.0000  0.0000  0.1350  0.1334  2.2361 
#> 
#> Optimization Results `head()`:
#>  uid   t1   t2     k    sse
#>    2 35.1 61.1 100.0 5.7008
#>   15 38.4 70.1  99.7 0.9157
#>   45 38.3 64.7 100.0 0.0026
#> 
#> Metrics:
#>  Groups      Timing Convergence  Iterations
#>       3 1.2016 secs        100% 407.67 (id)
#> 
coef(mod_1, id = 2)
#> # A tibble: 3 × 7
#>     uid fn_name     coefficient solution std.error `t value` `Pr(>|t|)`
#>   <dbl> <chr>       <chr>          <dbl>     <dbl>     <dbl>      <dbl>
#> 1     2 fn_lin_plat t1              35.1     0.244      144.   3.04e-10
#> 2     2 fn_lin_plat t2              61.1     0.387      158.   1.93e-10
#> 3     2 fn_lin_plat k              100.0     0.616      162.   1.69e-10
```
