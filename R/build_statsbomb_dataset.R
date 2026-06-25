source("R/statsbomb_loader.R")

flatten_events <- function(events, match, competition_id, season_id) {
  rows <- lapply(events, function(event) {
    pass_data <- event$pass %||% list()
    shot_data <- event$shot %||% list()
    carry_data <- event$carry %||% list()
    duel_data <- event$duel %||% list()
    interception_data <- event$interception %||% list()

    tibble::tibble(
      event_id = event$id %||% NA_character_,
      event_index = event$index %||% NA_integer_,
      match_id = match$match_id,
      competition_id = competition_id,
      season_id = season_id,
      match_date = match$match_date %||% NA_character_,
      home_team = nested_value(match, "home_team"),
      away_team = nested_value(match, "away_team"),
      home_score = match$home_score %||% NA_integer_,
      away_score = match$away_score %||% NA_integer_,
      period = event$period %||% NA_integer_,
      timestamp = event$timestamp %||% NA_character_,
      minute = event$minute %||% NA_integer_,
      second = event$second %||% NA_integer_,
      possession = event$possession %||% NA_integer_,
      possession_team = nested_value(event, "possession_team"),
      team = nested_value(event, "team"),
      player = nested_value(event, "player"),
      position = nested_value(event, "position"),
      event_type = nested_value(event, "type"),
      play_pattern = nested_value(event, "play_pattern"),
      location_x = xy(event$location, 1),
      location_y = xy(event$location, 2),
      pass_end_x = xy(pass_data$end_location, 1),
      pass_end_y = xy(pass_data$end_location, 2),
      pass_recipient = nested_value(pass_data, "recipient"),
      pass_type = nested_value(pass_data, "type"),
      pass_outcome = nested_value(pass_data, "outcome"),
      pass_height = nested_value(pass_data, "height"),
      pass_length = pass_data$length %||% NA_real_,
      shot_xg = shot_data$statsbomb_xg %||% NA_real_,
      shot_outcome = nested_value(shot_data, "outcome"),
      shot_body_part = nested_value(shot_data, "body_part"),
      shot_technique = nested_value(shot_data, "technique"),
      carry_end_x = xy(carry_data$end_location, 1),
      carry_end_y = xy(carry_data$end_location, 2),
      duel_type = nested_value(duel_data, "type"),
      duel_outcome = nested_value(duel_data, "outcome"),
      interception_outcome = nested_value(interception_data, "outcome"),
      under_pressure = event$under_pressure %||% FALSE,
      counterpress = event$counterpress %||% FALSE
    )
  })

  dplyr::bind_rows(rows)
}

summarize_team_events <- function(events) {
  shots <- events |>
    dplyr::filter(event_type == "Shot") |>
    dplyr::group_by(team) |>
    dplyr::summarise(
      shots = dplyr::n(),
      xg = sum(shot_xg, na.rm = TRUE),
      goals = sum(shot_outcome == "Goal", na.rm = TRUE),
      .groups = "drop"
    )

  passes <- events |>
    dplyr::filter(event_type == "Pass") |>
    dplyr::group_by(team) |>
    dplyr::summarise(
      passes = dplyr::n(),
      incomplete_passes = sum(!is.na(pass_outcome)),
      .groups = "drop"
    )

  defensive <- events |>
    dplyr::filter(event_type %in% c("Pressure", "Ball Recovery", "Interception", "Duel")) |>
    dplyr::group_by(team) |>
    dplyr::summarise(defensive_events = dplyr::n(), .groups = "drop")

  carries <- events |>
    dplyr::filter(event_type == "Carry") |>
    dplyr::group_by(team) |>
    dplyr::summarise(carries = dplyr::n(), .groups = "drop")

  list(shots, passes, defensive, carries) |>
    purrr::reduce(dplyr::full_join, by = "team") |>
    dplyr::mutate(
      dplyr::across(-team, ~ tidyr::replace_na(.x, 0)),
      pass_completion_pct = round((passes - incomplete_passes) / dplyr::if_else(passes == 0, NA_real_, passes) * 100, 1),
      xg = round(xg, 3)
    ) |>
    dplyr::arrange(dplyr::desc(xg), dplyr::desc(shots))
}

build_statsbomb_dataset <- function(competition_id = 55, season_id = 282, match_id = NULL) {
  dir.create("data/processed", recursive = TRUE, showWarnings = FALSE)
  dir.create("reports/tables", recursive = TRUE, showWarnings = FALSE)

  load_competitions()
  matches <- load_matches(competition_id, season_id)
  match <- select_match(matches, match_id)
  selected_match_id <- match$match_id

  events <- load_events(selected_match_id)
  load_lineups(selected_match_id)
  load_three_sixty(selected_match_id)

  events_df <- flatten_events(events, match, competition_id, season_id)
  summary_df <- summarize_team_events(events_df)

  events_path <- file.path("data/processed", paste0("events_match_", selected_match_id, ".csv"))
  summary_path <- file.path("reports/tables", paste0("team_summary_match_", selected_match_id, ".csv"))

  readr::write_csv(events_df, events_path)
  readr::write_csv(summary_df, summary_path)

  message(
    "Partido: ", nested_value(match, "home_team"), " ",
    match$home_score, "-", match$away_score, " ",
    nested_value(match, "away_team"), " (", match$match_date, ")"
  )
  message("Eventos: ", format(nrow(events_df), big.mark = "."))
  message("CSV eventos: ", normalizePath(events_path, winslash = "/", mustWork = FALSE))
  message("Tabla resumen: ", normalizePath(summary_path, winslash = "/", mustWork = FALSE))

  invisible(list(match = match, events = events_df, summary = summary_df))
}
