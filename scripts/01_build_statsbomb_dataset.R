library(dplyr)
library(httr2)
library(jsonlite)
library(purrr)
library(readr)
library(stringr)
library(tibble)
library(tidyr)

source("R/build_statsbomb_dataset.R")

# UEFA Euro 2024 por defecto. Cambia estos valores si quieres otra competicion.
build_statsbomb_dataset(
  competition_id = 55,
  season_id = 282,
  match_id = NULL
)
