# Delta method generic function

Delta method generic function

## Usage

``` r
.delta_method_gen(fit, formula)
```

## Arguments

- fit:

  A fit object which is located inside a modeler object

- formula:

  A formula specifying a function of the parameters to be estimated
  (e.g., `~ b * 500`). Default is `NULL`.

## Value

A data.frame of the evaluated formula.

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
#>       3 1.0721 secs        100% 407.67 (id)
#> 
# Function of the parameters
predict(mod_1, formula = ~ t2 - t1, id = 2)
#> # A tibble: 1 × 5
#>     uid fn_name     formula predicted.value std.error
#>   <dbl> <chr>       <chr>             <dbl>     <dbl>
#> 1     2 fn_lin_plat t2 - t1            26.0     0.522
```
