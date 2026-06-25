safe_divide <- function(x, y) {
  ifelse(y == 0 | is.na(y), 0, x / y)
}

scale_0_100 <- function(x) {
  if (all(is.na(x)) || diff(range(x, na.rm = TRUE)) == 0) {
    return(rep(50, length(x)))
  }

  round((x - min(x, na.rm = TRUE)) / diff(range(x, na.rm = TRUE)) * 100, 1)
}

team_xg <- function(summary_table, team_name) {
  value <- summary_table |>
    dplyr::filter(team == team_name) |>
    dplyr::pull(xg)

  if (length(value) == 0 || is.na(value)) {
    stop("No xG found for team: ", team_name)
  }

  as.numeric(value[[1]])
}

poisson_match_model <- function(summary_table, team_a, team_b, max_goals = 6) {
  lambda_a <- team_xg(summary_table, team_a)
  lambda_b <- team_xg(summary_table, team_b)

  score_grid <- expand.grid(
    goals_a = 0:max_goals,
    goals_b = 0:max_goals
  ) |>
    dplyr::mutate(
      probability = stats::dpois(goals_a, lambda_a) * stats::dpois(goals_b, lambda_b),
      scoreline = paste0(goals_a, "-", goals_b),
      result = dplyr::case_when(
        goals_a > goals_b ~ paste(team_a, "win"),
        goals_a == goals_b ~ "Draw",
        TRUE ~ paste(team_b, "win")
      )
    )

  # Renormalize because the grid truncates very high scorelines.
  score_grid <- score_grid |>
    dplyr::mutate(probability = probability / sum(probability))

  outcome_probabilities <- score_grid |>
    dplyr::group_by(result) |>
    dplyr::summarise(probability = sum(probability), .groups = "drop") |>
    dplyr::mutate(probability_pct = round(probability * 100, 1)) |>
    dplyr::arrange(dplyr::desc(probability))

  top_scorelines <- score_grid |>
    dplyr::arrange(dplyr::desc(probability)) |>
    dplyr::slice_head(n = 8) |>
    dplyr::mutate(probability_pct = round(probability * 100, 1))

  list(
    team_a = team_a,
    team_b = team_b,
    lambda_a = lambda_a,
    lambda_b = lambda_b,
    score_grid = score_grid,
    outcome_probabilities = outcome_probabilities,
    top_scorelines = top_scorelines
  )
}

simulate_match_outcomes <- function(summary_table, team_a, team_b, n = 10000, seed = 2026) {
  set.seed(seed)
  lambda_a <- team_xg(summary_table, team_a)
  lambda_b <- team_xg(summary_table, team_b)

  simulations <- tibble::tibble(
    goals_a = stats::rpois(n, lambda_a),
    goals_b = stats::rpois(n, lambda_b),
    result = dplyr::case_when(
      goals_a > goals_b ~ paste(team_a, "win"),
      goals_a == goals_b ~ "Draw",
      TRUE ~ paste(team_b, "win")
    )
  )

  simulations |>
    dplyr::count(result, name = "simulations") |>
    dplyr::mutate(
      probability = simulations / n,
      probability_pct = round(probability * 100, 1)
    ) |>
    dplyr::arrange(dplyr::desc(probability))
}

plot_score_probability_heatmap <- function(model) {
  ggplot2::ggplot(model$score_grid, ggplot2::aes(x = goals_b, y = goals_a, fill = probability)) +
    ggplot2::geom_tile(color = "white", linewidth = 0.35) +
    ggplot2::geom_text(ggplot2::aes(label = sprintf("%.1f%%", probability * 100)), size = 3) +
    ggplot2::scale_fill_gradient(low = "#f7f6f2", high = "#0f2d4a", labels = function(x) paste0(round(x * 100, 1), "%")) +
    ggplot2::scale_x_continuous(breaks = sort(unique(model$score_grid$goals_b))) +
    ggplot2::scale_y_continuous(breaks = sort(unique(model$score_grid$goals_a))) +
    ggplot2::labs(
      title = "Probabilidad de marcador con modelo Poisson",
      subtitle = paste(model$team_a, "vs", model$team_b),
      x = paste("Goles", model$team_b),
      y = paste("Goles", model$team_a),
      fill = "Prob."
    ) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      panel.grid = ggplot2::element_blank(),
      plot.background = ggplot2::element_rect(fill = "white", color = NA),
      panel.background = ggplot2::element_rect(fill = "white", color = NA),
      plot.title = ggplot2::element_text(color = "#111111", face = "bold"),
      plot.subtitle = ggplot2::element_text(color = "#333333"),
      axis.text = ggplot2::element_text(color = "#333333"),
      axis.title = ggplot2::element_text(color = "#333333"),
      legend.text = ggplot2::element_text(color = "#333333"),
      legend.title = ggplot2::element_text(color = "#333333")
    )
}

