# Subset an object of class `modeler`

Subset an object of class `modeler`

## Usage

``` r
# S3 method for class 'modeler'
subset(x, id = NULL, ...)
```

## Arguments

- x:

  An object of class `modeler`, typically the result of calling
  [`modeler()`](https://apariciojohan.github.io/flexFitR/reference/modeler.md).

- id:

  Unique identifier to filter a `modeler` object by a specific group.
  Default is `NULL`.

- ...:

  Additional parameters for future functionality.

## Value

A `modeler` object.

## Author

Johan Aparicio \[aut\]

## Examples

``` r
library(flexFitR)
data(dt_potato)
mod <- dt_potato |>
  modeler(
    x = DAP,
    y = Canopy,
    grp = Plot,
    fn = "fn_logistic",
    parameters = c(a = 0.199, t0 = 47.7, k = 100),
    subset = 1:2
  )
print(mod)
#> 
#> Call:
#> Canopy ~ fn_logistic(DAP, a, t0, k) 
#> 
#> Residuals (`Standardized`):
#>     Min.  1st Qu.   Median     Mean  3rd Qu.     Max. 
#> -1.90574 -0.48414 -0.02140 -0.19314  0.07097  1.17113 
#> 
#> Optimization Results `head()`:
#>  uid     a   t0     k  sse
#>    1 0.215 50.7  99.9 15.7
#>    2 0.198 48.3 100.0 22.4
#> 
#> Metrics:
#>  Groups      Timing Convergence Iterations
#>       2 0.3946 secs        100% 550.5 (id)
#> 
mod_new <- subset(mod, id = 2)
print(mod_new)
#> 
#> Call:
#> Canopy ~ fn_logistic(DAP, a, t0, k) 
#> 
#> Residuals (`Standardized`):
#>     Min.  1st Qu.   Median     Mean  3rd Qu.     Max. 
#> -1.53735 -0.60292  0.01037 -0.19574  0.07725  1.17113 
#> 
#> Optimization Results `head()`:
#>  uid     a   t0   k  sse
#>    2 0.198 48.3 100 22.4
#> 
#> Metrics:
#>  Groups      Timing Convergence Iterations
#>       1 0.3946 secs        100%   532 (id)
#> 
```
