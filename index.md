# shinyglass

[Liquid
Glass](https://developer.apple.com/documentation/technologyoverviews/liquid-glass)
themes for [Shiny](https://shiny.posit.co/). Call
[`glass_theme()`](https://ericrayanderson.github.io/shinyglass/reference/glass_theme.md)
to get translucent surfaces, backdrop blur, and system typography on
Bootstrap components via [bslib](https://rstudio.github.io/bslib/).

[Documentation](https://ericrayanderson.github.io/shinyglass/) ·
[GitHub](https://github.com/ericrayanderson/shinyglass)

![Demo app,
light](https://raw.githubusercontent.com/ericrayanderson/shinyglass/main/man/figures/shinyglass-demo.png)![Demo
app,
dark](https://raw.githubusercontent.com/ericrayanderson/shinyglass/main/man/figures/shinyglass-demo-dark.png)

## Quick start

``` r

# install.packages("remotes")
remotes::install_github("ericrayanderson/shinyglass")

library(shiny)
library(shinyglass)

ui <- fluidPage(
  theme = glass_theme(),  # or glass_theme(preset = "dark")
  titlePanel("Liquid Glass"),
  sliderInput("n", "Bars", 5, 30, 15),
  plotOutput("plot")
)

server <- function(input, output, session) {
  output$plot <- renderPlot(barplot(seq_len(input$n), col = "#007AFF", border = NA))
}

shinyApp(ui, server)
```
