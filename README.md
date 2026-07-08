# shinyglass

Apple-inspired [Liquid Glass](https://developer.apple.com/documentation/technologyoverviews/liquid-glass) themes for R Shiny — one function, built on [bslib](https://rstudio.github.io/bslib/).

<p align="center">
  <img src="man/figures/shinyglass-demo.png" alt="shinyglass demo app with liquid glass theme" width="720">
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

## Example apps

### Demo

The bundled demo uses [bslib](https://rstudio.github.io/bslib/) cards and [ggplot2](https://ggplot2.tidyverse.org/):

```r
install.packages(c("bslib", "ggplot2"))
shiny::runApp(system.file("examples", "demo-app.R", package = "shinyglass"))
```

### Reference app

Sidebar overlay, content-aware tinting, and DataTables:

```r
shiny::runApp(system.file("examples", "apple-glass-reference.R", package = "shinyglass"))
```

<p align="center">
  <img src="man/figures/apple-glass-reference.png" alt="Apple Liquid Glass reference app controls" width="720">
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