# Transform variables in a data frame

This function performs transformations on specified columns of a data
frame, including truncating maximum values, handling negative values,
and adding a zero to the series. It allows for grouping and supports
retaining metadata in the output.

## Usage

``` r
transform(
  data,
  x,
  y,
  grp,
  metadata,
  max_as_last = FALSE,
  check_negative = FALSE,
  add_zero = FALSE,
  interval = NULL
)
```

## Arguments

- data:

  A \`data.frame\` containing the input data for analysis.

- x:

  The name of the column in \`data\` representing the independent
  variable (x points).

- y:

  The name of the column(s) in \`data\` containing variables to
  transform.

- grp:

  Column(s) in \`data\` used as grouping variable(s). Defaults to
  \`NULL\` (optional).

- metadata:

  Names of columns to retain in the output. Defaults to \`NULL\`
  (optional).

- max_as_last:

  Logical. If \`TRUE\`, appends the maximum value after reaching the
  maximum. Default is \`FALSE\`.

- check_negative:

  Logical. If \`TRUE\`, converts negative values in the data to zero.
  Default is \`FALSE\`.

- add_zero:

  Logical. If \`TRUE\`, adds a zero value to the series at the start.
  Default is \`FALSE\`.

- interval:

  A numeric vector of length 2 (start and end) specifying the range to
  filter the data. Defaults to \`NULL\`.

## Value

A transformed \`data.frame\` with the specified modifications applied.

## Examples

``` r
data(dt_potato)
new_data <- transform(
  data = dt_potato,
  x = DAP,
  y = GLI,
  grp = gid,
  max_as_last = TRUE,
  check_negative = TRUE
)
```
