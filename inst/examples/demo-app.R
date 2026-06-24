library(shiny)
library(bslib)
library(ggplot2)
library(shinyglass)

ui <- fluidPage(
  theme = glass_theme(),
  titlePanel("Liquid Glass"),
  layout_column_wrap(
    width = 1 / 2,
    card(
      card_header("Form Controls"),
      selectInput("species", "Species", c("setosa", "versicolor", "virginica")),
      sliderInput("bins", "Bins", 1, 50, 20),
      checkboxInput("smooth", "Show smooth", TRUE),
      actionButton("go", "Go", class = "btn-primary")
    ),
    card(
      card_header("Plot"),
      plotOutput("dist_plot", height = "260px")
    )
  )
)

server <- function(input, output, session) {
  output$dist_plot <- renderPlot({
    x <- faithful$waiting
    ggplot(data.frame(x = x), aes(x)) +
      geom_histogram(bins = input$bins, fill = "#007AFF", color = "white") +
      labs(title = "Faithful Waiting Times", x = "Waiting (minutes)", y = NULL) +
      theme_minimal(base_size = 13)
  }, height = 260)
}

shinyApp(ui, server)