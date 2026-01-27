# Akaike's An Information Criterion for an object of class `modeler`

Generic function calculating Akaike's ‘An Information Criterion’ for
fitted model object of class `modeler`.

## Usage

``` r
# S3 method for class 'modeler'
AIC(object, ..., k = 2)

# S3 method for class 'modeler'
BIC(object, ...)
```

## Arguments

- object:

  An object inheriting from class `modeler` resulting of executing the
  function
  [`modeler()`](https://apariciojohan.github.io/flexFitR/reference/modeler.md)

- ...:

  Further parameters. For future improvements.

- k:

  Numeric, the penalty per parameter to be used; the default k = 2 is
  the classical AIC.

## Value

A `tibble` with columns giving the corresponding AIC and BIC.

## Author

Johan Aparicio \[aut\]

## Examples

``` r
library(flexFitR)
dt <- data.frame(X = 1:6, Y = c(12, 16, 44, 50, 95, 100))
mo_1 <- modeler(dt, X, Y, fn = "fn_lin", param = c(m = 10, b = -5))
mo_2 <- modeler(dt, X, Y, fn = "fn_quad", param = c(a = 1, b = 10, c = 5))
AIC(mo_1)
#>   uid fn_name    logLik df nobs p     AIC
#> 1   1  fn_lin -21.45745  3    6 2 48.9149
AIC(mo_2)
#>   uid fn_name    logLik df nobs p      AIC
#> 1   1 fn_quad -21.00014  4    6 3 50.00028
BIC(mo_1)
#>   uid fn_name    logLik df nobs p      BIC
#> 1   1  fn_lin -21.45745  3    6 2 48.29017
BIC(mo_2)
#>   uid fn_name    logLik df nobs p      BIC
#> 1   1 fn_quad -21.00014  4    6 3 49.16732
```
