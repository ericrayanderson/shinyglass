# Liquid Glass + shinyreact.
# Run from this directory:
#   shiny::runApp(system.file("examples/shinyreact-glass", package = "shinyglass"))
#
# The React client owns the DOM (www/ui.js). glass_page_react() attaches
# glass_theme() as theme= so Bootstrap and the glass CSS are not suppressed.

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
    dark <- identical(glass_resolved_preset(input), "dark")
    ink <- if (dark) "#f5f5f7" else "#1d1d1f"
    op <- par(col.axis = ink, col.lab = ink, fg = ink, col.main = ink)
    on.exit(par(op), add = TRUE)
    hist(
      faithful$waiting,
      breaks = n,
      col = "#007AFF99",
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
