# Linear function

A basic linear function of the form `f(t) = m * t + b`, where `m` is the
slope and `b` is the intercept.

## Usage

``` r
fn_lin(t, m, b)
```

## Arguments

- t:

  A numeric vector of input values (e.g., time).

- m:

  The slope of the line.

- b:

  The intercept (function value when `t = 0`).

## Value

A numeric vector of the same length as `t`, giving the linear function
values.

## Details

\$\$ f(t; m, b) = m \cdot t + b \$\$

## Examples

``` r
library(flexFitR)
plot_fn(
  fn = "fn_lin",
  params = c(m = 2, b = 10),
  interval = c(0, 108),
  n_points = 2000
)
```
