# General-purpose optimization

The function .fitter_curve is used internally to find the parameters
requested.

## Usage

``` r
.fitter_curve(
  data,
  id,
  fn,
  method,
  lower,
  upper,
  control,
  metadata,
  trace,
  fn_str
)
```

## Arguments

- data:

  A nested data.frame with columns \<plot, genotype, row, range, data,
  initials, fx_params\>.

- id:

  An optional vector of IDs to filter the data. Default is `NULL`,
  meaning all ids are used.

- fn:

  A function to be used for the curve fitting. Default is
  `"fn_lin_plat"`.

- method:

  A character vector specifying the optimization methods to be used. See
  `optimx` package for available methods. Default is
  `c("subplex", "pracmanm", "anms")`.

- lower:

  Numeric vector specifying the lower bounds for the parameters. Default
  is `-Inf` for all parameters.

- upper:

  Numeric vector specifying the upper bounds for the parameters. Default
  is `Inf` for all parameters.

- control:

  A list of control parameters to be passed to the optimization
  function. For example, `list(maxit = 500)`.

- trace:

  If `TRUE` , convergence monitoring of the current fit is reported in
  the console. `FALSE` by default.

- fn_str:

  A string specifying the name of the function to be used for the curve
  fitting. Default is `"fn_lin_plat"`.

## Value

A list containing the following elements:

- `kkopt`:

  opm object.

- `param`:

  Data frame with best solution parameters.

- `rr`:

  Data frame with all methods tested.

- `details`:

  Additional details of the best solution.

- `hessian`:

  Hessian matrix.

- `type`:

  Data frame describing the type of coefficient (estimable of fixed)

- `conv`:

  Convergency.

- `p`:

  Number of parameters estimated.

- `n_obs`:

  Number of observations.

- `uid`:

  Unique identifier.

- `fn_name`:

  Name of the curve-fitting function used.

## Examples

``` r
library(flexFitR)
data(dt_potato)
mod_1 <- dt_potato |>
  modeler(
    x = DAP,
    y = GLI,
    grp = Plot,
    fn = "fn_lin_pl_lin",
    parameters = c(t1 = 38.7, t2 = 62, t3 = 90, k = 0.32, beta = -0.01),
    subset = 195,
    options = list(add_zero = TRUE)
  )
```
