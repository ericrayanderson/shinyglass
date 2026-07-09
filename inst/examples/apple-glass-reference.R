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
    radioButtons(
      "preset",
      "Tint preview",
      choices = c("Light" = "light", "Dark" = "dark"),
      selected = glass_preset,
      inline = TRUE
    ),
    actionButton("notify", "Show notification", class = "btn-primary"),
    tags$hr(),
    tags$small(
      class = "text-muted",
      "Launch with SHINYGLASS_PRESET=dark for the full dark theme. ",
      "Tint preview adjusts content-aware glass sampling only."
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

  observeEvent(input$preset, {
    session$sendCustomMessage("glassPreset", input$preset)
  }, ignoreInit = TRUE)

  output$hero_plot <- renderPlot({
    df <- plot_data()
    cols <- palette_colors[[input$palette]]
    plot_bg <- if (input$preset == "dark") "#14141a" else "#f8f9fc"
    text_col <- if (input$preset == "dark") "#f5f5f7" else "black"

    p <- ggplot(df, aes(x = Sepal.Length, y = Sepal.Width, color = Species)) +
      geom_point(size = 3, alpha = 0.85) +
      scale_color_manual(values = cols) +
      labs(
        title = paste("Iris —", input$palette, "palette"),
        x = "Sepal length",
        y = "Sepal width"
      ) +
      theme_minimal(base_size = 14) +
      theme(
        panel.background = element_rect(fill = plot_bg, color = NA),
        plot.background = element_rect(fill = plot_bg, color = NA),
        legend.position = "bottom",
        text = element_text(color = text_col),
        axis.text = element_text(color = text_col),
        axis.title = element_text(color = text_col),
        plot.title = element_text(color = text_col)
      )

    if (isTRUE(input$density)) {
      p <- p + geom_density(
        aes(x = Sepal.Length),
        inherit.aes = FALSE,
        fill = cols[[2]],
        alpha = 0.25,
        color = NA
      )
    }

    print(p)
  }, height = 340)

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