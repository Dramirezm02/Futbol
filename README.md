# Football Performance Insights

Portfolio project for football performance analysis, scouting insights, and probabilistic match modeling using open event data from StatsBomb.

The case study analyzes the UEFA Euro 2024 final: **Spain 2-1 England** (`competition_id = 55`, `season_id = 282`, `match_id = 3943043`).

## Overview

This project demonstrates an end-to-end football analytics workflow in R:

- Download and transform open event data.
- Build a Shiny dashboard for interactive analysis.
- Generate tactical visualizations such as shot maps and progressive pass maps.
- Summarize team and player performance.
- Estimate match result probabilities with a Poisson model.
- Run Monte Carlo simulations.
- Create a reproducible R Markdown report for publication.

## Public Report

The rendered report is available in:

```text
docs/index.html
```

If GitHub Pages is enabled from the `docs/` folder, the report can be viewed at:

```text
https://dramirezm02.github.io/Futbol/
```

## Dashboard

Open the project in RStudio with:

```text
FUTBOL.Rproj
```

Install required packages:

```r
source("install_packages.R")
```

Run the Shiny app:

```r
shiny::runApp()
```

The dashboard includes:

- **Summary:** scoreline, shots, xG, passing accuracy, event table.
- **Attack:** shot map and progressive passes.
- **Defense:** pressures, recoveries, interceptions, and duels.
- **Model:** Poisson probabilities, Monte Carlo simulation, and most likely scorelines.
- **Scouting:** advanced player ranking and radar profile.
- **Insights:** practical football recommendations based on the analysis.

## Main Results

For Spain vs England, using observed xG as the Poisson input:

```text
Poisson model
Spain win:   62.8%
Draw:        22.6%
England win: 14.7%

Monte Carlo simulation
Spain win:   62.6%
Draw:        23.0%
England win: 14.5%
```

Most likely scorelines:

```text
1-0 Spain: 14.5%
2-0 Spain: 13.0%
1-1 Draw:  10.5%
2-1 Spain:  9.4%
```

## Repository Structure

```text
app.R                                  # Shiny dashboard
install_packages.R                     # R package installer
R/
  statsbomb_loader.R                   # StatsBomb Open Data loader
  build_statsbomb_dataset.R            # Event flattening and team summaries
  visualize_match.R                    # Pitch maps and visual helpers
  advanced_analysis.R                  # Poisson, Monte Carlo, scouting scores
scripts/
  01_build_statsbomb_dataset.R         # Build base datasets
  02_visualize_match.R                 # Export base figures
  03_render_report.R                   # Render R Markdown report
  04_export_advanced_outputs.R         # Export advanced tables and figures
reports/
  football_performance_report.Rmd      # Reproducible report source
  figures/                             # Portfolio figures
  tables/                              # Portfolio result tables
docs/
  index.html                           # Rendered public report
data/
  raw/                                 # Downloaded JSON files, ignored by Git
  processed/                           # Generated event CSV files, ignored by Git
```

## Generated Outputs

Figures:

```text
reports/figures/shot_map_3943043_Spain.png
reports/figures/progressive_passes_3943043_Spain.png
reports/figures/score_probability_heatmap.png
reports/figures/top_player_radar.png
```

Tables:

```text
reports/tables/team_summary_match_3943043.csv
reports/tables/poisson_outcome_probabilities.csv
reports/tables/monte_carlo_probabilities.csv
reports/tables/top_scorelines_poisson.csv
reports/tables/advanced_player_ranking.csv
```

## Reproducibility

Run the full workflow from RStudio:

```r
source("install_packages.R")
source("scripts/01_build_statsbomb_dataset.R")
source("scripts/02_visualize_match.R")
source("scripts/04_export_advanced_outputs.R")
source("scripts/03_render_report.R")
```

## Methods

The analysis combines:

- Descriptive statistics: shots, goals, passes, pass completion, defensive events.
- Football event metrics: xG, progressive passes, progressive carries, pressures, recoveries.
- Poisson score model using team xG as expected goals.
- Monte Carlo simulation with 10,000 simulated matches.
- Weighted scouting score based on xG, progression, defensive activity, and involvement.

## Limitations

This is a portfolio analysis based on one match. The Poisson and Monte Carlo models are explanatory tools based on observed xG, not production-grade betting or recruitment models. A stronger predictive model would require a larger historical dataset, team-strength adjustments, player availability, home advantage, and validation on out-of-sample matches.

## Data Source

Data comes from [StatsBomb Open Data](https://github.com/statsbomb/open-data). This project is not affiliated with StatsBomb, UEFA, Spain, England, River Plate, or any football club. It is an educational portfolio project using publicly available data.
