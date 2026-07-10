# shinyglass

<!-- badges: start -->
[![License: GPL-3](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](https://www.r-project.org/Licenses/GPL-3)
<!-- badges: end -->

[Liquid Glass](https://developer.apple.com/documentation/technologyoverviews/liquid-glass) themes for [Shiny](https://shiny.posit.co/). `glass_theme()` returns a [bslib](https://rstudio.github.io/bslib/) theme with translucent surfaces, backdrop blur, and system typography. Pass it as `theme = glass_theme()` to `fluidPage()`, `navbarPage()`, or other page functions that accept a bslib theme.

[Documentation](https://ericrayanderson.github.io/shinyglass/) · [GitHub](https://github.com/ericrayanderson/shinyglass)

<p align="center">
<img src="https://raw.githubusercontent.com/ericrayanderson/shinyglass/main/man/figures/bslib-dashboard.png" width="48%" alt="Glass dashboard, light">
<img src="https://raw.githubusercontent.com/ericrayanderson/shinyglass/main/man/figures/bslib-dashboard-dark.png" width="48%" alt="Glass dashboard, dark">
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
