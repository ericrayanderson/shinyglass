# Liquid Glass Design Themes for Shiny Applications

Drop-in Liquid Glass themes for [shiny](https://shiny.posit.co/). Call
[`glass_theme()`](https://ericrayanderson.github.io/shinyglass/dev/reference/glass_theme.md)
and pass the result to `theme =` on
[`fluidPage()`](https://rdrr.io/pkg/shiny/man/fluidPage.html),
[`navbarPage()`](https://rdrr.io/pkg/shiny/man/navbarPage.html), or any
[bslib](https://rstudio.github.io/bslib/)-aware page function to get
translucent surfaces, backdrop blur, and system typography.

## Getting started

    library(shiny)
    library(shinyglass)

    ui <- fluidPage(
      theme = glass_theme(),
      titlePanel("Liquid Glass"),
      sliderInput("n", "Bars", 5, 30, 15),
      plotOutput("plot")
    )

Light and dark presets are available via `glass_theme(preset = "dark")`.
Accent color, blur, saturation, and corner radius are configurable.

For [teal](https://insightsengineering.github.io/teal/) apps, set
`options(teal.bs_theme = glass_theme())` before calling `teal::init()`.

## See also

[`glass_theme()`](https://ericrayanderson.github.io/shinyglass/dev/reference/glass_theme.md)

## Author

**Maintainer**: Eric Anderson <eric.ray.anderson@gmail.com>

Authors:

- Eric Anderson <eric.ray.anderson@gmail.com>
