## code to prepare `DATASET` dataset goes here

dt_potato <- readr::read_csv("data-raw/data_2020_flexfitr.csv")
usethis::use_data(dt_potato, overwrite = TRUE)


dt_potato_22 <- readr::read_csv("data-raw/chips_2022.csv") |>
  select(Trial, DAP, Plot, row, range, Name, Total.yield, vine.maturity, Red:Canopy)
names(dt_potato_22) <- names(dt_potato_20)

usethis::use_data(dt_potato_22, overwrite = TRUE)
