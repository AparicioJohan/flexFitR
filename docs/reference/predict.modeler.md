# Predict an object of class `modeler`

Generate model predictions from an object of class `modeler`. This
function allows for flexible prediction types, including point
predictions, area under the curve (AUC), first or second order
derivatives, and functions of the parameters.

## Usage

``` r
# S3 method for class 'modeler'
predict(
  object,
  x = NULL,
  id = NULL,
  type = c("point", "auc", "fd", "sd"),
  se_interval = c("confidence", "prediction"),
  n_points = 1000,
  formula = NULL,
  metadata = FALSE,
  parallel = FALSE,
  workers = NULL,
  ...
)
```

## Arguments

- object:

  An object of class `modeler`, typically the result of calling the
  [`modeler()`](https://apariciojohan.github.io/flexFitR/reference/modeler.md)
  function.

- x:

  A numeric value or vector specifying the points at which predictions
  are made. For `type = "auc"`, `x` must be a vector of length 2 that
  specifies the interval over which to calculate the AUC.

- id:

  Optional unique identifier to filter predictions by a specific group.
  Default is `NULL`.

- type:

  A character string specifying the type of prediction. Default is
  "point".

  `"point"`

  :   Predicts the value of `y` for the given `x`.

  `"auc"`

  :   Calculates the area under the curve (AUC) for the fitted model
      over the interval specified by `x`.

  `"fd"`

  :   Returns the first derivative (rate of change) of the model at the
      given `x` value(s).

  `"sd"`

  :   Returns the second derivative of the model at the given `x`
      value(s).

- se_interval:

  A character string specifying the type of interval for standard error
  calculation. Options are `"confidence"` (default) or `"prediction"`.
  Only works with "point" estimation.

- n_points:

  An integer specifying the number of points used to approximate the
  area under the curve (AUC) when `type = "auc"`. Default is `1000`.

- formula:

  A formula specifying a function of the parameters to be estimated
  (e.g., `~ b * 500`). Default is `NULL`.

- metadata:

  Logical. If `TRUE`, metadata is included with the predictions. Default
  is `FALSE`.

- parallel:

  Logical. If `TRUE` the prediction is performed in parallel. Default is
  `FALSE`. Use only when a large number of groups are being analyzed and
  `x` is a grid of values.

- workers:

  The number of parallel processes to use.
  [`parallel::detectCores()`](https://rdrr.io/r/parallel/detectCores.html)

- ...:

  Additional parameters for future functionality.

## Value

A `data.frame` containing the predicted values, their associated
standard errors, and optionally the metadata.

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
#>       3 0.5601 secs        100% 407.67 (id)
#> 
# Point Prediction
predict(mod_1, x = 45, type = "point", id = 2)
#> # A tibble: 1 × 5
#>     uid fn_name     x_new predicted.value std.error
#>   <dbl> <chr>       <dbl>           <dbl>     <dbl>
#> 1     2 fn_lin_plat    45            38.0     0.618
# AUC Prediction
predict(mod_1, x = c(0, 108), type = "auc", id = 2)
#> # A tibble: 1 × 6
#>     uid fn_name     x_min x_max predicted.value std.error
#>   <dbl> <chr>       <dbl> <dbl>           <dbl>     <dbl>
#> 1     2 fn_lin_plat     0   108           5990.      33.7
# First Derivative
predict(mod_1, x = 45, type = "fd", id = 2)
#> # A tibble: 1 × 5
#>     uid fn_name     x_new predicted.value std.error
#>   <dbl> <chr>       <dbl>           <dbl>     <dbl>
#> 1     2 fn_lin_plat    45            3.85    0.0738
# Second Derivative
predict(mod_1, x = 45, type = "sd", id = 2)
#> # A tibble: 1 × 5
#>     uid fn_name     x_new predicted.value std.error
#>   <dbl> <chr>       <dbl>           <dbl>     <dbl>
#> 1     2 fn_lin_plat    45    0.0000000324 0.0000239
# Function of the parameters
predict(mod_1, formula = ~ t2 - t1, id = 2)
#> # A tibble: 1 × 5
#>     uid fn_name     formula predicted.value std.error
#>   <dbl> <chr>       <chr>             <dbl>     <dbl>
#> 1     2 fn_lin_plat t2 - t1            26.0     0.522
```
