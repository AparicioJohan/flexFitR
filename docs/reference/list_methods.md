# Print available methods in flexFitR

Print available methods in flexFitR

## Usage

``` r
list_methods(bounds = FALSE, check_package = FALSE)
```

## Arguments

- bounds:

  If TRUE, returns methods for box (or bounds) constraints. FALSE by
  default.

- check_package:

  If TRUE, ensures solvers are installed. FALSE by default.

## Value

A vector with available methods

## Examples

``` r
library(flexFitR)
list_methods()
#>         stats         stats         stats         stats         stats 
#>        "BFGS"          "CG" "Nelder-Mead"    "L-BFGS-B"         "nlm" 
#>         stats      lbfgsb3c        optimx        optimx        optimx 
#>      "nlminb"    "lbfgsb3c"      "Rcgmin"      "Rtnmin"      "Rvmmin" 
#>            BB        ucminf         minqa         minqa       dfoptim 
#>         "spg"      "ucminf"      "newuoa"      "bobyqa"        "nmkb" 
#>       dfoptim        optimx         lbfgs       subplex        optimx 
#>        "hjkb"         "hjn"       "lbfgs"     "subplex"         "ncg" 
#>        optimx    marqLevAlg        nloptr        nloptr        pracma 
#>         "nvm"         "mla"       "slsqp"       "tnewt"        "anms" 
#>        pracma        nloptr 
#>    "pracmanm"        "nlnm" 
```
