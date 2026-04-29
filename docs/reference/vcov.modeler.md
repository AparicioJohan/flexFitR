# Variance-Covariance matrix for an object of class `modeler`

Extract the variance-covariance matrix for the parameter estimates from
an object of class `modeler`.

## Usage

``` r
# S3 method for class 'modeler'
vcov(object, id = NULL, ...)
```

## Arguments

- object:

  An object of class `modeler`, typically the result of calling the
  [`modeler()`](https://apariciojohan.github.io/flexFitR/reference/modeler.md)
  function.

- id:

  An optional unique identifier to filter by a specific group. Default
  is `NULL`.

- ...:

  Additional parameters for future functionality.

## Value

A list of matrices, where each matrix represents the variance-covariance
matrix of the estimated parameters for each group or fit.

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
#>       3 0.8936 secs        100% 407.67 (id)
#> 
vcov(mod_1)
#> $`2`
#>               t1          t2            k
#> t1  5.934998e-02 -0.03183713 5.554275e-06
#> t2 -3.183713e-02  0.14965142 9.863943e-02
#> k   5.554275e-06  0.09863943 3.800529e-01
#> attr(,"fn_name")
#> [1] "fn_lin_plat"
#> 
#> $`15`
#>               t1          t2            k
#> t1  3.082693e-02 -0.03338909 8.560487e-07
#> t2 -3.338909e-02  0.10016820 1.945368e-02
#> k   8.560487e-07  0.01945368 6.104608e-02
#> attr(,"fn_name")
#> [1] "fn_lin_plat"
#> 
#> $`45`
#>               t1            t2            k
#> t1  6.081675e-05 -4.407386e-05 7.269796e-11
#> t2 -4.407386e-05  1.208133e-04 4.577090e-05
#> k   7.269796e-11  4.577090e-05 1.734000e-04
#> attr(,"fn_name")
#> [1] "fn_lin_plat"
#> 
```
