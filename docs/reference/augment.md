# Augment a `modeler` object with influence diagnostics

This function computes various influence diagnostics, including
standardized residuals, studentized residuals, and Cook's distance, for
an object of class `modeler`.

## Usage

``` r
augment(x, id = NULL, metadata = TRUE, ...)
```

## Arguments

- x:

  An object of class `modeler`.

- id:

  Optional unique identifier to filter by a specific group. Default is
  `NULL`.

- metadata:

  Logical. If `TRUE`, metadata is included with the predictions. Default
  is `FALSE`

- ...:

  Additional parameters for future functionality.

## Value

A tibble containing the following columns:

- uid:

  Unique identifier for the group.

- fn_name:

  Function name associated with the model.

- x:

  Predictor variable values.

- y:

  Observed response values.

- .fitted:

  Fitted values from the model.

- .resid:

  Raw residuals (observed - fitted).

- .hat:

  Leverage values for each observation.

- .cooksd:

  Cook's distance for each observation.

- .std.resid:

  Standardized residuals.

- .stud.resid:

  Studentized residuals.

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
    fn = "fn_logistic",
    parameters = c(a = 0.199, t0 = 47.7, k = 100),
    subset = 2
  )
print(mod_1)
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
#>       1 0.2931 secs        100%   532 (id)
#> 
augment(mod_1)
#> # A tibble: 8 × 10
#>     uid fn_name         x      y  .fitted   .resid      .hat  .cooksd .std.resid
#>   <dbl> <chr>       <dbl>  <dbl>    <dbl>    <dbl>     <dbl>    <dbl>      <dbl>
#> 1     2 fn_logistic     0   0     0.00684 -0.00684   3.42e-6 1.19e-11   -0.00323
#> 2     2 fn_logistic    29   0     2.11    -2.11      4.96e-2 1.82e- 2   -0.997  
#> 3     2 fn_logistic    36   4.70  7.95    -3.25      2.82e-1 4.32e- 1   -1.54   
#> 4     2 fn_logistic    42  24.6  22.1      2.48      7.16e-1 4.05e+ 0    1.17   
#> 5     2 fn_logistic    56  81.0  82.0     -0.997     9.54e-1 3.39e+ 1   -0.472  
#> 6     2 fn_logistic    76 100    99.5      0.460     3.13e-1 1.05e- 2    0.218  
#> 7     2 fn_logistic    92 100    99.9      0.0645    3.42e-1 2.45e- 4    0.0305 
#> 8     2 fn_logistic   100 100    99.9      0.0507    3.43e-1 1.53e- 4    0.0240 
#> # ℹ 1 more variable: .stud.resid <dbl>
```
