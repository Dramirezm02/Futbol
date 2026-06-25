library(dplyr)
library(ggplot2)
library(httr2)
library(jsonlite)
library(purrr)
library(readr)
library(stringr)
library(tibble)
library(tidyr)

source("R/build_statsbomb_dataset.R")
source("R/visualize_match.R")
source("R/advanced_analysis.R")

dir.create("reports/figures", recursive = TRUE, showWarnings = FALSE)
dir.create("reports/tables", recursive = TRUE, showWarnings = FALSE)

result <- build_statsbomb_dataset(competition_id = 55, season_id = 282, match_id = 3943043)
events <- result$events
summary_table <- result$summary
match <- result$match
home_team <- nested_value(match, "home_team")
away_team <- nested_value(match, "away_team")

model <- poisson_match_model(summary_table, home_team, away_team)
simulations <- simulate_match_outcomes(summary_table, home_team, away_team)
advanced_players <- player_advanced_summary(events)
top_player <- advanced_players |>
  dplyr::arrange(dplyr::desc(scouting_score)) |>
  dplyr::slice(1) |>
  dplyr::pull(player)

readr::write_csv(model$outcome_probabilities, "reports/tables/poisson_outcome_probabilities.csv")
readr::write_csv(simulations, "reports/tables/monte_carlo_probabilities.csv")
readr::write_csv(model$top_scorelines, "reports/tables/top_scorelines_poisson.csv")
readr::write_csv(advanced_players, "reports/tables/advanced_player_ranking.csv")

ggplot2::ggsave(
  "reports/figures/score_probability_heatmap.png",
  plot_score_probability_heatmap(model),
  width = 10,
  height = 7,
  dpi = 180
)

ggplot2::ggsave(
  "reports/figures/top_player_radar.png",
  plot_player_radar(advanced_players, top_player),
  width = 8,
  height = 7,
  dpi = 180
)

message("Advanced outputs exported to reports/figures and reports/tables.")
