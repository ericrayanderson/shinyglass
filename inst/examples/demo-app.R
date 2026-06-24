library(shiny)
library(bslib) # for card(), layout_column_wrap()
library(shinyglass)

ui <- glass_page(
  title = "shinyglass demo",
  header = "Liquid Glass",
  glass_card(
    h3("One-line theming"),
    p(
      "Pass ",
      code("theme = glass_theme()"),
      " to any bslib page, or use ",
      code("glass_page()"),
      " for a ready-made layout."
    ),
    actionButton("standard_btn", "Standard Bootstrap Button", class = "btn-primary"),
    br(), br(),
    glass_button("glass_btn", "Glass Button"),
    textOutput("click_count")
  ),
  layout_column_wrap(
    width = 1 / 2,
    glass_card(
      h4("Form Controls"),
      selectInput("species", "Species", c("setosa", "versicolor", "virginica")),
      sliderInput("bins", "Bins", 1, 50, 20),
      checkboxInput("smooth", "Show smooth", TRUE)
    ),
    glass_card(
      h4("Plot"),
      plotOutput("dist_plot", height = "260px")
    )
  )
)

server <- function(input, output, session) {
  output$click_count <- renderText({
    paste(
      "Standard clicks:", input$standard_btn,
      "| Glass clicks:", input$glass_btn
    )
  })

  output$dist_plot <- renderPlot({
    x <- faithful$waiting
    hist(
      x,
      breaks = input$bins,
      col = "#007AFF",
      border = "white",
      main = "Faithful Waiting Times",
      xlab = "Waiting (minutes)"
    )
  })
}

shinyApp(ui, server)