player_advanced_summary <- function(events) {
  events |>
    dplyr::filter(!is.na(player), !is.na(team)) |>
    dplyr::group_by(team, player, position) |>
    dplyr::summarise(
      shots = sum(event_type == "Shot", na.rm = TRUE),
      xg = sum(shot_xg, na.rm = TRUE),
      passes = sum(event_type == "Pass", na.rm = TRUE),
      completed_passes = sum(event_type == "Pass" & is.na(pass_outcome), na.rm = TRUE),
      progressive_passes = sum(event_type == "Pass" & is.na(pass_outcome) & (pass_end_x - location_x) >= 15, na.rm = TRUE),
      pressures = sum(event_type == "Pressure", na.rm = TRUE),
      recoveries = sum(event_type == "Ball Recovery", na.rm = TRUE),
      interceptions = sum(event_type == "Interception", na.rm = TRUE),
      carries = sum(event_type == "Carry", na.rm = TRUE),
      progressive_carries = sum(event_type == "Carry" & (carry_end_x - location_x) >= 15, na.rm = TRUE),
      .groups = "drop"
    ) |>
    dplyr::mutate(
      pass_completion_pct = round(safe_divide(completed_passes, passes) * 100, 1),
      xg_score = scale_0_100(xg),
      progression_score = scale_0_100(progressive_passes + progressive_carries),
      defensive_score = scale_0_100(pressures + recoveries + interceptions),
      involvement_score = scale_0_100(passes + carries + shots),
      scouting_score = round(
        0.30 * xg_score +
          0.30 * progression_score +
          0.25 * defensive_score +
          0.15 * involvement_score,
        1
      )
    ) |>
    dplyr::arrange(dplyr::desc(scouting_score), dplyr::desc(xg))
}

player_radar_data <- function(player_table, player_name) {
  player_table |>
    dplyr::filter(player == player_name) |>
    dplyr::select(
      xg_score,
      progression_score,
      defensive_score,
      involvement_score,
      scouting_score
    ) |>
    tidyr::pivot_longer(
      cols = dplyr::everything(),
      names_to = "metric",
      values_to = "score"
    ) |>
    dplyr::mutate(
      metric = dplyr::recode(
        metric,
        xg_score = "xG",
        progression_score = "Progression",
        defensive_score = "Defense",
        involvement_score = "Involvement",
        scouting_score = "Scouting"
      )
    )
}

plot_player_radar <- function(player_table, player_name) {
  radar <- player_radar_data(player_table, player_name)

  ggplot2::ggplot(radar, ggplot2::aes(x = metric, y = score, group = 1)) +
    ggplot2::geom_polygon(fill = "#2364aa", alpha = 0.24, color = "#2364aa", linewidth = 1) +
    ggplot2::geom_point(color = "#ff5a3d", size = 3) +
    ggplot2::coord_polar() +
    ggplot2::ylim(0, 100) +
    ggplot2::labs(title = paste("Perfil radar -", player_name), x = NULL, y = NULL) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      plot.background = ggplot2::element_rect(fill = "white", color = NA),
      panel.background = ggplot2::element_rect(fill = "white", color = NA),
      panel.grid.minor = ggplot2::element_blank(),
      plot.title = ggplot2::element_text(color = "#111111", face = "bold"),
      axis.text.x = ggplot2::element_text(color = "#333333"),
      axis.text.y = ggplot2::element_blank()
    )
}
