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
  Sys.getenv("SHINYGLASS_PRESET", "auto"),
  c("light", "dark", "auto")
)

accent_colors <- c(
  "Apple Blue" = "#007AFF",
  "Purple" = "#AF52DE",
  "Orange" = "#FF9500",
  "Green" = "#34C759"
)

ui <- page_sidebar(
  title = "Glass Dashboard",
  theme = glass_theme(preset = glass_preset, primary = "#007AFF", intensity = 0.45),
  class = "bslib-page-dashboard",
  fillable = TRUE,
  # Closed on phones by default so content is usable; open on desktop
  sidebar = sidebar(
    title = "Dashboard",
    width = 280,
    open = "desktop",
    glass_intensity_slider(
      "glass_intensity",
      label = "Liquid Glass",
      value = 0.45,
      preview = TRUE
    ),
    glass_preset_input(
      "preset",
      label = "Theme preset",
      selected = glass_preset,
      width = "100%"
    ),
    selectInput(
      "accent",
      "Accent color",
      choices = accent_colors,
      selected = "#007AFF",
      width = "100%"
    ),
    selectInput(
      "species",
      "Focus species",
      choices = c("All", "setosa", "versicolor", "virginica"),
      selected = "All",
      width = "100%"
    ),
    sliderInput("bins", "Histogram bins", 8, 40, 18, width = "100%"),
    checkboxInput("show_curve", "Show density curve", TRUE),
    actionButton("refresh", "Refresh metrics", class = "btn-primary", width = "100%")
  ),
  # Stack value boxes on narrow screens (min width ~10rem)
  layout_column_wrap(
    width = "10rem",
    fill = FALSE,
    gap = "0.65rem",
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
  # Full-width stack below md; two columns from md up
  layout_columns(
    col_widths = breakpoints(
      xs = c(12, 12),
      md = c(6, 6)
    ),
    gap = "0.75rem",
    navset_card_tab(
      id = "tabs",
      nav_panel(
        "Distribution",
        card_body(
          plotOutput("dist_plot", height = "280px")
        )
      ),
      nav_panel(
        "Scatter",
        card_body(
          plotOutput("scatter_plot", height = "280px")
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

  observe_glass_intensity(input, session, "glass_intensity")
  observe_glass_preset_input(input, session, "preset")

  observeEvent(input$accent, {
    update_glass_theme(session, primary = input$accent)
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
    # "auto" uses a neutral light panel; pure dark when forced dark.
    if (identical(input$preset, "dark")) "#14141a" else "#f8f9fc"
  })

  plot_fg <- reactive({
    if (identical(input$preset, "dark")) "#f5f5f7" else "black"
  })

  output$dist_plot <- renderPlot({
    df <- filtered_data()
    accent <- input$accent
    p <- ggplot(df, aes(x = Sepal.Length)) +
      geom_histogram(bins = input$bins, fill = accent, color = NA, alpha = 0.9) +
      labs(title = "Sepal length distribution", x = NULL, y = "Count") +
      theme_minimal(base_size = 12) +
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
  }, height = 280, res = 96)

  output$scatter_plot <- renderPlot({
    df <- filtered_data()
    accent <- input$accent
    ggplot(df, aes(x = Sepal.Length, y = Sepal.Width, color = Species)) +
      geom_point(size = 2.4, alpha = 0.85) +
      scale_color_manual(values = c("#007AFF", "#AF52DE", "#FF9500")) +
      labs(title = "Sepal dimensions", x = "Length", y = "Width") +
      theme_minimal(base_size = 12) +
      theme(
        panel.background = element_rect(fill = plot_bg(), color = NA),
        plot.background = element_rect(fill = plot_bg(), color = NA),
        text = element_text(color = plot_fg()),
        axis.text = element_text(color = plot_fg()),
        plot.title = element_text(color = plot_fg()),
        legend.text = element_text(color = plot_fg()),
        legend.title = element_text(color = plot_fg()),
        legend.position = "bottom"
      )
  }, height = 280, res = 96)

  output$data_table <- DT::renderDT({
    DT::datatable(
      filtered_data(),
      fillContainer = FALSE,
      rownames = FALSE,
      options = list(
        pageLength = 6,
        dom = "tip",
        scrollX = TRUE,
        autoWidth = TRUE
      )
    )
  })
}

shinyApp(ui, server)
