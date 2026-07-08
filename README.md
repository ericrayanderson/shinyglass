# shinyglass

Apple-inspired [Liquid Glass](https://developer.apple.com/documentation/technologyoverviews/liquid-glass) themes for R Shiny — one function, built on [bslib](https://rstudio.github.io/bslib/).

[Documentation](https://ericrayanderson.github.io/shinyglass/) · [Report an issue](https://github.com/ericrayanderson/shinyglass/issues)

<p align="center">
<table>
<tr>
<td align="center"><img src="man/figures/shinyglass-demo.png" width="340" alt="shinyglass demo app, light preset"></td>
<td align="center"><img src="man/figures/shinyglass-demo-dark.png" width="340" alt="shinyglass demo app, dark preset"></td>
</tr>
<tr>
<td align="center">Light</td>
<td align="center">Dark</td>
</tr>
</table>
</p>

## Install

```r
# install.packages("shinyglass")  # once on CRAN
remotes::install_github("ericrayanderson/shinyglass")
```

## Quick start

Save as `app.R` and run with `shiny::runApp()`:

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

You only need `shiny` and `shinyglass`. `glass_theme()` returns a bslib theme object that `fluidPage()` and other Shiny page functions understand automatically — you do not need to load bslib.

Load [bslib](https://rstudio.github.io/bslib/) only if you want its UI helpers like `card()` or `page_fillable()`. Standard Shiny inputs, buttons, and layouts work out of the box.

## Customization

```r
glass_theme(
  preset     = "dark",   # "light" or "dark"
  primary    = "#007AFF",
  blur       = 28,
  saturation = 200
)
```

`preset` switches the full color system — both variants are shown above.

## Example apps

### Demo

The bundled demo uses [bslib](https://rstudio.github.io/bslib/) cards and [ggplot2](https://ggplot2.tidyverse.org/):

```r
install.packages(c("bslib", "ggplot2"))
shiny::runApp(system.file("examples", "demo-app.R", package = "shinyglass"))
```

### bslib dashboard

`value_box()`, `layout_columns()`, `navset_card_tab()`, and `card(full_screen = TRUE)` on a `page_sidebar()` dashboard:

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

### querychat explorer

[querychat](https://posit-dev.github.io/querychat/r/) natural-language filtering with a glass dashboard layout. Quick-filter buttons work without an API key; chat requires an LLM credential (e.g. `OPENAI_API_KEY`):

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

### dreamRs apps

Real-world dashboards from [dreamRs/shinyapps](https://github.com/dreamRs/shinyapps) with `glass_theme()` applied. Useful for spotting styling gaps on custom CSS, legacy widgets, and third-party outputs (leaflet, reactable, apexcharter, shinydashboard).

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
|-----|-------|------|
| GitHub dashboard | <img src="man/figures/dreamrs-gh-dashboard.png" width="220" alt="dreamRs GitHub dashboard, light"> | <img src="man/figures/dreamrs-gh-dashboard-dark.png" width="220" alt="dreamRs GitHub dashboard, dark"> |
| Olympic medals | <img src="man/figures/dreamrs-olympic-medals.png" width="220" alt="dreamRs Olympic medals, light"> | <img src="man/figures/dreamrs-olympic-medals-dark.png" width="220" alt="dreamRs Olympic medals, dark"> |
| Births in France | <img src="man/figures/dreamrs-tdb-naissances.png" width="220" alt="dreamRs births dashboard, light"> | <img src="man/figures/dreamrs-tdb-naissances-dark.png" width="220" alt="dreamRs births dashboard, dark"> |
| Paris metro | <img src="man/figures/dreamrs-ratp-traffic.png" width="220" alt="dreamRs RATP traffic, light"> | <img src="man/figures/dreamrs-ratp-traffic-dark.png" width="220" alt="dreamRs RATP traffic, dark"> |

Re-capture screenshots (requires [chromote](https://rstudio.github.io/chromote/)):

```bash
Rscript inst/scripts/capture-dreamrs-screenshots.R
```

### Reference app

Sidebar overlay, content-aware tinting, and DataTables:

```r
shiny::runApp(system.file("examples", "apple-glass-reference.R", package = "shinyglass"))
```

Dark preset:

```r
Sys.setenv(SHINYGLASS_PRESET = "dark")
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

## Gallery

Official [Shiny examples](https://github.com/rstudio/shiny/tree/main/inst/examples) with `glass_theme()` applied:

| | | | |
|:---:|:---:|:---:|:---:|
| <img src="man/figures/gallery/01-fluid-sidebar.png" width="270" alt="fluidPage with sidebar layout"> | <img src="man/figures/gallery/02-tabsets.png" width="270" alt="tabset with pill-style tabs"> | <img src="man/figures/gallery/03-action-button.png" width="270" alt="action button in a glass card"> | <img src="man/figures/gallery/thumbs/04-download.png" width="270" alt="download button with data preview"> |
| fluidPage + sidebar | Pill tab bar | actionButton | downloadButton |
| <img src="man/figures/gallery/05-datatables.png" width="270" alt="interactive DataTable with glass styling"> | <img src="man/figures/gallery/thumbs/06-selectize.png" width="270" alt="selectize inputs with glass styling"> | <img src="man/figures/gallery/thumbs/07-navbar.png" width="270" alt="navbarPage with glass navigation bar"> | <img src="man/figures/gallery/08-page-sidebar.png" width="270" alt="page_sidebar with glass controls"> |
| DataTables | selectizeInput | navbarPage | page_sidebar |

## License

GPL-3