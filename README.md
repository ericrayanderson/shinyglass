# shinyglass

Apple's [Liquid Glass](https://developer.apple.com/documentation/technologyoverviews/liquid-glass) aesthetic for R Shiny apps — one theme call, built on [bslib](https://rstudio.github.io/bslib/).

<p align="center">
  <img src="man/figures/shinyglass-demo.png" alt="shinyglass demo app" width="700">
</p>

## Install

```r
remotes::install_github("ericrayanderson/shinyglass")
```

## Quick start

```r
library(shiny)
library(bslib)
library(shinyglass)

ui <- fluidPage(
  theme = glass_theme(),
  card(
    card_header("Hello"),
    "Your app content here."
  )
)

shinyApp(ui, server = function(input, output, session) {})
```

Or use the convenience page wrapper:

```r
ui <- glass_page(
  header = "My App",
  glass_card(h3("Welcome"), p("Liquid glass styling applied automatically."))
)
```

## Customization

```r
glass_theme(
  preset  = "dark",      # "light" or "dark"
  primary = "#007AFF",   # accent color
  blur    = 20,          # backdrop blur (px)
  saturation = 180       # backdrop saturation (%)
)
```

## Demo

```r
shiny::runApp(system.file("examples", "demo-app.R", package = "shinyglass"))
```

## License

GPL-3