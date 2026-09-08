# shinyglass

<!-- badges: start -->
[![License: GPL-3](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](https://www.r-project.org/Licenses/GPL-3)
[![R-CMD-check](https://github.com/ericrayanderson/shinyglass/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/ericrayanderson/shinyglass/actions/workflows/R-CMD-check.yaml)
[![visual-qa](https://github.com/ericrayanderson/shinyglass/actions/workflows/visual-qa.yaml/badge.svg)](https://github.com/ericrayanderson/shinyglass/actions/workflows/visual-qa.yaml)
<!-- badges: end -->

Glass themes for [Shiny](https://shiny.posit.co/), built on [bslib](https://rstudio.github.io/bslib/). Add translucent surfaces, live light/dark switching, and adjustable glass intensity to your app.

[Documentation](https://ericrayanderson.github.io/shinyglass/) · [Theming guide](https://ericrayanderson.github.io/shinyglass/articles/theming.html) · [Release notes](NEWS.md)

<p align="center">
<img src="https://raw.githubusercontent.com/ericrayanderson/shinyglass/main/man/figures/intensity-slider.gif" width="72%" alt="Glass intensity changing from clear to tinted">
</p>

## Install

```r
install.packages("shinyglass")
```

For the latest development features:

```r
# install.packages("remotes")
remotes::install_github("ericrayanderson/shinyglass")
```

## Quick start

```r
library(shiny)
library(shinyglass)

ui <- fluidPage(
  theme = glass_theme(preset = "auto", intensity = 0.45),
  titlePanel("Hello, glass"),
  glass_theme_toggle(selected = "auto"),
  glass_intensity_slider("glass_intensity"),
  sliderInput("n", "Bars", 5, 30, 15),
  plotOutput("plot")
)

server <- function(input, output, session) {
  observe_glass_theme_toggle(input, session)
  observe_glass_intensity(input, session, "glass_intensity")
  output$plot <- renderPlot(barplot(seq_len(input$n)))
}

shinyApp(ui, server)
```

## Live demos

Apps may take a moment to wake up.

| Demo | Explore |
|------|---------|
| [Basics](https://ericrayanderson.shinyapps.io/shinyglass-demo/) | Theme switching and core controls |
| [Dashboard](https://ericrayanderson.shinyapps.io/shinyglass-dashboard/) | Cards, plots, and tables |
| [Inputs](https://ericrayanderson.shinyapps.io/shinyglass-inputs/) | Shiny input controls |
| [Olympic medals](https://ericrayanderson.shinyapps.io/shinyglass-olympics/) | A complete dashboard |
| [plotly + gt](https://ericrayanderson.shinyapps.io/shinyglass-plotly-gt/) | Interactive charts and tables |

Built for Bootstrap 5 and bslib. See [compatibility](https://ericrayanderson.github.io/shinyglass/articles/compatibility.html) for supported widgets and older layouts.

More: [examples](inst/examples/) · [experimental Python package](python/) · [testing](inst/scripts/VISUAL-QA.md) · [deployment](inst/scripts/SHINYAPPS-DEPLOY.md)
