# shinyglass

<!-- badges: start -->
[![License: GPL-3](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
<!-- badges: end -->

**Apple-inspired Liquid Glass themes for [Shiny](https://shiny.posit.co/).**

One function — `glass_theme()` — gives your app translucent surfaces, backdrop blur, soft depth, and system typography. Built on [bslib](https://rstudio.github.io/bslib/).

[Documentation](https://ericrayanderson.github.io/shinyglass/) · [GitHub](https://github.com/ericrayanderson/shinyglass)

<p align="center">
<img src="https://raw.githubusercontent.com/ericrayanderson/shinyglass/main/man/figures/shinyglass-demo.png" width="48%" alt="Demo app, light">
<img src="https://raw.githubusercontent.com/ericrayanderson/shinyglass/main/man/figures/shinyglass-demo-dark.png" width="48%" alt="Demo app, dark">
</p>
<p align="center"><em>Light and dark presets</em></p>

## Installation

```r
# install.packages("shinyglass")  # once on CRAN
remotes::install_github("ericrayanderson/shinyglass")
```

## Usage

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

Pass `glass_theme()` to any page function that accepts a bslib theme (`fluidPage()`, `navbarPage()`, `page_sidebar()`, and so on). Standard Shiny inputs and layouts are styled automatically.

## Options

```r
glass_theme(
  preset     = "dark",   # "light" or "dark"
  primary    = "#007AFF",
  blur       = 28,
  saturation = 200,
  radius     = "1.25rem"
)
```

## Screenshots

<p align="center">
<img src="https://raw.githubusercontent.com/ericrayanderson/shinyglass/main/man/figures/bslib-dashboard.png" width="48%" alt="Dashboard, light">
<img src="https://raw.githubusercontent.com/ericrayanderson/shinyglass/main/man/figures/bslib-dashboard-dark.png" width="48%" alt="Dashboard, dark">
</p>

<p align="center">
<img src="https://raw.githubusercontent.com/ericrayanderson/shinyglass/main/man/figures/querychat-demo.png" width="48%" alt="Data explorer, light">
<img src="https://raw.githubusercontent.com/ericrayanderson/shinyglass/main/man/figures/querychat-demo-dark.png" width="48%" alt="Data explorer, dark">
</p>

<p align="center">
<img src="https://raw.githubusercontent.com/ericrayanderson/shinyglass/main/man/figures/apple-glass-reference.png" width="48%" alt="Sidebar layout, light">
<img src="https://raw.githubusercontent.com/ericrayanderson/shinyglass/main/man/figures/apple-glass-reference-dark.png" width="48%" alt="Sidebar layout, dark">
</p>

<p align="center">
<img src="https://raw.githubusercontent.com/ericrayanderson/shinyglass/main/man/figures/dreamrs-gh-dashboard.png" width="48%" alt="GitHub dashboard, light">
<img src="https://raw.githubusercontent.com/ericrayanderson/shinyglass/main/man/figures/dreamrs-gh-dashboard-dark.png" width="48%" alt="GitHub dashboard, dark">
</p>

<p align="center">
<img src="https://raw.githubusercontent.com/ericrayanderson/shinyglass/main/man/figures/dreamrs-olympic-medals.png" width="48%" alt="Olympic medals, light">
<img src="https://raw.githubusercontent.com/ericrayanderson/shinyglass/main/man/figures/dreamrs-olympic-medals-dark.png" width="48%" alt="Olympic medals, dark">
</p>

<p align="center">
<img src="https://raw.githubusercontent.com/ericrayanderson/shinyglass/main/man/figures/dreamrs-tdb-naissances.png" width="48%" alt="Time series dashboard, light">
<img src="https://raw.githubusercontent.com/ericrayanderson/shinyglass/main/man/figures/dreamrs-tdb-naissances-dark.png" width="48%" alt="Time series dashboard, dark">
</p>

<p align="center">
<img src="https://raw.githubusercontent.com/ericrayanderson/shinyglass/main/man/figures/dreamrs-ratp-traffic.png" width="48%" alt="Map dashboard, light">
<img src="https://raw.githubusercontent.com/ericrayanderson/shinyglass/main/man/figures/dreamrs-ratp-traffic-dark.png" width="48%" alt="Map dashboard, dark">
</p>

<p align="center">
<img src="https://raw.githubusercontent.com/ericrayanderson/shinyglass/main/man/figures/gallery/01-fluid-sidebar.png" width="24%" alt="Sidebar">
<img src="https://raw.githubusercontent.com/ericrayanderson/shinyglass/main/man/figures/gallery/02-tabsets.png" width="24%" alt="Tabs">
<img src="https://raw.githubusercontent.com/ericrayanderson/shinyglass/main/man/figures/gallery/05-datatables.png" width="24%" alt="DataTables">
<img src="https://raw.githubusercontent.com/ericrayanderson/shinyglass/main/man/figures/gallery/03-action-button.png" width="24%" alt="Buttons">
</p>

## Examples

```r
# Bundled demos (install Suggests as needed)
shiny::runApp(system.file("examples", "demo-app.R", package = "shinyglass"))
shiny::runApp(system.file("examples", "bslib-dashboard.R", package = "shinyglass"))
shiny::runApp(system.file("examples", "apple-glass-reference.R", package = "shinyglass"))
shiny::runApp(system.file("examples", "inputs-gallery.R", package = "shinyglass"))
```

## License

GPL-3
