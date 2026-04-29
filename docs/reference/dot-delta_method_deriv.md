# Delta method for derivative estimation

Delta method for derivative estimation

## Usage

``` r
.delta_method_deriv(fit, x_new, which = "fd")
```

## Arguments

- fit:

  A fit object which is located inside a modeler object

- x_new:

  A vector of x values to evaluate the derivative.

- which:

  Can be "fd" for first-derivative or "sd" for second-derivative.

## Value

A data.frame of the evaluated values.

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
#>       3 0.9682 secs        100% 407.67 (id)
#> 
# First Derivative
predict(mod_1, x = 45, type = "fd", id = 2)
#> # A tibble: 1 × 5
#>     uid fn_name     x_new predicted.value std.error
#>   <dbl> <chr>       <dbl>           <dbl>     <dbl>
#> 1     2 fn_lin_plat    45            3.85    0.0738
```
