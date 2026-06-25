library(bslib)
library(DT)
library(dplyr)
library(ggplot2)
library(httr2)
library(jsonlite)
library(purrr)
library(readr)
library(shiny)
library(stringr)
library(tibble)
library(tidyr)

source("R/build_statsbomb_dataset.R")
source("R/visualize_match.R")

default_competition_id <- 55
default_season_id <- 282

ensure_default_data <- function() {
  matches <- load_matches(default_competition_id, default_season_id)
  match <- select_match(matches)
  path <- file.path("data/processed", paste0("events_match_", match$match_id, ".csv"))

  if (!file.exists(path)) {
    build_statsbomb_dataset(default_competition_id, default_season_id, match$match_id)
  }

  list(match = match, events = readr::read_csv(path, show_col_types = FALSE))
}

metric_card <- function(title, value, subtitle = NULL) {
  bslib::value_box(
    title = title,
    value = value,
    showcase = NULL,
    p(subtitle %||% "")
  )
}

team_summary_for_dashboard <- function(events) {
  summarize_team_events(events) |>
    mutate(
      shots = as.integer(shots),
      goals = as.integer(goals),
      passes = as.integer(passes),
      defensive_events = as.integer(defensive_events),
      carries = as.integer(carries)
    )
}

player_summary <- function(events) {
  events |>
    filter(!is.na(player), !is.na(team)) |>
    group_by(team, player, position) |>
    summarise(
      shots = sum(event_type == "Shot", na.rm = TRUE),
      xg = sum(shot_xg, na.rm = TRUE),
      passes = sum(event_type == "Pass", na.rm = TRUE),
      progressive_passes = sum(event_type == "Pass" & is.na(pass_outcome) & (pass_end_x - location_x) >= 15, na.rm = TRUE),
      pressures = sum(event_type == "Pressure", na.rm = TRUE),
      recoveries = sum(event_type == "Ball Recovery", na.rm = TRUE),
      carries = sum(event_type == "Carry", na.rm = TRUE),
      .groups = "drop"
    ) |>
    arrange(desc(xg), desc(progressive_passes), desc(pressures))
}

shot_plot_for_dashboard <- function(events, selected_team) {
  shots <- events |>
    filter(event_type == "Shot", team == selected_team)

  ggplot(shots) +
    draw_pitch() +
    geom_point(
      aes(
        x = location_x,
        y = location_y,
        size = replace_na(shot_xg, 0),
        color = shot_outcome == "Goal"
      ),
      alpha = 0.82
    ) +
    scale_size_continuous(range = c(3, 13), guide = "none") +
    scale_color_manual(values = c(`TRUE` = "#ff5a3d", `FALSE` = "#2364aa"), guide = "none") +
    labs(title = paste("Mapa de tiros -", selected_team))
}

progressive_pass_plot_for_dashboard <- function(events, selected_team) {
  progressive <- events |>
    filter(
      event_type == "Pass",
      team == selected_team,
      is.na(pass_outcome),
      !is.na(location_x),
      !is.na(pass_end_x)
    ) |>
    mutate(progress = pass_end_x - location_x) |>
    filter(progress >= 15) |>
    arrange(desc(progress)) |>
    slice_head(n = 45)

  ggplot(progressive) +
    draw_pitch() +
    geom_segment(
      aes(x = location_x, y = location_y, xend = pass_end_x, yend = pass_end_y),
      arrow = arrow(length = grid::unit(0.16, "cm")),
      color = "#23835b",
      alpha = 0.72,
      linewidth = 0.7
    ) +
    labs(title = paste("Pases progresivos -", selected_team))
}

defensive_plot_for_dashboard <- function(events, selected_team) {
  defensive <- events |>
    filter(
      team == selected_team,
      event_type %in% c("Pressure", "Ball Recovery", "Interception", "Duel"),
      !is.na(location_x),
      !is.na(location_y)
    )

  ggplot(defensive) +
    draw_pitch() +
    geom_point(aes(x = location_x, y = location_y, color = event_type), alpha = 0.62, size = 2.2) +
    scale_color_manual(
      values = c(
        "Pressure" = "#ff8c42",
        "Ball Recovery" = "#23835b",
        "Interception" = "#2364aa",
        "Duel" = "#6d597a"
      )
    ) +
    labs(title = paste("Acciones defensivas -", selected_team), color = NULL) +
    theme(legend.position = "bottom")
}

data_bundle <- ensure_default_data()
events_data <- data_bundle$events
match_data <- data_bundle$match
teams <- sort(unique(stats::na.omit(events_data$team)))

