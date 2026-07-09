# shinyglass

<!-- badges: start -->
[![License: GPL-3](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](https://www.r-project.org/Licenses/GPL-3)
<!-- badges: end -->

[Liquid Glass](https://developer.apple.com/documentation/technologyoverviews/liquid-glass) themes for [Shiny](https://shiny.posit.co/). Call `glass_theme()` to get translucent surfaces, backdrop blur, and system typography on Bootstrap components via [bslib](https://rstudio.github.io/bslib/).

[Documentation](https://ericrayanderson.github.io/shinyglass/) · [GitHub](https://github.com/ericrayanderson/shinyglass)

<p align="center">
<img src="https://raw.githubusercontent.com/ericrayanderson/shinyglass/main/man/figures/shinyglass-demo.png" width="48%" alt="Demo app, light">
<img src="https://raw.githubusercontent.com/ericrayanderson/shinyglass/main/man/figures/shinyglass-demo-dark.png" width="48%" alt="Demo app, dark">
</p>

## Quick start

```r
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
