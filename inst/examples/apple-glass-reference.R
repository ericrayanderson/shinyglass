# Apple Liquid Glass reference app for shinyglass visual validation.
# Exercises: floating sidebar, pill tabs, content-aware tinting, notifications.
#
# Run:
#   shiny::runApp(system.file("examples", "apple-glass-reference.R", package = "shinyglass"))

library(shiny)
library(shinyglass)

if (!requireNamespace("ggplot2", quietly = TRUE)) {
  stop("ggplot2 is required for this reference app.")
}
library(ggplot2)

palette_colors <- list(
  Ocean = c("#007AFF", "#5AC8FA", "#34C759"),
  Sunset = c("#FF9500", "#FF2D55", "#AF52DE"),
  Forest = c("#34C759", "#30B0C7", "#5856D6")
)

ui <- fluidPage(
  theme = glass_theme(),
  titlePanel("Apple Liquid Glass Reference"),
  p(
    class = "text-muted",
    "Validates shinyglass against Apple's Liquid Glass goals: translucent chrome ",
    "informed by surrounding content, floating controls above a colorful hero."
  ),
  sidebarLayout(
    sidebarPanel(
      selectInput(
        "palette",
        "Chart palette",
        choices = names(palette_colors),
        selected = "Ocean"
      ),
      selectInput(
        "species",
        "Species",
        choices = c("setosa", "versicolor", "virginica"),
        selected = "setosa"
      ),
      sliderInput("bins", "Histogram bins", min = 8, max = 40, value = 18),
      checkboxInput("density", "Show density curve", TRUE),
      actionButton("notify", "Show notification", class = "btn-primary"),
      tags$hr(),
      tags$small(
        class = "text-muted",
        "Change palette to see content-aware glass tinting update."
      )
    ),
    mainPanel(
      tabsetPanel(
        id = "tabs",
        tabPanel(
          "Chart",
          div(
            class = "glass-content-hero",
            plotOutput("hero_plot", height = "340px")
          )
        ),
        tabPanel(
          "Data",
          tableOutput("hero_table")
        ),
        tabPanel(
          "Checklist",
          tags$ul(
            tags$li("Floating glass sidebar (functional layer above content)"),
            tags$li("Pill tab bar with scroll-compact navigation"),
            tags$li("Content-aware tint sampled from the chart"),
            tags$li("Notification toast as a floating glass layer"),
            tags$li("Compare against ", tags$a(
              href = "https://developer.apple.com/documentation/TechnologyOverviews/adopting-liquid-glass",
              "Apple's Adopting Liquid Glass"
            ))
          )
        )
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

  output$hero_plot <- renderPlot({
    df <- plot_data()
    cols <- palette_colors[[input$palette]]

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
        panel.background = element_rect(fill = "#f8f9fc", color = NA),
        plot.background = element_rect(fill = "#f8f9fc", color = NA),
        legend.position = "bottom"
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

  output$hero_table <- renderTable({
    head(plot_data()[, c("Sepal.Length", "Sepal.Width", "Petal.Length", "Species")], 12)
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