## code to prepare `DATASET` dataset goes here

dt_potato <- readr::read_csv("data-raw/data_2020_flexfitr.csv") |>
  rename(Trial = trial) |>
  select(-year, -loc) |>
  relocate(DAP, .after = gid)
usethis::use_data(dt_potato, overwrite = TRUE)


# dt_potato_22 <- readr::read_csv("data-raw/chips_2022.csv") |>
#   select(Trial, DAP, Plot, row, range, Name, Total.yield, vine.maturity, Red:Canopy)
# names(dt_potato_22) <- names(dt_potato_20)

dt_potato_22 <- readr::read_csv("data-raw/dt_potato_2022_paper.csv") |>
  select(Trial, Plot, Row, Range, gid, DAP, GC, PH = ph, Yield = yield)

usethis::use_data(dt_potato_22, overwrite = TRUE)


# Soybean
dt_soybean_22 <- readr::read_csv("data-raw/dt_soybean_22.csv")

usethis::use_data(dt_soybean_22, overwrite = TRUE)
