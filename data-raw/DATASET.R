## code to prepare `DATASET` dataset goes here

dt_potato <- readr::read_csv("data-raw/dt_potato.csv")

usethis::use_data(dt_potato, overwrite = TRUE)


dt_chips <- readr::read_csv("data-raw/chips_2022.csv") |>
  select(Trial, DAP, Plot, row, range, Name, Total.yield, vine.maturity, Red:Canopy)
names(dt_chips) <- names(dt_potato)

usethis::use_data(dt_chips, overwrite = TRUE)
