# shinyglass

<!-- badges: start -->
[![License: GPL-3](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
<!-- badges: end -->

**Apple-inspired Liquid Glass themes for [Shiny](https://shiny.posit.co/).**

One function — `glass_theme()` — and your app gets translucent surfaces, backdrop blur, soft depth, and system typography. Built on [bslib](https://rstudio.github.io/bslib/), so it works with `fluidPage()`, `navbarPage()`, `page_sidebar()`, and other Bootstrap-aware layouts.

[Documentation](https://ericrayanderson.github.io/shinyglass/) · [Source](https://github.com/ericrayanderson/shinyglass) · [Issues](https://github.com/ericrayanderson/shinyglass/issues)

<p align="center">
<table>
<tr>
<td align="center"><img src="man/figures/shinyglass-demo.png" width="340" alt="shinyglass demo app, light preset"></td>
<td align="center"><img src="man/figures/shinyglass-demo-dark.png" width="340" alt="shinyglass demo app, dark preset"></td>
</tr>
<tr>
<td align="center"><strong>Light</strong></td>
<td align="center"><strong>Dark</strong></td>
</tr>
</table>
</p>

## Features

- **Drop-in theme** — pass `theme = glass_theme()` to any Shiny page function that accepts a bslib theme
- **Light and dark presets** — full color systems, not just inverted text
- **Familiar Shiny UI** — standard inputs, buttons, navbars, sidebars, cards, and DataTables pick up glass styling automatically
- **Works with bslib** — optional cards, value boxes, and `page_sidebar()` dashboards
- **Tunable** — accent color, blur, saturation, and corner radius

## Installation

```r
# install.packages("shinyglass")  # once on CRAN
remotes::install_github("ericrayanderson/shinyglass")
```

## Quick start

```r
library(shiny)
library(shinyglass)

ui <- fluidPage(
  theme = glass_theme(),
  titlePanel("Liquid Glass"),
  selectInput("color", "Favorite color", c("Blue", "Purple", "Orange")),
  sliderInput("n", "Number of bars", 5, 30, 15),
  plotOutput("plot")
)

server <- function(input, output, session) {
  output$plot <- renderPlot({
    barplot(
      seq_len(input$n),
      col = "#007AFF",
      border = NA,
      main = paste("You chose", input$color)
    )
  })
}

shinyApp(ui, server)
```

You only need **shiny** and **shinyglass**. `glass_theme()` returns a [bslib](https://rstudio.github.io/bslib/) theme object that Shiny page functions understand — you do not need to load bslib unless you want its UI helpers (`card()`, `page_fillable()`, and so on).

## Customization

```r
glass_theme(
  preset     = "dark",   # "light" or "dark"
  primary    = "#007AFF",
  blur       = 28,
  saturation = 200,
  radius     = "1.25rem"
)
```

| Argument | Description |
|----------|-------------|
| `preset` | Overall light or dark appearance |
| `primary` | Accent color (buttons, links, focus rings) |
| `blur` | Backdrop blur radius in pixels |
| `saturation` | Backdrop saturation percentage |
| `radius` | Corner radius for glass surfaces |
| `...` | Passed through to `bslib::bs_theme()` |

## Examples

Bundled demos live in the package. Run any of them with `shiny::runApp()`.

### Cards and plots

```r
install.packages(c("bslib", "ggplot2"))
shiny::runApp(system.file("examples", "demo-app.R", package = "shinyglass"))
```

### Dashboard layout

A `page_sidebar()` app with value boxes, tabbed cards, and a DataTable:

```r
install.packages(c("bslib", "ggplot2", "DT"))
shiny::runApp(system.file("examples", "bslib-dashboard.R", package = "shinyglass"))
```

<p align="center">
<table>
<tr>
<td align="center"><img src="man/figures/bslib-dashboard.png" width="340" alt="bslib dashboard, light preset"></td>
<td align="center"><img src="man/figures/bslib-dashboard-dark.png" width="340" alt="bslib dashboard, dark preset"></td>
</tr>
<tr>
<td align="center">Light</td>
<td align="center">Dark</td>
</tr>
</table>
</p>

### Natural-language filtering

Explore data with [querychat](https://posit-dev.github.io/querychat/r/). Quick-filter buttons work offline; chat needs an LLM API key (for example `OPENAI_API_KEY`):

```r
install.packages(c("querychat", "duckdb", "DT", "ggplot2"))
shiny::runApp(system.file("examples", "querychat-demo.R", package = "shinyglass"))
```

<p align="center">
<table>
<tr>
<td align="center"><img src="man/figures/querychat-demo.png" width="340" alt="querychat explorer, light preset"></td>
<td align="center"><img src="man/figures/querychat-demo-dark.png" width="340" alt="querychat explorer, dark preset"></td>
</tr>
<tr>
<td align="center">Light</td>
<td align="center">Dark</td>
</tr>
</table>
</p>

### Sidebar reference

Floating sidebar, plots, and DataTables:

```r
shiny::runApp(system.file("examples", "apple-glass-reference.R", package = "shinyglass"))
```

<p align="center">
<table>
<tr>
<td align="center"><img src="man/figures/apple-glass-reference.png" width="340" alt="reference app, light preset"></td>
<td align="center"><img src="man/figures/apple-glass-reference-dark.png" width="340" alt="reference app, dark preset"></td>
</tr>
<tr>
<td align="center">Light</td>
<td align="center">Dark</td>
</tr>
</table>
</p>

### Community dashboards

Glass themes applied to open dashboards from [dreamRs](https://github.com/dreamRs/shinyapps) — GitHub stats, Olympic medals, French births, and Paris metro traffic:

```r
install.packages(c(
  "shinyWidgets", "ggplot2", "reactable", "apexcharter",
  "leaflet", "sf", "billboarder", "shinydashboard"
))
shiny::runApp(system.file("examples", "dreamrs-gh-dashboard.R", package = "shinyglass"))
shiny::runApp(system.file("examples", "dreamrs-olympic-medals.R", package = "shinyglass"))
shiny::runApp(system.file("examples", "dreamrs-tdb-naissances.R", package = "shinyglass"))
shiny::runApp(system.file("examples", "dreamrs-ratp-traffic.R", package = "shinyglass"))
```

| App | Light | Dark |
|-----|:-----:|:----:|
| GitHub dashboard | <img src="man/figures/dreamrs-gh-dashboard.png" width="220" alt="GitHub dashboard, light"> | <img src="man/figures/dreamrs-gh-dashboard-dark.png" width="220" alt="GitHub dashboard, dark"> |
| Olympic medals | <img src="man/figures/dreamrs-olympic-medals.png" width="220" alt="Olympic medals, light"> | <img src="man/figures/dreamrs-olympic-medals-dark.png" width="220" alt="Olympic medals, dark"> |
| Births in France | <img src="man/figures/dreamrs-tdb-naissances.png" width="220" alt="Births dashboard, light"> | <img src="man/figures/dreamrs-tdb-naissances-dark.png" width="220" alt="Births dashboard, dark"> |
| Paris metro | <img src="man/figures/dreamrs-ratp-traffic.png" width="220" alt="RATP traffic, light"> | <img src="man/figures/dreamrs-ratp-traffic-dark.png" width="220" alt="RATP traffic, dark"> |

## Gallery

Common Shiny patterns with `glass_theme()`:

| | | | |
|:---:|:---:|:---:|:---:|
| <img src="man/figures/gallery/01-fluid-sidebar.png" width="270" alt="fluidPage with sidebar layout"> | <img src="man/figures/gallery/02-tabsets.png" width="270" alt="tabset with pill-style tabs"> | <img src="man/figures/gallery/03-action-button.png" width="270" alt="action button in a glass card"> | <img src="man/figures/gallery/thumbs/04-download.png" width="270" alt="download button with data preview"> |
| fluidPage + sidebar | Pill tabs | actionButton | downloadButton |
| <img src="man/figures/gallery/05-datatables.png" width="270" alt="interactive DataTable with glass styling"> | <img src="man/figures/gallery/thumbs/06-selectize.png" width="270" alt="selectize inputs with glass styling"> | <img src="man/figures/gallery/thumbs/07-navbar.png" width="270" alt="navbarPage with glass navigation bar"> | <img src="man/figures/gallery/08-page-sidebar.png" width="270" alt="page_sidebar with glass controls"> |
| DataTables | selectizeInput | navbarPage | page_sidebar |

## Learn more

- Function reference: [`glass_theme()`](https://ericrayanderson.github.io/shinyglass/reference/glass_theme.html)
- Package site: [ericrayanderson.github.io/shinyglass](https://ericrayanderson.github.io/shinyglass/)
- Design inspiration: [Apple Liquid Glass](https://developer.apple.com/documentation/technologyoverviews/liquid-glass)

## License

GPL-3
