# Extract Log-Likelihood for an object of class `modeler`

logLik for an object of class `modeler`

## Usage

``` r
# S3 method for class 'modeler'
logLik(object, ...)
```

## Arguments

- object:

  An object inheriting from class `modeler` resulting of executing the
  function
  [`modeler()`](https://apariciojohan.github.io/flexFitR/reference/modeler.md)

- ...:

  Further parameters. For future improvements.

## Value

A `tibble` with the Log-Likelihood for the fitted models.

## Author

Johan Aparicio \[aut\]

## Examples

``` r
library(flexFitR)
dt <- data.frame(X = 1:6, Y = c(12, 16, 44, 50, 95, 100))
mo_1 <- modeler(dt, X, Y, fn = "fn_lin", param = c(m = 10, b = -5))
plot(mo_1)

logLik(mo_1)
#>   uid fn_name    logLik df nobs p
#> 1   1  fn_lin -21.45745  3    6 2
```
