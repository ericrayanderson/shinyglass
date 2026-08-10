# iOS 27 Liquid Glass intensity slider demo.
# Ultra Clear (0) ←————→ Tinted (1)
#
# Run:
#   shiny::runApp(system.file("examples", "intensity-slider-demo.R", package = "shinyglass"))
#
# Dark:
#   Sys.setenv(SHINYGLASS_PRESET = "dark")
#   shiny::runApp(system.file("examples", "intensity-slider-demo.R", package = "shinyglass"))

library(shiny)
library(bslib)
library(shinyglass)

if (!requireNamespace("ggplot2", quietly = TRUE)) {
  stop("ggplot2 is required. install.packages('ggplot2')")
}
library(ggplot2)

glass_preset <- match.arg(
  Sys.getenv("SHINYGLASS_PRESET", "light"),
  c("light", "dark", "auto")
)

ui <- page_fillable(
  theme = glass_theme(
    preset = glass_preset,
    primary = "#007AFF",
    intensity = 0.45
  ),
  padding = "1rem",
  gap = "0.85rem",
  layout_columns(
    col_widths = breakpoints(xs = c(12, 12), md = c(4, 8)),
    card(
      card_header("Liquid Glass intensity"),
      tags$p(
        class = "text-muted",
        style = "font-size:0.9rem;margin-bottom:0.75rem;",
        "iOS 27 Appearance → Liquid Glass. Drag Ultra Clear → Tinted; ",
        "surfaces update live (no reload)."
      ),
      glass_intensity_slider(
        "glass_intensity",
        label = NULL,
        value = 0.45,
        preview = TRUE
      ),
      tags$hr(),
      glass_theme_toggle(selected = glass_preset),
      tags$hr(),
      selectInput(
        "accent",
        "Accent",
        choices = c(
          "Blue" = "#007AFF",
          "Purple" = "#AF52DE",
          "Orange" = "#FF9500",
          "Green" = "#34C759"
        ),
        selected = "#007AFF",
        width = "100%"
      ),
      sliderInput("n", "Points", 40, 200, 90, width = "100%"),
      checkboxInput("show_smooth", "Density curve", TRUE),
      tags$p(
        class = "text-muted",
        style = "font-size:0.78rem;margin-top:0.75rem;margin-bottom:0;",
        textOutput("intensity_label", inline = TRUE)
      )
    ),
    div(
      layout_column_wrap(
        width = "9rem",
        fill = FALSE,
        gap = "0.65rem",
        value_box(
          title = "Look",
          value = textOutput("vb_look"),
          theme = "primary"
        ),
        value_box(
          title = "Intensity",
          value = textOutput("vb_intensity"),
          theme = "info"
        ),
        value_box(
          title = "Points",
          value = textOutput("vb_n"),
          theme = "success"
        )
      ),
      tags$div(style = "height:0.75rem;"),
      card(
        full_screen = TRUE,
        card_header("Content under glass"),
        plotOutput("hero", height = "300px")
      ),
      tags$div(style = "height:0.75rem;"),
      layout_column_wrap(
        width = 1 / 2,
        fill = FALSE,
        gap = "0.65rem",
        card(
          card_header("Chrome"),
          tags$p(
            style = "margin:0;font-size:0.9rem;",
            "Floating chrome uses true glass — watch the fill thicken as you tint."
          )
        ),
        card(
          card_header("Content"),
          tags$p(
            style = "margin:0;font-size:0.9rem;",
            "Content cards stay slightly denser so hierarchy stays clear."
          )
        )
      )
    )
  )
)

server <- function(input, output, session) {
  observe_glass_theme_toggle(input, session)
  observe_glass_intensity(input, session, "glass_intensity")

  observeEvent(input$accent, {
    update_glass_theme(session, primary = input$accent)
  }, ignoreInit = TRUE)

  intensity_val <- reactive({
    v <- input$glass_intensity
    if (is.null(v) || length(v) != 1L || is.na(v)) 0.45 else as.numeric(v)
  })

  output$intensity_label <- renderText({
    v <- intensity_val()
    sprintf(
      "Current intensity: %.0f%%  ·  %s",
      100 * v,
      if (v < 0.33) "Ultra Clear" else if (v > 0.66) "Tinted" else "Balanced"
    )
  })

  output$vb_look <- renderText({
    v <- intensity_val()
    if (v < 0.33) "Ultra Clear" else if (v > 0.66) "Tinted" else "Balanced"
  })

  output$vb_intensity <- renderText({
    sprintf("%.0f%%", 100 * intensity_val())
  })

  output$vb_n <- renderText({
    as.character(input$n)
  })

  output$hero <- renderPlot({
    set.seed(1)
    n <- input$n
    df <- data.frame(
      x = rnorm(n, 5, 1.2),
      g = sample(c("A", "B", "C"), n, replace = TRUE)
    )
    cols <- c(A = "#007AFF", B = "#AF52DE", C = "#FF9500")
    p <- ggplot(df, aes(x, fill = g, color = g)) +
      geom_histogram(bins = 22, alpha = 0.72, position = "identity", linewidth = 0) +
      scale_fill_manual(values = cols) +
      scale_color_manual(values = cols) +
      labs(x = NULL, y = NULL, fill = NULL, color = NULL) +
      theme_void(base_size = 14) +
      theme(
        legend.position = "bottom",
        plot.background = element_rect(fill = "transparent", color = NA),
        panel.background = element_rect(fill = "transparent", color = NA)
      )
    if (isTRUE(input$show_smooth)) {
      p <- p + geom_density(aes(y = after_stat(count)), linewidth = 1.1, fill = NA)
    }
    p
  }, bg = "transparent", res = 96)
}

shinyApp(ui, server)
