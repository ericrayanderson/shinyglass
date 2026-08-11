# shinyglass

<!-- badges: start -->
[![License: GPL-3](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](https://www.r-project.org/Licenses/GPL-3)
[![R-CMD-check](https://github.com/ericrayanderson/shinyglass/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/ericrayanderson/shinyglass/actions/workflows/R-CMD-check.yaml)
[![visual-qa](https://github.com/ericrayanderson/shinyglass/actions/workflows/visual-qa.yaml/badge.svg)](https://github.com/ericrayanderson/shinyglass/actions/workflows/visual-qa.yaml)
<!-- badges: end -->

[Liquid Glass](https://developer.apple.com/documentation/technologyoverviews/liquid-glass) themes for [Shiny](https://shiny.posit.co/). `glass_theme()` returns a [bslib](https://rstudio.github.io/bslib/) theme with translucent surfaces, backdrop blur, and system typography. Pass it as `theme = glass_theme()` to `fluidPage()`, `navbarPage()`, or other page functions that accept a bslib theme.

**Runtime controls (no page reload):**

- **Light / Dark / Auto** — `glass_theme_toggle()` + `update_glass_theme(preset = …)`, or `preset = "auto"` to follow the OS
- **Liquid Glass intensity** — iOS 27-style **Ultra Clear → Tinted** via `glass_intensity_slider()` (and `glass_theme(intensity = 0–1)`)

[Documentation](https://ericrayanderson.github.io/shinyglass/) · [GitHub](https://github.com/ericrayanderson/shinyglass) · **[Live demos](#live-demos)**

### Liquid Glass intensity

Drop in `glass_intensity_slider()` for the same continuous control as iOS 27 **Settings → Appearance → Liquid Glass**. Surfaces update live as you drag from **Ultra Clear** (`0`) to **Tinted** (`1`) — no page reload.

<p align="center">
<img src="https://raw.githubusercontent.com/ericrayanderson/shinyglass/main/man/figures/intensity-slider.gif" width="48%" alt="Intensity slider Ultra Clear to Tinted, light">
<img src="https://raw.githubusercontent.com/ericrayanderson/shinyglass/main/man/figures/intensity-slider-dark.gif" width="48%" alt="Intensity slider Ultra Clear to Tinted, dark">
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

<p align="center">
<img src="https://raw.githubusercontent.com/ericrayanderson/shinyglass/main/man/figures/bslib-dashboard.png" width="48%" alt="Glass dashboard, light">
<img src="https://raw.githubusercontent.com/ericrayanderson/shinyglass/main/man/figures/bslib-dashboard-dark.png" width="48%" alt="Glass dashboard, dark">
</p>

<p align="center">
<img src="https://raw.githubusercontent.com/ericrayanderson/shinyglass/main/man/figures/plotly-gt.png" width="48%" alt="plotly + gt, light">
<img src="https://raw.githubusercontent.com/ericrayanderson/shinyglass/main/man/figures/plotly-gt-dark.png" width="48%" alt="plotly + gt, dark">
</p>

## Live demos

Public apps on [shinyapps.io](https://www.shinyapps.io/) (free tier may take a few seconds to wake):

| App | What it shows |
|-----|----------------|
| [Demo + theme toggle](https://ericrayanderson.shinyapps.io/shinyglass-demo/) | Core glass UI + **`glass_intensity_slider()`** + Light / Dark / Auto |
| [bslib dashboard](https://ericrayanderson.shinyapps.io/shinyglass-dashboard/) | `page_sidebar`, value boxes, plots, DT + intensity in the sidebar |
| [Intensity slider example](https://github.com/ericrayanderson/shinyglass/blob/main/inst/examples/intensity-slider-demo.R) | Dedicated **Ultra Clear → Tinted** demo (`glass_intensity_slider()`); run locally or deploy via `--apps=intensity` |
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
  theme = glass_theme(preset = "auto", intensity = 0.45),
  titlePanel("Liquid Glass"),
  # iOS 27-style Ultra Clear → Tinted (updates live on the client)
  glass_intensity_slider("glass_intensity"),
  # Light / Dark / Auto buttons
  glass_theme_toggle(selected = "auto"),
  sliderInput("n", "Bars", 5, 30, 15),
  plotOutput("plot")
)

server <- function(input, output, session) {
  observe_glass_theme_toggle(input, session)
  # optional: keep server session intensity in sync (client already updates live)
  observe_glass_intensity(input, session, "glass_intensity")
  output$plot <- renderPlot(barplot(seq_len(input$n), col = "#007AFF", border = NA))
}

shinyApp(ui, server)
```

Set the starting material with `glass_theme(intensity = …)` (`0` Ultra Clear … `1` Tinted), or drive it from the server with `update_glass_theme(session, intensity = 0.8)`.

See the [theming article](https://ericrayanderson.github.io/shinyglass/articles/theming.html) for knobs (`intensity`, `tint`, `specular`, `nav_morph`) and CSS variables.

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
