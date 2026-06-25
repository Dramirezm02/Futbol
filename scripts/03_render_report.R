library(rmarkdown)

rstudio_pandoc <- "C:/Program Files/RStudio/resources/app/bin/quarto/bin/tools"
if (dir.exists(rstudio_pandoc) && !nzchar(Sys.getenv("RSTUDIO_PANDOC"))) {
  Sys.setenv(RSTUDIO_PANDOC = rstudio_pandoc)
}

dir.create("docs", recursive = TRUE, showWarnings = FALSE)

rmarkdown::render(
  input = "reports/football_performance_report.Rmd",
  output_file = "../docs/index.html",
  knit_root_dir = getwd(),
  quiet = FALSE,
  envir = new.env(parent = globalenv())
)
