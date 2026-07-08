# Modern bslib dashboard: value boxes, layout_columns, navset_card_tab.
#
# Run:
#   shiny::runApp(system.file("examples", "bslib-dashboard.R", package = "shinyglass"))
#
# Dark preset:
#   Sys.setenv(SHINYGLASS_PRESET = "dark")
#   shiny::runApp(system.file("examples", "bslib-dashboard.R", package = "shinyglass"))

library(shiny)
library(bslib)
library(shinyglass)

if (!requireNamespace("ggplot2", quietly = TRUE)) {
  stop("ggplot2 is required for this demo. Install with install.packages('ggplot2').")
}
if (!requireNamespace("DT", quietly = TRUE)) {
  stop("DT is required for this demo. Install with install.packages('DT').")
}
library(ggplot2)

glass_preset <- match.arg(
  Sys.getenv("SHINYGLASS_PRESET", "light"),
  c("light", "dark")
)

accent_colors <- c(
  "Apple Blue" = "#007AFF",
  "Purple" = "#AF52DE",
  "Orange" = "#FF9500",
  "Green" = "#34C759"
)

ui <- page_sidebar(
  title = "Glass Dashboard",
  theme = glass_theme(preset = glass_preset, primary = "#007AFF"),
  class = "bslib-page-dashboard",
  fillable = TRUE,
  sidebar = sidebar(
    title = "Dashboard",
    width = 280,
    selectInput(
      "preset",
      "Theme preset",
      choices = c("Light" = "light", "Dark" = "dark"),
      selected = glass_preset
    ),
    selectInput(
      "accent",
      "Accent color",
      choices = accent_colors,
      selected = "#007AFF"
    ),
    selectInput(
      "species",
      "Focus species",
      choices = c("All", "setosa", "versicolor", "virginica"),
      selected = "All"
    ),
    sliderInput("bins", "Histogram bins", 8, 40, 18),
    checkboxInput("show_curve", "Show density curve", TRUE),
    actionButton("refresh", "Refresh metrics", class = "btn-primary")
  ),
  layout_column_wrap(
    width = 1 / 3,
    fill = FALSE,
    value_box(
      title = "Observations",
      value = textOutput("metric_n"),
      theme = "primary"
    ),
    value_box(
      title = "Species",
      value = textOutput("metric_species"),
      theme = "success"
    ),
    value_box(
      title = "Avg sepal length",
      value = textOutput("metric_sepal"),
      theme = "info"
    )
  ),
  layout_columns(
    col_widths = c(6, 6),
    navset_card_tab(
      id = "tabs",
      nav_panel(
        "Distribution",
        card_body(
          plotOutput("dist_plot", height = "320px")
        )
      ),
      nav_panel(
        "Scatter",
        card_body(
          plotOutput("scatter_plot", height = "320px")
        )
      )
    ),
    card(
      full_screen = TRUE,
      card_header("Iris data"),
      DT::DTOutput("data_table")
    )
  )
)

server <- function(input, output, session) {
  filtered_data <- reactive({
    input$refresh
    df <- iris
    if (input$species != "All") {
      df <- df[df$Species == input$species, , drop = FALSE]
    }
    df
  })

  observeEvent(input$preset, {
    session$sendCustomMessage("glassPreset", input$preset)
  }, ignoreInit = TRUE)

  output$metric_n <- renderText({
    format(nrow(filtered_data()), big.mark = ",")
  })

  output$metric_species <- renderText({
    length(unique(filtered_data()$Species))
  })

  output$metric_sepal <- renderText({
    avg <- mean(filtered_data()$Sepal.Length, na.rm = TRUE)
    paste0(round(avg, 1), " cm")
  })

  plot_bg <- reactive({
    if (input$preset == "dark") "#14141a" else "#f8f9fc"
  })

  plot_fg <- reactive({
    if (input$preset == "dark") "#f5f5f7" else "black"
  })

  output$dist_plot <- renderPlot({
    df <- filtered_data()
    accent <- input$accent
    p <- ggplot(df, aes(x = Sepal.Length)) +
      geom_histogram(bins = input$bins, fill = accent, color = NA, alpha = 0.9) +
      labs(title = "Sepal length distribution", x = NULL, y = "Count") +
      theme_minimal(base_size = 13) +
      theme(
        panel.background = element_rect(fill = plot_bg(), color = NA),
        plot.background = element_rect(fill = plot_bg(), color = NA),
        text = element_text(color = plot_fg()),
        axis.text = element_text(color = plot_fg()),
        plot.title = element_text(color = plot_fg())
      )
    if (isTRUE(input$show_curve)) {
      p <- p + geom_density(
        aes(y = after_stat(count)),
        color = accent,
        linewidth = 1,
        alpha = 0.5
      )
    }
    print(p)
  }, height = 320)

  output$scatter_plot <- renderPlot({
    df <- filtered_data()
    accent <- input$accent
    ggplot(df, aes(x = Sepal.Length, y = Sepal.Width, color = Species)) +
      geom_point(size = 2.8, alpha = 0.85) +
      scale_color_manual(values = c("#007AFF", "#AF52DE", "#FF9500")) +
      labs(title = "Sepal dimensions", x = "Length", y = "Width") +
      theme_minimal(base_size = 13) +
      theme(
        panel.background = element_rect(fill = plot_bg(), color = NA),
        plot.background = element_rect(fill = plot_bg(), color = NA),
        text = element_text(color = plot_fg()),
        axis.text = element_text(color = plot_fg()),
        plot.title = element_text(color = plot_fg()),
        legend.text = element_text(color = plot_fg()),
        legend.title = element_text(color = plot_fg())
      )
  }, height = 320)

  output$data_table <- DT::renderDT({
    DT::datatable(
      filtered_data(),
      fillContainer = TRUE,
      rownames = FALSE,
      options = list(pageLength = 8, dom = "tip")
    )
  })
}

shinyApp(ui, server)