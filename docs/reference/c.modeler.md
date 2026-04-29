# Combine objects of class `modeler`

Combine objects of class `modeler`. Use with caution, some functions
might not work as expected.

## Usage

``` r
# S3 method for class 'modeler'
c(...)
```

## Arguments

- ...:

  Objects of class `modeler`, typically the result of calling
  [`modeler()`](https://apariciojohan.github.io/flexFitR/reference/modeler.md).

## Value

A `modeler` object.

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
    subset = 1:2
  )
mod_2 <- dt_potato |>
  modeler(
    x = DAP,
    y = Canopy,
    grp = Plot,
    fn = "fn_lin_plat",
    parameters = c(t1 = 45, t2 = 80, k = 100),
    subset = 1:2
  )
mod <- c(mod_1, mod_2)
print(mod)
#> 
#> Call:
#> Canopy ~ fn_lin_plat(DAP, t1, t2, k) | uid (2) 
#> Canopy ~ fn_logistic(DAP, a, t0, k) | uid (2) 
#> 
#> Residuals (`Standardized`):
#>     Min.  1st Qu.   Median     Mean  3rd Qu.     Max. 
#> -1.90574 -0.04114  0.00000 -0.02669  0.02561  2.23607 
#> 
#> Optimization Results `head()`:
#>  uid coefficient solution std.error t value Pr(>|t|)
#>    1           a    0.215    0.0115    18.7 7.98e-06
#>    1          t0   50.683    0.4082   124.2 6.43e-10
#>    1           k   99.895    1.0399    96.1 2.32e-09
#>    2           a    0.198    0.0119    16.7 1.42e-05
#> 
#> Metrics:
#>  Groups Timing Convergence Iterations
#>       2 1.0624        100%   519 (id)
#> 
plot(mod, id = 1:2)
```
