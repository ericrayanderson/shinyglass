# Liquid Glass reference app for shinyglass visual validation.
# Exercises: page_sidebar overlay, pill tabs, content-aware tinting, DT tables.
#
# Run:
#   shiny::runApp(system.file("examples", "apple-glass-reference.R", package = "shinyglass"))
#
# Dark preset:
#   Sys.setenv(SHINYGLASS_PRESET = "dark")
#   shiny::runApp(system.file("examples", "apple-glass-reference.R", package = "shinyglass"))

library(shiny)
library(bslib)
library(shinyglass)

if (!requireNamespace("ggplot2", quietly = TRUE)) {
  stop("ggplot2 is required for this reference app.")
}
if (!requireNamespace("DT", quietly = TRUE)) {
  stop("DT is required for this reference app.")
}
library(ggplot2)

glass_preset <- match.arg(
  Sys.getenv("SHINYGLASS_PRESET", "light"),
  c("light", "dark")
)

palette_colors <- list(
  Ocean = c("#007AFF", "#5AC8FA", "#34C759"),
  Sunset = c("#FF9500", "#FF2D55", "#AF52DE"),
  Forest = c("#34C759", "#30B0C7", "#5856D6")
)

ui <- page_sidebar(
  title = "Liquid Glass Reference",
  theme = glass_theme(preset = glass_preset),
  fillable = TRUE,
  sidebar = sidebar(
    title = "Controls",
    width = 280,
    selectInput(
      "palette",
      "Chart palette",
      choices = names(palette_colors),
      selected = "Ocean"
    ),
    selectizeInput(
      "species",
      "Species (selectize)",
      choices = c("setosa", "versicolor", "virginica"),
      selected = "setosa"
    ),
    sliderInput("bins", "Histogram bins", min = 8, max = 40, value = 18),
    checkboxInput("density", "Show density curve", TRUE),
    glass_preset_input(
      "preset",
      label = "Theme preset",
      selected = glass_preset,
      choices = c("Light" = "light", "Dark" = "dark"),
      width = "100%"
    ),
    actionButton("notify", "Show notification", class = "btn-primary"),
    tags$hr(),
    tags$small(
      class = "text-muted",
      "Theme preset switches glass live. ",
      "Launch with SHINYGLASS_PRESET=dark to start in dark."
    )
  ),
  p(
    class = "text-muted",
    "Validates shinyglass Liquid Glass goals: translucent chrome ",
    "floating above full-bleed content, informed by surrounding color."
  ),
  navset_card_tab(
    id = "tabs",
    nav_panel(
      "Chart",
      div(
        class = "glass-content-hero",
        plotOutput("hero_plot", height = "340px")
      )
    ),
    nav_panel(
      "Data",
      DT::DTOutput("hero_dt")
    ),
    nav_panel(
      "Checklist",
      tags$ul(
        tags$li("page_sidebar overlay — glass sidebar floats above full-bleed main"),
        tags$li("Pill tab bar — compact on scroll down, expand on scroll up"),
        tags$li("Content-aware tint sampled from the chart"),
        tags$li("Selectize dropdown with glass menu styling"),
        tags$li("DT table with glass wrapper, striped rows, and glass pagination"),
        tags$li("Pointer-driven specular highlights on glass surfaces"),
        tags$li("Dark preset via glass_theme(preset = \"dark\")"),
        tags$li("Compare against ", tags$a(
          href = "https://developer.apple.com/documentation/TechnologyOverviews/adopting-liquid-glass",
          "Adopting Liquid Glass design notes"
        ))
      ),
      tags$p(tags$strong("Scroll this tab"), " to test navigation morph."),
      tags$div(
        style = "min-height: 120vh; padding-bottom: 4rem;",
        lapply(seq_len(18), function(i) {
          tags$p(paste("Scroll section", i, "— navigation should compact while scrolling down."))
        })
      )
    )
  )
)

server <- function(input, output, session) {
  plot_data <- reactive({
    cols <- palette_colors[[input$palette]]
    iris |>
      subset(Species == input$species) |>
      transform(accent = cols[1], accent2 = cols[2])
  })

  observe_glass_preset_input(input, session, "preset")

  output$hero_plot <- renderPlot({
    df <- plot_data()
    cols <- palette_colors[[input$palette]]
    preset <- glass_resolved_preset(input)
    # Light mode sits on a pale card. Opaque paper and darker ink keep the
    # points, axes, labels, and density readable. Dark keeps a clear panel.
    surface <- if (identical(preset, "light")) "opaque" else "clear"
    ink <- if (identical(preset, "dark")) "#f5f5f7" else "#1d1d1f"
    grid <- grDevices::adjustcolor(ink, alpha.f = if (identical(preset, "dark")) 0.28 else 0.38)

    p <- ggplot(df, aes(x = Sepal.Length, y = Sepal.Width, color = Species)) +
      geom_point(size = 3.4, alpha = 1) +
      scale_color_manual(values = cols) +
      labs(
        title = paste("Iris —", input$palette, "palette"),
        x = "Sepal length",
        y = "Sepal width"
      ) +
      theme_glass(preset, base_size = 14, surface = surface) +
      theme(
        legend.position = "bottom",
        panel.grid.major = element_line(color = grid, linewidth = 0.45),
        axis.line = element_line(color = ink, linewidth = 0.45),
        axis.ticks = element_line(color = ink, linewidth = 0.4)
      )

    if (isTRUE(input$density)) {
      p <- p + geom_density(
        aes(x = Sepal.Length),
        inherit.aes = FALSE,
        fill = cols[[2]],
        alpha = if (identical(preset, "light")) 0.55 else 0.35,
        color = cols[[1]],
        linewidth = 0.7
      )
    }

    print(p)
  }, bg = "transparent", height = 340)

  output$hero_dt <- DT::renderDT({
    DT::datatable(
      plot_data()[, c("Sepal.Length", "Sepal.Width", "Petal.Length", "Species")],
      options = list(
        pageLength = 8,
        dom = "lftip",
        lengthMenu = c(5, 8, 12, 20)
      ),
      rownames = FALSE,
      class = "stripe hover cell-border"
    )
  })

  observeEvent(input$notify, {
    showNotification(
      paste("Glass tint driven by", input$palette, "content"),
      type = "message",
      duration = 4
    )
  })
}

shinyApp(ui, server)