library(shiny)
library(bslib)
library(ggplot2)
library(shinyglass)

ui <- glass_page(
  title = "Liquid Glass",
  persist = TRUE,
  scene = "tahoe",
  layout_column_wrap(
    width = 280,
    gap = "0.75rem",
    card(
      card_header("Form Controls"),
      selectInput("species", "Species", c("setosa", "versicolor", "virginica"), width = "100%"),
      sliderInput("bins", "Bins", 1, 50, 20, width = "100%"),
      checkboxInput("smooth", "Show smooth", TRUE)
    ),
    card(
      card_header("Plot"),
      plotOutput("dist_plot", height = "260px")
    )
  )
)

server <- function(input, output, session) {
  observe_glass(input, session)

  output$dist_plot <- renderPlot({
    req(input$species)
    x <- iris$Sepal.Length[iris$Species == input$species]
    df <- data.frame(x = x)
    pal <- glass_plot_colors(input = input)
    fill <- if (!is.null(input$glass_accent) && nzchar(input$glass_accent)) {
      input$glass_accent
    } else {
      pal$fill
    }
    p <- ggplot(df, aes(x)) +
      geom_histogram(bins = input$bins, fill = fill, color = NA, alpha = 0.88) +
      labs(title = paste("Sepal length:", input$species), x = "Sepal length (cm)", y = NULL) +
      theme_glass(input = input)
    if (isTRUE(input$smooth)) {
      p <- p + geom_density(
        aes(y = after_stat(count)),
        color = "#AF52DE",
        linewidth = 1.15
      )
    }
    p
  }, bg = "transparent", height = 260, res = 96)
}

shinyApp(ui, server)
