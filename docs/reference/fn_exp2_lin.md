# Super-exponential linear function

A piecewise function that models an initial exponential growth phase
based on a squared time difference, followed by a linear phase.

## Usage

``` r
fn_exp2_lin(t, t1, t2, alpha, beta)
```

## Arguments

- t:

  A numeric vector of input values (e.g., time).

- t1:

  The onset time of the response. The function is 0 for all values less
  than `t1`.

- t2:

  The transition time between exponential and linear phases. Must be
  greater than `t1`.

- alpha:

  The exponential growth rate controlling the curvature of the
  exponential phase.

- beta:

  The slope of the linear phase after `t2`.

## Value

A numeric vector of the same length as `t`, representing the function
values.

## Details

\$\$ f(t; t_1, t_2, \alpha, \beta) = \begin{cases} 0 & \text{if } t \<
t_1 \\ e^{\alpha \cdot (t - t_1)^2} - 1 & \text{if } t_1 \leq t \leq t_2
\\ \beta \cdot (t - t_2) + \left(e^{\alpha \cdot (t_2 - t_1)^2} -
1\right) & \text{if } t \> t_2 \end{cases} \$\$

The exponential section rises gradually from 0 at `t1` and accelerates
as time increases. The linear section starts at `t2` with a value
matching the end of the exponential phase, ensuring continuity but not
necessarily matching the derivative.

## Examples

``` r
library(flexFitR)
plot_fn(
  fn = "fn_exp2_lin",
  params = c(t1 = 35, t2 = 55, alpha = 1 / 600, beta = -1 / 80),
  interval = c(0, 108),
  n_points = 2000,
  auc_label_size = 3
)
```
