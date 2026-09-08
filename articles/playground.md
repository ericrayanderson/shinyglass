# Try it

## Live demo

The [basics demo](https://ericrayanderson.shinyapps.io/shinyglass-demo/)
is a full Shiny app with theme persistence, intensity, accent wells, and
[`theme_glass()`](https://ericrayanderson.github.io/shinyglass/reference/theme_glass.md)
plots. Apps may take a moment to wake up.

## Shinylive

Paste this into the [Shinylive editor](https://shinylive.io/r/editor/)
(install shinyglass from GitHub in the editor if the CRAN build is older
than 0.3.0):

``` r

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
      fg = pal$ink,
      col.axis = pal$ink
    )
  }, bg = "transparent")
}

shinyApp(ui, server)
```

The same app lives at `inst/examples/playground.R` in the source
repository.
