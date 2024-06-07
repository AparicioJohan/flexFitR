## code to prepare `DATASET` dataset goes here

dt_potato <- readr::read_csv("data-raw/dt_potato.csv")

usethis::use_data(dt_potato, overwrite = TRUE)
