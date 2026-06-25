source("R/build_statsbomb_dataset.R")

draw_pitch <- function() {
  list(
    ggplot2::coord_fixed(xlim = c(0, 120), ylim = c(0, 80), expand = FALSE),
    ggplot2::theme_void(),
    ggplot2::theme(
      plot.background = ggplot2::element_rect(fill = "#f7f6f2", color = NA),
      panel.background = ggplot2::element_rect(fill = "#f7f6f2", color = NA),
      plot.title = ggplot2::element_text(hjust = 0.5, size = 18, face = "bold")
    ),
    ggplot2::geom_rect(ggplot2::aes(xmin = 0, xmax = 120, ymin = 0, ymax = 80), fill = NA, color = "#30343f"),
    ggplot2::geom_segment(ggplot2::aes(x = 60, xend = 60, y = 0, yend = 80), color = "#30343f"),
    ggplot2::geom_rect(ggplot2::aes(xmin = 0, xmax = 18, ymin = 18, ymax = 62), fill = NA, color = "#30343f"),
    ggplot2::geom_rect(ggplot2::aes(xmin = 102, xmax = 120, ymin = 18, ymax = 62), fill = NA, color = "#30343f"),
    ggplot2::geom_rect(ggplot2::aes(xmin = 0, xmax = 6, ymin = 30, ymax = 50), fill = NA, color = "#30343f"),
    ggplot2::geom_rect(ggplot2::aes(xmin = 114, xmax = 120, ymin = 30, ymax = 50), fill = NA, color = "#30343f")
  )
}

choose_team <- function(events, team = NULL) {
  if (!is.null(team)) {
    return(team)
  }

  events |>
    dplyr::filter(event_type == "Shot") |>
    dplyr::group_by(team) |>
    dplyr::summarise(xg = sum(shot_xg, na.rm = TRUE), .groups = "drop") |>
    dplyr::arrange(dplyr::desc(xg)) |>
    dplyr::slice(1) |>
    dplyr::pull(team)
}

safe_name <- function(value) {
  stringr::str_replace_all(value, "[^A-Za-z0-9]+", "_")
}

plot_shots <- function(events, match_id, team) {
  shots <- events |>
    dplyr::filter(event_type == "Shot", .data$team == team)

  plot <- ggplot2::ggplot(shots) +
    draw_pitch() +
    ggplot2::geom_point(
      ggplot2::aes(
        x = location_x,
        y = location_y,
        size = tidyr::replace_na(shot_xg, 0),
        color = shot_outcome == "Goal"
      ),
      alpha = 0.8
    ) +
    ggplot2::scale_size_continuous(range = c(4, 14), guide = "none") +
    ggplot2::scale_color_manual(values = c(`TRUE` = "#cf3f3f", `FALSE` = "#2364aa"), guide = "none") +
    ggplot2::labs(title = paste("Mapa de tiros -", team))

  dir.create("reports/figures", recursive = TRUE, showWarnings = FALSE)
  path <- file.path("reports/figures", paste0("shot_map_", match_id, "_", safe_name(team), ".png"))
  ggplot2::ggsave(path, plot, width = 10, height = 7, dpi = 180)
  path
}

plot_progressive_passes <- function(events, match_id, team) {
  progressive <- events |>
    dplyr::filter(
      event_type == "Pass",
      .data$team == team,
      is.na(pass_outcome),
      !is.na(location_x),
      !is.na(pass_end_x)
    ) |>
    dplyr::mutate(progress = pass_end_x - location_x) |>
    dplyr::filter(progress >= 15) |>
    dplyr::arrange(dplyr::desc(progress)) |>
    dplyr::slice_head(n = 40)

  plot <- ggplot2::ggplot(progressive) +
    draw_pitch() +
    ggplot2::geom_segment(
      ggplot2::aes(x = location_x, y = location_y, xend = pass_end_x, yend = pass_end_y),
      arrow = ggplot2::arrow(length = grid::unit(0.16, "cm")),
      color = "#23835b",
      alpha = 0.72,
      linewidth = 0.7
    ) +
    ggplot2::labs(title = paste("Pases progresivos -", team))

  dir.create("reports/figures", recursive = TRUE, showWarnings = FALSE)
  path <- file.path("reports/figures", paste0("progressive_passes_", match_id, "_", safe_name(team), ".png"))
  ggplot2::ggsave(path, plot, width = 10, height = 7, dpi = 180)
  path
}

visualize_match <- function(competition_id = 55, season_id = 282, match_id = NULL, team = NULL) {
  matches <- load_matches(competition_id, season_id)
  match <- select_match(matches, match_id)
  selected_match_id <- match$match_id
  csv_path <- file.path("data/processed", paste0("events_match_", selected_match_id, ".csv"))

  if (!file.exists(csv_path)) {
    build_statsbomb_dataset(competition_id, season_id, selected_match_id)
  }

  events <- readr::read_csv(csv_path, show_col_types = FALSE)
  selected_team <- choose_team(events, team)

  shot_path <- plot_shots(events, selected_match_id, selected_team)
  passes_path <- plot_progressive_passes(events, selected_match_id, selected_team)

  message("Equipo: ", selected_team)
  message("Mapa de tiros: ", normalizePath(shot_path, winslash = "/", mustWork = FALSE))
  message("Pases progresivos: ", normalizePath(passes_path, winslash = "/", mustWork = FALSE))

  invisible(list(team = selected_team, shot_map = shot_path, progressive_passes = passes_path))
}
