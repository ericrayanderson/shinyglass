library(shiny)
library(bslib)
library(ggplot2)
library(shinyglass)

ui <- fluidPage(
  theme = glass_theme(preset = "auto"),
  titlePanel("Liquid Glass"),
  # Min column width so cards stack on phones instead of forcing 2 columns
  layout_column_wrap(
    width = 280,
    gap = "0.75rem",
    card(
      card_header("Form Controls"),
      selectInput("species", "Species", c("setosa", "versicolor", "virginica"), width = "100%"),
      sliderInput("bins", "Bins", 1, 50, 20, width = "100%"),
      checkboxInput("smooth", "Show smooth", TRUE),
      actionButton("go", "Go", class = "btn-primary"),
      hr(),
      # onclick applies instantly on the client; server update_glass_theme()
      # keeps session state in sync (needed on hosts that rewrite Shiny messaging).
      div(
        class = "d-flex flex-wrap gap-2",
        actionButton(
          "theme_light", "Light",
          onclick = "window.shinyglass&&window.shinyglass.setPreset('light')"
        ),
        actionButton(
          "theme_dark", "Dark",
          onclick = "window.shinyglass&&window.shinyglass.setPreset('dark')"
        ),
        actionButton(
          "theme_auto", "Auto (OS)",
          onclick = "window.shinyglass&&window.shinyglass.setPreset('auto')"
        )
      )
    ),
    card(
      card_header("Plot"),
      plotOutput("dist_plot", height = "260px")
    )
  )
)

server <- function(input, output, session) {
  observeEvent(input$theme_light, update_glass_theme(session, preset = "light"))
  observeEvent(input$theme_dark, update_glass_theme(session, preset = "dark"))
  observeEvent(input$theme_auto, update_glass_theme(session, preset = "auto"))

  output$dist_plot <- renderPlot({
    x <- faithful$waiting
    df <- data.frame(x = x)
    p <- ggplot(df, aes(x)) +
      geom_histogram(bins = input$bins, fill = "#007AFF", color = "white") +
      labs(title = "Faithful Waiting Times", x = "Waiting (minutes)", y = NULL) +
      theme_minimal(base_size = 13)
    if (isTRUE(input$smooth)) {
      p <- p + geom_density(
        aes(y = after_stat(count)),
        color = "#AF52DE",
        linewidth = 1.15
      )
    }
    p
  }, height = 260, res = 96)
}

shinyApp(ui, server)
