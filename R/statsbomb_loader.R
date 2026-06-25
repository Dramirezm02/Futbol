base_url <- "https://raw.githubusercontent.com/statsbomb/open-data/master/data"

fetch_json <- function(path) {
  url <- paste0(base_url, "/", path)
  response <- httr2::request(url) |>
    httr2::req_timeout(30) |>
    httr2::req_perform()

  text <- httr2::resp_body_string(response)
  jsonlite::fromJSON(text, simplifyVector = FALSE)
}

write_json <- function(data, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  jsonlite::write_json(data, path, auto_unbox = TRUE, pretty = TRUE)
}

load_competitions <- function(raw_dir = "data/raw") {
  data <- fetch_json("competitions.json")
  write_json(data, file.path(raw_dir, "competitions.json"))
  data
}

load_matches <- function(competition_id, season_id, raw_dir = "data/raw") {
  data <- fetch_json(glue_path("matches", competition_id, paste0(season_id, ".json")))
  write_json(data, file.path(raw_dir, "matches", competition_id, paste0(season_id, ".json")))
  data
}

load_events <- function(match_id, raw_dir = "data/raw") {
  data <- fetch_json(glue_path("events", paste0(match_id, ".json")))
  write_json(data, file.path(raw_dir, "events", paste0(match_id, ".json")))
  data
}

load_lineups <- function(match_id, raw_dir = "data/raw") {
  data <- fetch_json(glue_path("lineups", paste0(match_id, ".json")))
  write_json(data, file.path(raw_dir, "lineups", paste0(match_id, ".json")))
  data
}

load_three_sixty <- function(match_id, raw_dir = "data/raw") {
  tryCatch(
    {
      data <- fetch_json(glue_path("three-sixty", paste0(match_id, ".json")))
      write_json(data, file.path(raw_dir, "three-sixty", paste0(match_id, ".json")))
      data
    },
    error = function(error) {
      message("Datos 360 no disponibles para match_id=", match_id)
      NULL
    }
  )
}

glue_path <- function(...) {
  paste(..., sep = "/")
}

nested_value <- function(x, ...) {
  keys <- c(...)
  value <- x

  for (key in keys) {
    if (is.null(value) || !is.list(value) || is.null(value[[key]])) {
      return(NA)
    }
    value <- value[[key]]
  }

  if (is.list(value)) {
    if (!is.null(value$name)) {
      return(value$name)
    }

    name_key <- names(value)[stringr::str_detect(names(value), "_name$")]
    if (length(name_key) > 0) {
      return(value[[name_key[[1]]]])
    }
  }

  if (length(value) == 0) {
    return(NA)
  }

  value
}

xy <- function(value, index) {
  if (is.null(value) || length(value) < index) {
    return(NA_real_)
  }
  as.numeric(value[[index]])
}

select_match <- function(matches, match_id = NULL) {
  if (!is.null(match_id)) {
    selected <- Filter(function(match) match$match_id == match_id, matches)
    if (length(selected) == 0) {
      stop("No encontre el partido ", match_id, " en la competencia/temporada elegida.")
    }
    return(selected[[1]])
  }

  dates <- vapply(matches, function(match) paste(match$match_date, match$kick_off %||% ""), character(1))
  matches[[order(dates, decreasing = TRUE)[1]]]
}

`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}
