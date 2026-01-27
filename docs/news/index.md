# Changelog

## flexFitR 1.2.2

### New features

- New functions added: `fn_lpl`, `fn_qpl`, `fn_qpl`.

## flexFitR 1.2.1

CRAN release: 2025-11-04

### Changes

- [`compute_tangent()`](https://apariciojohan.github.io/flexFitR/reference/compute_tangent.md)
  accepts the `x` argument as data.frame.

### Bug fixes

- Fixed issue when `ggplot2` was updated.
- Parallel was not working properly.

## flexFitR 1.2.0

CRAN release: 2025-04-16

### New features

- [`compute_tangent()`](https://apariciojohan.github.io/flexFitR/reference/compute_tangent.md)
  function added to compute tangent line(s) for a `modeler` object.
- [`inverse_predict.modeler()`](https://apariciojohan.github.io/flexFitR/reference/inverse_predict.modeler.md)
  S3 method added to calculate inverse predictions for `modeler`
  objects.
- [`update.modeler()`](https://apariciojohan.github.io/flexFitR/reference/update.modeler.md)
  S3 method added to refit a model of class `modeler`.
- Adding
  [`fn_lin_logis()`](https://apariciojohan.github.io/flexFitR/reference/fn_lin_logis.md),
  [`fn_quad_plat()`](https://apariciojohan.github.io/flexFitR/reference/fn_quad_plat.md)
  and
  [`fn_quad_pl_sm()`](https://apariciojohan.github.io/flexFitR/reference/fn_quad_pl_sm.md).
- [`predict.modeler()`](https://apariciojohan.github.io/flexFitR/reference/predict.modeler.md)
  includes `parallel` and `workers` to allow for parallel computing.

### Changes

- When evaluating several methods in
  [`modeler()`](https://apariciojohan.github.io/flexFitR/reference/modeler.md),
  Jacobian and Hessian are computed only for the best method.
- Now functions are required to be vectorized (faster execution).
- Renaming
  [`fn_lin_plat()`](https://apariciojohan.github.io/flexFitR/reference/fn_lin_plat.md)
  function.
- The
  [`modeler()`](https://apariciojohan.github.io/flexFitR/reference/modeler.md)
  function now uses `optimr` instead of `opm` for faster execution.
- [`plot.modeler()`](https://apariciojohan.github.io/flexFitR/reference/plot.modeler.md)
  includes `linewidth` argument to increase size in geom lines.

### Bug fixes

- Removed methods that required hessian matrix (snewton, snewtonm,
  snewtm) in
  [`list_methods()`](https://apariciojohan.github.io/flexFitR/reference/list_methods.md).
- Fixed issue when combining fitted values in
  [`modeler()`](https://apariciojohan.github.io/flexFitR/reference/modeler.md).

## flexFitR 1.1.0

CRAN release: 2025-02-21

### New features

- [`fitted.modeler()`](https://apariciojohan.github.io/flexFitR/reference/fitted.modeler.md)
  S3 method added to extract fitted values from `modeler` objects.
- [`residuals.modeler()`](https://apariciojohan.github.io/flexFitR/reference/residuals.modeler.md)
  S3 method added to extract residuals from `modeler` objects.
- [`augment()`](https://apariciojohan.github.io/flexFitR/reference/augment.md)
  function added to calculate influence measures (Cook’s distance,
  leverage values, standardized residuals, studentized residuals).
- [`c.modeler()`](https://apariciojohan.github.io/flexFitR/reference/c.modeler.md)
  S3 method added to combine `modeler` objects.
- [`subset.modeler()`](https://apariciojohan.github.io/flexFitR/reference/subset.modeler.md)
  S3 method added to subset `modeler` objects.
- [`performance()`](https://apariciojohan.github.io/flexFitR/reference/performance.md)
  function added to evaluate the performance of several models.
- [`plot.performance()`](https://apariciojohan.github.io/flexFitR/reference/plot.performance.md)
  S3 method to plot an object of class `performance`.

### Changes

- [`modeler()`](https://apariciojohan.github.io/flexFitR/reference/modeler.md)
  adds the function name (`fn_name`) in every output table.
- [`modeler()`](https://apariciojohan.github.io/flexFitR/reference/modeler.md)
  no longer returns function call.
- [`plot.modeler()`](https://apariciojohan.github.io/flexFitR/reference/plot.modeler.md)
  includes `add_ribbon_pi` and `add_ribbon_ci` arguments for prediction
  and confidence intervals.
- [`metrics()`](https://apariciojohan.github.io/flexFitR/reference/metrics.md)
  returns R2 instead of r_squared.

### Bug fixes

- Fixed conflict of
  [`modeler()`](https://apariciojohan.github.io/flexFitR/reference/modeler.md)
  with upcoming version of `future`.
- Fixed increase dependency to R (\>=4.1).
- Fixed regression function not found in the environment when running in
  parallel.

## flexFitR 1.0.0

CRAN release: 2025-01-20

## flexFitR 0.1.0

- Initial CRAN submission.
