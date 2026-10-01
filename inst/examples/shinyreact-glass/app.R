# Liquid Glass + shinyreact.
# Run from this directory, or:
#   shiny::runApp(system.file("examples/shinyreact-glass", package = "shinyglass"))
#
# www/ui.js is built from window.shinyglass components (GlassPage,
# GlassSidebar, GlassSurface, GlassButton) and useGlassTheme(). There is
# no www/ui.css. Colors come from --glass-* on those classes.

library(shiny)
library(shinyreact)
library(shinyglass)

ui <- glass_page_react(
  theme = glass_theme(preset = "auto", scene = "tahoe", tint = FALSE),
  title = "shinyglass + shinyreact"
)

server <- function(input, output, session) {
  output$caption <- reactive_output({
    n <- input$bins
    if (is.null(n)) {
      return(NULL)
    }
    paste0(length(faithful$waiting), " eruptions in ", n, " bins")
  })

  output$dist <- renderPlot({
    n <- req(input$bins)
    # Server-drawn ink cannot read CSS variables. Follow the resolved pack.
    pal <- glass_plot_colors(input = input)
    op <- par(col.axis = pal$ink, col.lab = pal$ink, fg = pal$ink, col.main = pal$ink)
    on.exit(par(op), add = TRUE)
    hist(
      faithful$waiting,
      breaks = n,
      col = grDevices::adjustcolor(pal$fill, alpha.f = 0.6),
      border = NA,
      main = NULL,
      xlab = "Waiting time (minutes)",
      ylab = "Frequency"
    )
  }, bg = "transparent")

  output$extra <- reactive_output({
    if (!isTRUE(input$show_extra)) {
      return(NULL)
    }
    "Dynamic region is on. This string arrived as JSON."
  })
}

shinyApp(ui, server)
