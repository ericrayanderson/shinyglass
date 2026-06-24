library(shiny)
library(bslib)
library(ggplot2)
library(shinyglass)

ui <- glass_page(
  title = "shinyglass test",
  header = "Liquid Glass Playground",
  layout_column_wrap(
    width = 1 / 2,
    glass_card(
      h4("Text & Numbers"),
      textInput("name", "Your name", placeholder = "Enter name..."),
      passwordInput("pw", "Password"),
      numericInput("age", "Age", value = 30, min = 0, max = 120),
      textAreaInput("bio", "Bio", placeholder = "A few words...", rows = 2)
    ),
    glass_card(
      h4("Choices"),
      selectInput("color", "Favorite color", c("Blue", "Purple", "Orange", "Green")),
      radioButtons("size", "T-shirt size", c("S", "M", "L", "XL"), inline = TRUE),
      checkboxInput("newsletter", "Subscribe to newsletter", TRUE),
      checkboxGroupInput(
        "features",
        "Features",
        c("Blur", "Specular highlights", "Dark mode", "Animations"),
        selected = c("Blur", "Specular highlights")
      )
    ),
    glass_card(
      h4("Sliders & Dates"),
      sliderInput("opacity", "Glass opacity", min = 0, max = 100, value = 45),
      sliderInput("blur", "Blur radius", min = 5, max = 40, value = 20),
      dateInput("start_date", "Start date"),
      actionButton("go", "Apply settings", class = "btn-primary"),
      glass_button("glass_btn", "Glass button")
    ),
    card(
      full_screen = TRUE,
      card_header("Bootstrap card (auto-styled)"),
      card_body(
        plotOutput("demo_plot", height = "260px"),
        verbatimTextOutput("summary")
      )
    )
  )
)

server <- function(input, output, session) {
  output$demo_plot <- renderPlot({
    n <- max(input$blur, 10)
    x <- seq(-3, 3, length.out = n)
    y <- dnorm(x)
    cols <- colorRampPalette(c("#007AFF", "#AF52DE", "#FF9500"))(n)

    ggplot(
      data.frame(x = seq_along(y), y = y),
      aes(x = x, y = y)
    ) +
      geom_col(fill = cols, width = 0.85) +
      labs(
        title = paste("Blur =", input$blur, "| Opacity =", input$opacity, "%"),
        x = NULL,
        y = NULL
      ) +
      theme_minimal(base_size = 13) +
      theme(
        plot.title = element_text(face = "bold", size = 13, hjust = 0.5),
        panel.grid.minor = element_blank(),
        axis.text.x = element_blank(),
        axis.ticks.x = element_blank()
      )
  }, height = 260)

  output$summary <- renderText({
    paste0(
      "Name: ", input$name %||% "(none)", "\n",
      "Color: ", input$color, " | Size: ", input$size, "\n",
      "Features: ", paste(input$features, collapse = ", "), "\n",
      "Newsletter: ", input$newsletter, "\n",
      "Clicks — Apply: ", input$go, " | Glass: ", input$glass_btn
    )
  })
}

`%||%` <- function(x, y) if (is.null(x) || length(x) == 0 || identical(x, "")) y else x

shinyApp(ui, server)