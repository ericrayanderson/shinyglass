# querychat + shinyglass: natural-language filtering with a glass dashboard.
#
# Run:
#   shiny::runApp(system.file("examples", "querychat-demo.R", package = "shinyglass"))
#
# Chat requires an LLM API key (e.g. Sys.setenv(OPENAI_API_KEY = "...")).
# Quick-filter buttons work without an API key.
#
# Install:
#   install.packages(c("querychat", "duckdb", "DT", "ggplot2"))

library(shiny)
library(bslib)
library(shinyglass)

for (pkg in c("querychat", "duckdb", "DT", "ggplot2")) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    stop(pkg, " is required. Install with install.packages('", pkg, "').", call. = FALSE)
  }
}
library(querychat)
library(ggplot2)

glass_preset <- match.arg(
  Sys.getenv("SHINYGLASS_PRESET", "light"),
  c("light", "dark")
)

qc <- QueryChat$new(iris)

ui <- page_sidebar(
  title = "Iris Explorer",
  theme = glass_theme(preset = glass_preset),
  class = "bslib-page-dashboard",
  fillable = TRUE,
  sidebar = sidebar(
    title = "Ask your data",
    width = 320,
    qc$ui(),
    tags$hr(),
    tags$small(class = "text-muted", "Quick filters (no API key):"),
    div(
      class = "d-grid gap-2",
      actionButton("filter_all", "All species", class = "btn-outline-primary"),
      actionButton("filter_setosa", "Setosa only", class = "btn-outline-primary"),
      actionButton("filter_virginica", "Virginica only", class = "btn-outline-primary"),
      actionButton("reset_filters", "Reset", class = "btn-secondary")
    ),
    tags$hr(),
    selectInput(
      "preset",
      "Theme preset",
      choices = c("Light" = "light", "Dark" = "dark"),
      selected = glass_preset
    )
  ),
  layout_column_wrap(
    width = 1 / 3,
    fill = FALSE,
    value_box(
      title = "Rows",
      value = textOutput("metric_n"),
      theme = "primary"
    ),
    value_box(
      title = "Species",
      value = textOutput("metric_species"),
      theme = "success"
    ),
    value_box(
      title = "Avg petal width",
      value = textOutput("metric_petal"),
      theme = "info"
    )
  ),
  layout_columns(
    col_widths = c(7, 5),
    card(
      full_screen = TRUE,
      card_header(textOutput("table_title")),
      DT::DTOutput("data_table")
    ),
    card(
      card_header("Species counts"),
      plotOutput("species_plot", height = "280px")
    )
  ),
  card(
    card_header("SQL query"),
    verbatimTextOutput("sql_query")
  )
)

server <- function(input, output, session) {
  qc_vals <- qc$server()

  observeEvent(input$preset, {
    session$sendCustomMessage("glassPreset", input$preset)
  }, ignoreInit = TRUE)

  observeEvent(input$filter_all, {
    qc_vals$sql("")
    qc_vals$title("All species")
  })
  observeEvent(input$filter_setosa, {
    qc_vals$sql("SELECT * FROM iris WHERE Species = 'setosa'")
    qc_vals$title("Setosa only")
  })
  observeEvent(input$filter_virginica, {
    qc_vals$sql("SELECT * FROM iris WHERE Species = 'virginica'")
    qc_vals$title("Virginica only")
  })
  observeEvent(input$reset_filters, {
    qc_vals$sql("")
    qc_vals$title(NULL)
  })

  output$metric_n <- renderText({
    format(nrow(qc_vals$df()), big.mark = ",")
  })

  output$metric_species <- renderText({
    length(unique(qc_vals$df()$Species))
  })

  output$metric_petal <- renderText({
    avg <- mean(qc_vals$df()$Petal.Width, na.rm = TRUE)
    paste0(round(avg, 2), " cm")
  })

  output$table_title <- renderText({
    qc_vals$title() %||% "All iris rows"
  })

  output$data_table <- DT::renderDT({
    DT::datatable(
      qc_vals$df(),
      fillContainer = TRUE,
      rownames = FALSE,
      options = list(pageLength = 8, dom = "tip", scrollX = TRUE)
    )
  })

  output$species_plot <- renderPlot({
    df <- qc_vals$df()
    counts <- as.data.frame(table(df$Species), stringsAsFactors = FALSE)
    names(counts) <- c("Species", "Count")
    accent <- if (identical(input$preset, "dark")) "#0A84FF" else "#007AFF"
    plot_bg <- if (identical(input$preset, "dark")) "#14141a" else "#f8f9fc"
    plot_fg <- if (identical(input$preset, "dark")) "#f5f5f7" else "black"

    ggplot(counts, aes(x = Species, y = Count, fill = Species)) +
      geom_col(fill = accent, width = 0.62, alpha = 0.92) +
      labs(x = NULL, y = NULL, title = NULL) +
      theme_minimal(base_size = 13) +
      theme(
        panel.background = element_rect(fill = plot_bg, color = NA),
        plot.background = element_rect(fill = plot_bg, color = NA),
        axis.text = element_text(color = plot_fg),
        axis.title = element_text(color = plot_fg),
        legend.position = "none"
      )
  }, height = 280)

  output$sql_query <- renderText({
    qc_vals$sql() %||% "SELECT * FROM iris"
  })
}

shinyApp(ui, server)