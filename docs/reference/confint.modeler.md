# Confidence intervals for a modeler object

Extract confidence intervals for the estimated parameters of an object
of class `modeler`.

## Usage

``` r
# S3 method for class 'modeler'
confint(object, parm = NULL, level = 0.95, id = NULL, ...)
```

## Arguments

- object:

  An object of class `modeler`, typically the result of calling the
  [`modeler()`](https://apariciojohan.github.io/flexFitR/reference/modeler.md)
  function.

- parm:

  A character vector specifying which parameters should have confidence
  intervals calculated. If `NULL`, confidence intervals for all
  parameters are returned. Default is `NULL`.

- level:

  A numeric value indicating the confidence level for the intervals.
  Default is 0.95, corresponding to a 95% confidence interval.

- id:

  An optional unique identifier to filter by a specific group. Default
  is `NULL`.

- ...:

  Additional parameters for future functionality.

## Value

A `tibble` containing the lower and upper confidence limits for each
specified parameter.

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
    subset = c(15, 35, 45)
  )
print(mod_1)
#> 
#> Call:
#> Canopy ~ fn_lin_plat(DAP, t1, t2, k) 
#> 
#> Residuals (`Standardized`):
#>     Min.  1st Qu.   Median     Mean  3rd Qu.     Max. 
#> -1.63103  0.00000  0.00000  0.22818  0.02056  2.23607 
#> 
#> Optimization Results `head()`:
#>  uid   t1   t2     k    sse
#>   15 38.4 70.1  99.7 0.9157
#>   35 47.2 68.7 100.0 1.8971
#>   45 38.3 64.7 100.0 0.0026
#> 
#> Metrics:
#>  Groups      Timing Convergence  Iterations
#>       3 0.8383 secs        100% 354.67 (id)
#> 
confint(mod_1)
#> # A tibble: 9 × 7
#>     uid fn_name     coefficient solution std.error ci_lower ci_upper
#>   <dbl> <chr>       <chr>          <dbl>     <dbl>    <dbl>    <dbl>
#> 1    15 fn_lin_plat t1              38.4   0.176       37.9     38.8
#> 2    15 fn_lin_plat t2              70.1   0.316       69.3     70.9
#> 3    15 fn_lin_plat k               99.7   0.247       99.0    100. 
#> 4    35 fn_lin_plat t1              47.2 NaN          NaN      NaN  
#> 5    35 fn_lin_plat t2              68.7 NaN          NaN      NaN  
#> 6    35 fn_lin_plat k              100.0   0.356       99.1    101. 
#> 7    45 fn_lin_plat t1              38.3   0.00780     38.2     38.3
#> 8    45 fn_lin_plat t2              64.7   0.0110      64.6     64.7
#> 9    45 fn_lin_plat k              100.    0.0132     100.0    100. 
```
