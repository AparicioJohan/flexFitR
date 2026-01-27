# Quadratic function

A standard quadratic function of the form `f(t) = a * t^2 + b * t + c`,
where `a` controls curvature, `b` is the linear coefficient, and `c` is
the intercept.

## Usage

``` r
fn_quad(t, a, b, c)
```

## Arguments

- t:

  A numeric vector of input values (e.g., time).

- a:

  The quadratic coefficient (curvature).

- b:

  The linear coefficient (slope at the origin).

- c:

  The intercept (function value when `t = 0`).

## Value

A numeric vector of the same length as `t`, representing the quadratic
function values.

## Details

\$\$ f(t; a, b, c) = a \cdot t^2 + b \cdot t + c \$\$

This function represents a second-degree polynomial. The sign of `a`
determines whether the parabola opens upward (`a > 0`) or downward
(`a < 0`).

## Examples

``` r
library(flexFitR)
plot_fn(fn = "fn_quad", params = c(a = 1, b = 10, c = 5))
```
