# flexFitR (development version)

## New features

* `modeler()` adds the function name (`fn_name`) in every single table.
* `c.modeler()` S3 method added to combine `modeler` objects.
* `subset.modeler()` S3 method added to subset `modeler` objects.
* `performance()` function added to evaluate the performance of different models.
* `plot.performance()` S3 method to plot an object of class `performance`.

## Changes

* `modeler()` no longer returns function call.
* `metrics()` returns R2 instead of r_squared.

## Bug fixes

* Fixed conflict of `modeler()` with upcoming version of `future`.
* Fixed increase dependency to R (>=4.1).
* Fixed regression function not found in the environment when running in parallel.

# flexFitR 1.0.0

# flexFitR 0.1.0

* Initial CRAN submission.
