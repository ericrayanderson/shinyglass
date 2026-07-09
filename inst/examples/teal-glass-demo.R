# Minimal teal app with shinyglass.
#
# Teal applies Bootstrap themes via options(teal.bs_theme = ...):
#   https://insightsengineering.github.io/teal/latest-tag/articles/bootstrap-themes-in-teal.html
#
# Run:
#   shiny::runApp("inst/examples/teal-glass-demo.R")
#
# Requires: teal

if (!requireNamespace("teal", quietly = TRUE)) {
  stop("Install teal: install.packages(\"teal\")", call. = FALSE)
}

# Prefer dev package sources when running from a checkout
if (requireNamespace("pkgload", quietly = TRUE) &&
      file.exists("DESCRIPTION") &&
      grepl("shinyglass", readLines("DESCRIPTION", n = 1L), fixed = TRUE)) {
  try(pkgload::load_all(".", quiet = TRUE), silent = TRUE)
}

library(teal)
library(shinyglass)

glass_preset <- match.arg(Sys.getenv("SHINYGLASS_PRESET", "light"), c("light", "dark"))
options(teal.bs_theme = glass_theme(preset = glass_preset))

data <- teal_data()
data <- within(data, {
  IRIS <- iris
  MTCARS <- mtcars
})

app <- init(
  data = data,
  filter = teal_slices(
    teal_slice(dataname = "IRIS", varname = "Species"),
    teal_slice(dataname = "IRIS", varname = "Sepal.Length"),
    teal_slice(dataname = "MTCARS", varname = "gear", multiple = FALSE)
  ),
  modules = modules(
    example_module(label = "Example module")
  )
) |>
  modify_title(title = "teal + shinyglass") |>
  modify_header(
    tags$span(
      style = "font-size: 1.35rem; font-weight: 600; letter-spacing: -0.02em;",
      "Liquid Glass teal demo"
    )
  )

shinyApp(app$ui, app$server)
