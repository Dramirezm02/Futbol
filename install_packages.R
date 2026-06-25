packages <- c(
  "bslib",
  "dplyr",
  "DT",
  "ggplot2",
  "httr2",
  "jsonlite",
  "knitr",
  "purrr",
  "readr",
  "rmarkdown",
  "shiny",
  "stringr",
  "tibble",
  "tidyr"
)

options(repos = c(CRAN = "https://cloud.r-project.org"))

missing_packages <- packages[!packages %in% rownames(installed.packages())]

if (length(missing_packages) > 0) {
  install.packages(missing_packages)
}

message("Paquetes listos: ", paste(packages, collapse = ", "))
