# shinyglass

Apple's [Liquid Glass](https://developer.apple.com/documentation/technologyoverviews/liquid-glass) aesthetic for R Shiny — one function, built on [bslib](https://rstudio.github.io/bslib/).

<p align="center">
  <img src="man/figures/shinyglass-demo.png" alt="shinyglass demo app" width="700">
</p>

## Install

```r
remotes::install_github("ericrayanderson/shinyglass")
```

## Usage

```r
library(shiny)
library(shinyglass)

ui <- fluidPage(
  theme = glass_theme(),
  titlePanel("My App"),
  selectInput("color", "Color", c("Blue", "Purple", "Orange")),
  plotOutput("plot")
)

shinyApp(ui, server = function(input, output, session) {})
```

That's it. Bootstrap cards, buttons, inputs, navbars, and modals are styled automatically.

Use [bslib](https://rstudio.github.io/bslib/) helpers like `card()` if you like — they work great with `glass_theme()`.

## Options

```r
glass_theme(
  preset     = "dark",   # "light" or "dark"
  primary    = "#007AFF",
  blur       = 20,
  saturation = 180
)
```

## Demo

```r
shiny::runApp(system.file("examples", "demo-app.R", package = "shinyglass"))
```

## License

GPL-3