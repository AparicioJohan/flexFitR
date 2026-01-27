# Update a `modeler` object

It creates a new fitted object using the parameter values from the
current model as initial values. It can also be used to perform a few
additional iterations of a model that has not converged.

## Usage

``` r
# S3 method for class 'modeler'
update(object, method = NULL, track = TRUE, eps = 1e-06, ...)
```

## Arguments

- object:

  An object of class `modeler`.

- method:

  A character vector specifying optimization methods. Check available
  methods using
  [`list_methods()`](https://apariciojohan.github.io/flexFitR/reference/list_methods.md).
  Defaults to the ones in `object`.

- track:

  Logical. If `TRUE`, the function compares the SSE before and after the
  update and reports how many groups improved. Useful for evaluating
  whether the refit led to better convergence.

- eps:

  Numeric. The minimum change in SSE required to consider a fit
  improved. Defaults to `1e-6`. Smaller values may include numerical
  noise as improvements.

- ...:

  Additional parameters for future functionality.

## Value

An object of class `modeler`, which is a list containing the following
elements:

- `param`:

  Data frame containing optimized parameters and related information.

- `dt`:

  Data frame with input data, fitted values, and residuals.

- `metrics`:

  Metrics and summary of the models.

- `execution`:

  Total execution time for the analysis.

- `response`:

  Name of the response variable analyzed.

- `keep`:

  Metadata retained based on the `keep` argument.

- `fun`:

  Name of the curve-fitting function used.

- `parallel`:

  List containing parallel execution details (if applicable).

- `fit`:

  List of fitted models for each group.

## Examples

``` r
library(flexFitR)
data(dt_potato)
mo_1 <- dt_potato |>
  modeler(
    x = DAP,
    y = GLI,
    grp = Plot,
    fn = "fn_lin_pl_lin",
    parameters = c(t1 = 10, t2 = 62, t3 = 90, k = 0.32, beta = -0.01),
    subset = 195
  )
plot(mo_1)

mo_2 <- update(mo_1)
#> Improved SSE in 1/1 groups (eps = 1.0e-06)
plot(mo_2)
```
