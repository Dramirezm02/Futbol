library(dplyr)
library(ggplot2)
library(httr2)
library(jsonlite)
library(purrr)
library(readr)
library(stringr)
library(tibble)
library(tidyr)

source("R/visualize_match.R")

# Si no pasas equipo, toma el equipo con mayor xG del partido.
visualize_match(
  competition_id = 55,
  season_id = 282,
  match_id = NULL,
  team = NULL
)
