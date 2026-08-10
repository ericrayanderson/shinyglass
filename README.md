# shinyglass

<!-- badges: start -->
[![License: GPL-3](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](https://www.r-project.org/Licenses/GPL-3)
[![R-CMD-check](https://github.com/ericrayanderson/shinyglass/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/ericrayanderson/shinyglass/actions/workflows/R-CMD-check.yaml)
[![visual-qa](https://github.com/ericrayanderson/shinyglass/actions/workflows/visual-qa.yaml/badge.svg)](https://github.com/ericrayanderson/shinyglass/actions/workflows/visual-qa.yaml)
<!-- badges: end -->

[Liquid Glass](https://developer.apple.com/documentation/technologyoverviews/liquid-glass) themes for [Shiny](https://shiny.posit.co/). `glass_theme()` returns a [bslib](https://rstudio.github.io/bslib/) theme with translucent surfaces, backdrop blur, and system typography. Pass it as `theme = glass_theme()` to `fluidPage()`, `navbarPage()`, or other page functions that accept a bslib theme.

Light and dark packs switch at **runtime** (no page reload). Use `preset = "auto"` to follow the OS, or call `update_glass_theme()` from the server.

[Documentation](https://ericrayanderson.github.io/shinyglass/) · [GitHub](https://github.com/ericrayanderson/shinyglass) · **[Live demos](#live-demos)**

<p align="center">
<img src="https://raw.githubusercontent.com/ericrayanderson/shinyglass/main/man/figures/bslib-dashboard.png" width="48%" alt="Glass dashboard, light">
<img src="https://raw.githubusercontent.com/ericrayanderson/shinyglass/main/man/figures/bslib-dashboard-dark.png" width="48%" alt="Glass dashboard, dark">
</p>

<p align="center">
<img src="https://raw.githubusercontent.com/ericrayanderson/shinyglass/main/man/figures/plotly-gt.png" width="48%" alt="plotly + gt, light">
<img src="https://raw.githubusercontent.com/ericrayanderson/shinyglass/main/man/figures/plotly-gt-dark.png" width="48%" alt="plotly + gt, dark">
</p>

<p align="center">
<img src="https://raw.githubusercontent.com/ericrayanderson/shinyglass/main/man/figures/intensity-slider.png" width="48%" alt="Liquid Glass intensity slider, light">
<img src="https://raw.githubusercontent.com/ericrayanderson/shinyglass/main/man/figures/intensity-slider-dark.png" width="48%" alt="Liquid Glass intensity slider, dark">
</p>

<p align="center">
<img src="https://raw.githubusercontent.com/ericrayanderson/shinyglass/main/man/figures/intensity-slider-clear.png" width="32%" alt="Ultra Clear intensity">
<img src="https://raw.githubusercontent.com/ericrayanderson/shinyglass/main/man/figures/intensity-slider-tinted.png" width="32%" alt="Tinted intensity">
<img src="https://raw.githubusercontent.com/ericrayanderson/shinyglass/main/man/figures/intensity-slider-dark-tinted.png" width="32%" alt="Tinted intensity, dark">
</p>

## Live demos

Public apps on [shinyapps.io](https://www.shinyapps.io/) (free tier may take a few seconds to wake):

| App | What it shows |
|-----|----------------|
| [Demo + theme toggle](https://ericrayanderson.shinyapps.io/shinyglass-demo/) | Core glass UI + intensity slider + **Light / Dark / Auto** |
| [bslib dashboard](https://ericrayanderson.shinyapps.io/shinyglass-dashboard/) | `page_sidebar`, value boxes, plots, DT + **Liquid Glass intensity** |
| [Intensity slider](https://ericrayanderson.shinyapps.io/shinyglass-intensity/) | iOS 27 **Ultra Clear → Tinted** control (`glass_intensity_slider()`) |
| [Inputs gallery](https://ericrayanderson.shinyapps.io/shinyglass-inputs/) | Built-in Shiny inputs under glass |
| [plotly + gt](https://ericrayanderson.shinyapps.io/shinyglass-plotly-gt/) | plotly modebar + gt tables under glass |
| [Olympic medals](https://ericrayanderson.shinyapps.io/shinyglass-olympics/) | denser dreamRs-style dashboard (glass port) |

## Install

```r
# once on CRAN:
install.packages("shinyglass")

# development version:
# remotes::install_github("ericrayanderson/shinyglass")
```

## Quick start

```r
library(shiny)
library(shinyglass)

ui <- fluidPage(
  theme = glass_theme(preset = "auto"),
  titlePanel("Liquid Glass"),
  actionButton("dark", "Dark mode"),
  sliderInput("n", "Bars", 5, 30, 15),
  plotOutput("plot")
)

server <- function(input, output, session) {
  observeEvent(input$dark, update_glass_theme(session, preset = "dark"))
  output$plot <- renderPlot(barplot(seq_len(input$n), col = "#007AFF", border = NA))
}

shinyApp(ui, server)
```

See the [theming article](https://ericrayanderson.github.io/shinyglass/articles/theming.html) for knobs (`tint`, `specular`, `nav_morph`) and CSS variables.

```r
# re-deploy live demos (requires rsconnect; installs shinyglass from GitHub):
# remotes::install_github("ericrayanderson/shinyglass")
# Rscript inst/scripts/deploy-shinyapps-demos.R
# Rscript inst/scripts/deploy-shinyapps-demos.R --apps=demo,dashboard,intensity
#
# visual QA (contrast + DT/selectize structure, light+dark matrix):
# Rscript inst/scripts/audit-glass-contrast.R
# see inst/scripts/VISUAL-QA.md
```

## Local examples

```r
shiny::runApp(system.file("examples", "demo-app.R", package = "shinyglass"))
shiny::runApp(system.file("examples", "bslib-dashboard.R", package = "shinyglass"))
shiny::runApp(system.file("examples", "intensity-slider-demo.R", package = "shinyglass"))
shiny::runApp(system.file("examples", "inputs-gallery.R", package = "shinyglass"))
# plotly + gt (+ waiter if installed):
# shiny::runApp(system.file("examples", "plotly-gt-demo.R", package = "shinyglass"))
```

## Shiny for Python (experimental)

A parallel package lives under
[`python/`](https://github.com/ericrayanderson/shinyglass/tree/main/python)
(not on CRAN/PyPI yet). See that README for wheel builds.
