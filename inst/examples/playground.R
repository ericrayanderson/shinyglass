# Minimal glass_page() app — copy into https://shinylive.io/r/editor/
library(shiny)
library(shinyglass)

ui <- glass_page(
  title = "shinyglass playground",
  persist = TRUE,
  scene = "tahoe",
  sliderInput("n", "Points", 10, 80, 30),
  plotOutput("p", height = "280px")
)

server <- function(input, output, session) {
  observe_glass(input, session)
  output$p <- renderPlot({
    pal <- glass_plot_colors(input = input)
    plot(
      seq_len(input$n),
      sin(seq_len(input$n) / 4),
      col = pal$fill,
      pch = 16,
      xlab = NULL,
      ylab = NULL,
      fg = pal$ink,
      col.axis = pal$ink,
      col.lab = pal$ink
    )
  }, bg = "transparent")
}

shinyApp(ui, server)
