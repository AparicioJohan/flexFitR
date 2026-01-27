# Inverse prediction from a `modeler` object

Computes the x-value at which a fitted model reaches a user-specified
response value (y-value).

## Usage

``` r
# S3 method for class 'modeler'
inverse_predict(
  object,
  y,
  id = NULL,
  interval = NULL,
  tol = 1e-06,
  resolution = 1000,
  ...
)
```

## Arguments

- object:

  A fitted object of class `modeler`.

- y:

  A numeric scalar giving the target y-value for which to compute the
  corresponding x.

- id:

  Optional vector of `uid`s for which to perform inverse prediction. If
  `NULL`, all groups are used.

- interval:

  Optional numeric vector of length 2 specifying the interval in which
  to search for the root. If `NULL`, the interval is inferred from the
  range of the observed x-values.

- tol:

  Numerical tolerance passed to
  [`uniroot`](https://rdrr.io/r/stats/uniroot.html) for root-finding
  accuracy.

- resolution:

  Integer. Number of grid points used to scan the interval.

- ...:

  Additional parameters for future functionality.

## Value

A `tibble` with one row per group, containing:

- `uid` – unique identifier of the group,

- `fn_name` – the name of the fitted function,

- `lower` and `upper` – the search interval used,

- `y` – the predicted y-value (from the function at the root),

- `x` – the x-value at which the function reaches `y`.

## Details

The function uses numeric root-finding to solve `f(t, ...params) = y`.
If no root is found in the interval, `NA` is returned.

## See also

[`predict.modeler`](https://apariciojohan.github.io/flexFitR/reference/predict.modeler.md),
[`uniroot`](https://rdrr.io/r/stats/uniroot.html)

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
#>       3 0.9536 secs        100% 407.67 (id)
#> 
inverse_predict(mod_1, y = 50)
#> # A tibble: 3 × 6
#>     uid fn_name     lower upper     y     x
#>   <dbl> <chr>       <dbl> <dbl> <dbl> <dbl>
#> 1     2 fn_lin_plat     0   100    50  48.1
#> 2    15 fn_lin_plat     0   100    50  54.3
#> 3    45 fn_lin_plat     0   100    50  51.5
inverse_predict(mod_1, y = 75, interval = c(20, 80))
#> # A tibble: 3 × 6
#>     uid fn_name     lower upper     y     x
#>   <dbl> <chr>       <dbl> <dbl> <dbl> <dbl>
#> 1     2 fn_lin_plat    20    80    75  54.6
#> 2    15 fn_lin_plat    20    80    75  62.3
#> 3    45 fn_lin_plat    20    80    75  58.1
```
