# Football Performance Insights en RStudio

Dashboard de portafolio para analizar rendimiento, scouting e insights de futbol con datos abiertos de StatsBomb.

El caso inicial usa StatsBomb Open Data y, por defecto, la final de UEFA Euro 2024: Spain 2-1 England (`competition_id=55`, `season_id=282`).

## Objetivo

Construir un dashboard en RStudio/Shiny que demuestre capacidades alineadas con una vacante de datos e insights de futbol:

- Analisis de rendimiento ofensivo y defensivo.
- Limpieza y transformacion de datos de eventos.
- Visualizacion de mapas de tiros, pases progresivos y acciones defensivas.
- Ranking inicial de jugadores para scouting.
- Traduccion de datos en recomendaciones deportivas.

## Estructura

```text
app.R                       # Dashboard Shiny principal
install_packages.R          # Instalacion de paquetes R
R/
  statsbomb_loader.R        # Descarga y helpers para JSON de StatsBomb
  build_statsbomb_dataset.R # Limpieza y dataset plano
  visualize_match.R         # Graficos con ggplot2
scripts/
  01_build_statsbomb_dataset.R
  02_visualize_match.R
data/
  raw/                      # JSON descargados, ignorados por git
  processed/                # CSV procesados, ignorados por git
reports/
  figures/                  # PNG generados, ignorados por git
  tables/                   # Resumenes CSV, ignorados por git
```

## Como correrlo en RStudio

1. Abre `Analisis futbolistico.Rproj` desde RStudio.
2. Instala paquetes:

```r
source("install_packages.R")
```

3. Abre `app.R`.
4. Haz clic en **Run App**.

Tambien puedes correrlo desde la consola:

```r
shiny::runApp()
```

## Que muestra el dashboard

- **Resumen:** marcador, tiros, xG, precision de pase, tabla por equipo y eventos filtrados.
- **Ataque:** mapa de tiros y pases progresivos.
- **Defensa:** presiones, recuperaciones, intercepciones y duelos.
- **Modelo:** probabilidades de resultado con Poisson, simulacion Monte Carlo y marcadores mas probables.
- **Scouting:** ranking de jugadores con tiros, xG, pases progresivos, presiones y recuperaciones.
- **Insights:** recomendaciones deportivas iniciales para convertir datos en decisiones.

## Reporte publicable

El proyecto tambien incluye un reporte reproducible en R Markdown:

```r
source("scripts/03_render_report.R")
```

Ese comando genera:

```text
docs/index.html
```

Cuando GitHub Pages este activo desde la carpeta `docs/`, el reporte se podra abrir en:

```text
https://dramirezm02.github.io/Futbol/
```

## Generar datos manualmente

Si quieres crear primero los CSV y graficos sin abrir Shiny:

```r
source("scripts/01_build_statsbomb_dataset.R")
source("scripts/02_visualize_match.R")
source("scripts/03_render_report.R")
source("scripts/04_export_advanced_outputs.R")
```

Las salidas avanzadas se guardan en:

```text
reports/tables/poisson_outcome_probabilities.csv
reports/tables/monte_carlo_probabilities.csv
reports/tables/top_scorelines_poisson.csv
reports/tables/advanced_player_ranking.csv
reports/figures/score_probability_heatmap.png
reports/figures/top_player_radar.png
```

## Cambiar partido o competicion

Edita los valores dentro de `app.R`:

```r
default_competition_id <- 55
default_season_id <- 282
```

Para analizar un partido especifico, puedes usar:

```r
source("R/build_statsbomb_dataset.R")
build_statsbomb_dataset(competition_id = 55, season_id = 282, match_id = 3943043)
```

## Columnas clave

```text
match_id, competition_id, season_id, match_date, home_team, away_team,
team, player, position, minute, second, period, timestamp,
event_type, location_x, location_y, pass_end_x, pass_end_y,
shot_xg, shot_outcome, pass_type, pass_outcome, carry_end_x, carry_end_y,
duel_type, interception_outcome, under_pressure, possession
```

## Siguientes mejoras

1. Agregar filtros por partido y jugador.
2. Crear metricas por 90 minutos.
3. Agregar modelo simple de similitud de jugadores.
4. Entrenar un modelo predictivo con una muestra historica de partidos.
5. Escribir un informe ejecutivo de 1 pagina con conclusiones para cuerpo tecnico.

## Fuente

- [StatsBomb Open Data](https://github.com/statsbomb/open-data)
