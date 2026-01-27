# Compare performance of different models

Computes indices of model performance for different models at once and
hence allows comparison of indices across models.

## Usage

``` r
performance(..., metrics = "all", metadata = FALSE, digits = 2)
```

## Arguments

- ...:

  Multiple model objects (only of class \`modeler\`).

- metrics:

  Can be "all" or a character vector of metrics to be computed (one or
  more of "logLik", "AIC", "AICc", "BIC", "Sigma", "SSE", "MAE", "MSE",
  "RMSE", "R2"). "all" by default.

- metadata:

  Logical. If `TRUE`, metadata is included with the performance metrics.
  Default is `FALSE`.

- digits:

  An integer. The number of decimal places to round the output. Default
  is 2.

## Value

A data.frame with performance metrics for models in (...).

## Examples

``` r
library(flexFitR)
data(dt_potato)
# Model 1
mod_1 <- dt_potato |>
  modeler(
    x = DAP,
    y = Canopy,
    grp = Plot,
    fn = "fn_lin_plat",
    parameters = c(t1 = 45, t2 = 80, k = 90),
    subset = 40
  )
print(mod_1)
#> 
#> Call:
#> Canopy ~ fn_lin_plat(DAP, t1, t2, k) 
#> 
#> Residuals (`Standardized`):
#>       Min.    1st Qu.     Median       Mean    3rd Qu.       Max. 
#> -1.779e+00  0.000e+00  2.000e-08  1.000e-08  1.334e-01  1.245e+00 
#> 
#> Optimization Results `head()`:
#>  uid   t1   t2   k    sse
#>   40 34.8 60.6 100 0.0545
#> 
#> Metrics:
#>  Groups      Timing Convergence Iterations
#>       1 0.3725 secs        100%   509 (id)
#> 
# Model 2
mod_2 <- dt_potato |>
  modeler(
    x = DAP,
    y = Canopy,
    grp = Plot,
    fn = "fn_logistic",
    parameters = c(a = 0.199, t0 = 47.7, k = 100),
    subset = 40
  )
print(mod_2)
#> 
#> Call:
#> Canopy ~ fn_logistic(DAP, a, t0, k) 
#> 
#> Residuals (`Standardized`):
#>     Min.  1st Qu.   Median     Mean  3rd Qu.     Max. 
#> -1.56658 -0.63135  0.03151 -0.18197  0.10167  1.20076 
#> 
#> Optimization Results `head()`:
#>  uid     a   t0    k  sse
#>   40 0.199 47.7 99.8 37.4
#> 
#> Metrics:
#>  Groups      Timing Convergence Iterations
#>       1 0.3395 secs        100%   582 (id)
#> 
# Model 3
mod_3 <- dt_potato |>
  modeler(
    x = DAP,
    y = Canopy,
    grp = Plot,
    fn = "fn_lin",
    parameters = c(m = 20, b = 2),
    subset = 40
  )
print(mod_3)
#> 
#> Call:
#> Canopy ~ fn_lin(DAP, m, b) 
#> 
#> Residuals (`Standardized`):
#>    Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
#> -1.1490 -0.6400 -0.2358  0.0000  0.8683  1.3178 
#> 
#> Optimization Results `head()`:
#>  uid    m     b  sse
#>   40 1.29 -17.8 2644
#> 
#> Metrics:
#>  Groups      Timing Convergence Iterations
#>       1 0.2909 secs        100%   251 (id)
#> 
performance(mod_1, mod_2, mod_3, metrics = c("AIC", "AICc", "BIC", "Sigma"))
#>         fn_name uid df nobs p   AIC  AICc   BIC Sigma
#> 1      fn_lin_3  40  3    8 2 75.11 81.11 75.35 20.99
#> 2 fn_lin_plat_1  40  4    8 3 -9.21  4.12 -8.89  0.10
#> 3 fn_logistic_2  40  4    8 3 43.04 56.37 43.35  2.73
```