ui <- page_navbar(
  title = "Football Performance Insights",
  theme = bs_theme(
    version = 5,
    bootswatch = "flatly",
    primary = "#0f2d4a",
    secondary = "#ff6b3d",
    base_font = font_google("Inter")
  ),
  sidebar = sidebar(
    title = "Filtros",
    selectInput("team", "Equipo", choices = teams, selected = teams[[1]]),
    selectInput(
      "event_type",
      "Tipo de evento",
      choices = c("Todos", sort(unique(stats::na.omit(events_data$event_type)))),
      selected = "Todos"
    ),
    sliderInput("minute_range", "Minutos", min = 0, max = 120, value = c(0, 120), step = 5),
    helpText("Caso base: UEFA Euro 2024, final Spain vs England.")
  ),
  nav_panel(
    "Resumen",
    layout_columns(
      value_box(
        title = "Partido",
        value = paste0(match_data$home_score, "-", match_data$away_score),
        p(paste(nested_value(match_data, "home_team"), "vs", nested_value(match_data, "away_team")))
      ),
      uiOutput("shots_card"),
      uiOutput("xg_card"),
      uiOutput("passes_card"),
      col_widths = c(3, 3, 3, 3)
    ),
    layout_columns(
      card(card_header("Resumen por equipo"), DTOutput("team_summary_table")),
      card(card_header("Eventos filtrados"), DTOutput("events_table")),
      col_widths = c(5, 7)
    )
  ),
  nav_panel(
    "Ataque",
    layout_columns(
      card(card_header("Mapa de tiros"), plotOutput("shot_map", height = 560)),
      card(card_header("Pases progresivos"), plotOutput("progressive_passes", height = 560)),
      col_widths = c(6, 6)
    )
  ),
  nav_panel(
    "Defensa",
    card(card_header("Presiones, recuperaciones, intercepciones y duelos"), plotOutput("defensive_map", height = 620))
  ),
  nav_panel(
    "Scouting",
    card(card_header("Ranking de jugadores"), DTOutput("player_table"))
  ),
  nav_panel(
    "Insights",
    card(
      card_header("Recomendaciones deportivas"),
      uiOutput("insights")
    )
  )
)

server <- function(input, output, session) {
  filtered_events <- reactive({
    data <- events_data |>
      filter(team == input$team, minute >= input$minute_range[1], minute <= input$minute_range[2])

    if (input$event_type != "Todos") {
      data <- data |> filter(event_type == input$event_type)
    }

    data
  })

  team_events <- reactive({
    events_data |> filter(team == input$team)
  })

  output$shots_card <- renderUI({
    shots <- team_events() |> filter(event_type == "Shot") |> nrow()
    metric_card("Tiros", shots, input$team)
  })

  output$xg_card <- renderUI({
    xg <- team_events() |> summarise(value = sum(shot_xg, na.rm = TRUE)) |> pull(value)
    metric_card("xG", round(xg, 2), "Goles esperados")
  })

  output$passes_card <- renderUI({
    passes <- team_events() |> filter(event_type == "Pass")
    completion <- round((sum(is.na(passes$pass_outcome)) / max(nrow(passes), 1)) * 100, 1)
    metric_card("Precision de pase", paste0(completion, "%"), paste(nrow(passes), "pases"))
  })

  output$team_summary_table <- renderDT({
    team_summary_for_dashboard(events_data) |>
      datatable(options = list(pageLength = 5, dom = "t"), rownames = FALSE)
  })

  output$events_table <- renderDT({
    filtered_events() |>
      select(minute, second, team, player, position, event_type, shot_xg, shot_outcome, pass_outcome) |>
      datatable(options = list(pageLength = 10, scrollX = TRUE), rownames = FALSE)
  })

  output$shot_map <- renderPlot({
    shot_plot_for_dashboard(team_events(), input$team)
  })

  output$progressive_passes <- renderPlot({
    progressive_pass_plot_for_dashboard(team_events(), input$team)
  })

  output$defensive_map <- renderPlot({
    defensive_plot_for_dashboard(team_events(), input$team)
  })

  output$player_table <- renderDT({
    player_summary(events_data) |>
      filter(team == input$team) |>
      mutate(xg = round(xg, 3)) |>
      datatable(options = list(pageLength = 12, scrollX = TRUE), rownames = FALSE)
  })

  output$insights <- renderUI({
    summary <- team_summary_for_dashboard(events_data)
    selected <- summary |> filter(team == input$team)
    opponent <- summary |> filter(team != input$team) |> slice(1)

    tags$div(
      tags$p(strong("Lectura principal: "), input$team, " produjo ", selected$shots, " tiros y ", selected$xg, " xG."),
      tags$ul(
        tags$li("Usar el mapa de tiros para identificar zonas de finalizacion y calidad de ocasiones."),
        tags$li("Revisar los pases progresivos para detectar rutas de avance y jugadores que rompen lineas."),
        tags$li("Cruzar presiones y recuperaciones para evaluar si el equipo recupera cerca del arco rival."),
        tags$li(
          if (nrow(opponent) > 0 && selected$xg > opponent$xg) {
            "El equipo genero mayor peligro que el rival; profundizar en mecanismos ofensivos repetibles."
          } else {
            "El rival genero igual o mayor peligro; revisar perdidas, duelos y zonas concedidas."
          }
        )
      )
    )
  })
}

shinyApp(ui, server)
