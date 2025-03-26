# flexFitR 1.1.0.00009

## Changes

* Renaming `fn_lin_plat()` function and adding `fn_lin_logis()` and `fn_quad_plat()`.
* The `modeler()` function now uses `optimr` instead of `opm` for faster execution.
* `plot.modeler()` includes `linewidth` argument to increase size in geom lines.
* `predict.modeler()` includes `parallel` and `workers` to allow for parallel computing.

## Bug fixes

* Removed methods that required hessian matrix (snewton, snewtonm, snewtm) in `list_methods()`.
* Fixed issue when combining fitted values in `modeler()`.

# flexFitR 1.1.0

## New features

* `fitted.modeler()` S3 method added to extract fitted values from `modeler` objects.
* `residuals.modeler()` S3 method added to extract residuals from `modeler` objects.
* `augment()` function added to calculate influence measures (Cook's distance,
  leverage values, standardized residuals, studentized residuals).
* `c.modeler()` S3 method added to combine `modeler` objects.
* `subset.modeler()` S3 method added to subset `modeler` objects.
* `performance()` function added to evaluate the performance of several models.
* `plot.performance()` S3 method to plot an object of class `performance`.

## Changes

* `modeler()` adds the function name (`fn_name`) in every output table.
* `modeler()` no longer returns function call.
* `plot.modeler()` includes `add_ribbon_pi` and `add_ribbon_ci` arguments for
prediction and confidence intervals.
* `metrics()` returns R2 instead of r_squared.

## Bug fixes

* Fixed conflict of `modeler()` with upcoming version of `future`.
* Fixed increase dependency to R (>=4.1).
* Fixed regression function not found in the environment when running in parallel.

# flexFitR 1.0.0

# flexFitR 0.1.0

* Initial CRAN submission.
