# Shared, deterministic real-Shiny fixture for integration and performance checks.
# Run from inst/scripts/browser: Rscript shiny-app.R
pkgload::load_all("../../..", quiet = TRUE)
library(shiny)
library(shinyglass)

controls_ui <- function(id) {
  ns <- NS(id)
  tagList(
    glass_theme_toggle(ns("mode"), selected = "auto"),
    glass_intensity_slider(ns("intensity"), value = 0.25),
    textOutput(ns("value"))
  )
}
controls_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    observe_glass_theme_toggle(input, session, "mode")
    output$value <- renderText(input$intensity)
  })
}
ui <- function(request) {
  args <- parseQueryString(request$QUERY_STRING)
  variant <- args$variant
  if (is.null(variant)) variant <- "glass"
  theme <- switch(variant,
    plain = bslib::bs_theme(version = 5, primary = "#007AFF"),
    static = glass_theme(preset = "auto", tint = FALSE, specular = FALSE,
                         nav_morph = FALSE, ambient_motion = FALSE),
    glass_theme(preset = "auto")
  )
  bslib::page_sidebar(
    title = "Runtime validation",
    theme = theme,
    sidebar = bslib::sidebar(
      if (variant != "plain") controls_ui("module"),
      actionButton("server_update", "Server update"),
      actionButton("insert", "Insert slider"),
      actionButton("advance", "Advance workload"),
      div(id = "dynamic"),
      textOutput("resolved"), textOutput("render_count"),
      textOutput("benchmark_result")
    ),
    bslib::layout_columns(
      bslib::card(bslib::card_header("Distribution"), plotOutput("plot")),
      bslib::card(bslib::card_header("Trend"), plotOutput("trend")),
      bslib::card(bslib::card_header("Data"), tableOutput("table")),
      col_widths = c(6, 6, 12)
    )
  )
}
server <- function(input, output, session) {
  # Standalone runApp has no hosting proxy advertising reconnect support.
  # Force a real new-session reconnect while retaining the browser's inputs.
  session$allowReconnect("force")
  controls_server("module")
  renders <- reactiveVal(0L)
  timing <- reactiveVal(list(iteration = 0L, server_compute_ms = 0))
  set.seed(42)
  x <- rnorm(20000)
  output$plot <- renderPlot({
    preset <- glass_resolved_preset(input)
    n <- input$advance
    start <- proc.time()[["elapsed"]]
    values <- sin(x + n / 10)
    par(col.axis = if (preset == "dark") "white" else "black")
    hist(values, breaks = 60, col = "#007AFF", border = NA, main = "Distribution")
    timing(list(iteration = n, server_compute_ms = 1000 * (proc.time()[["elapsed"]] - start)))
    renders(isolate(renders()) + 1L)
  }, bg = "transparent")
  output$trend <- renderPlot({
    plot(head(x, 1000) + input$advance / 10, type = "l", col = "#007AFF")
  }, bg = "transparent")
  output$table <- renderTable({
    data.frame(index = seq_len(50), value = round(head(x, 50) + input$advance, 3))
  })
  output$benchmark_result <- renderText(jsonlite::toJSON(timing(), auto_unbox = TRUE))
  output$render_count <- renderText(renders())
  output$resolved <- renderText(glass_resolved_preset(input))
  observeEvent(input$server_update, {
    update_glass_theme(session, preset = "dark", intensity = 0.8, primary = "#AF52DE")
  })
  observeEvent(input$insert, {
    insertUI("#dynamic", ui = glass_intensity_slider(
      paste0("inserted", input$insert), value = 0.6, label = NULL
    ))
  })
}
runApp(shinyApp(ui, server), host = "127.0.0.1", port = 3941, launch.browser = FALSE)
