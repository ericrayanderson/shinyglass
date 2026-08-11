# Liquid Glass Design Themes for 'shiny' Applications

Drop-in Liquid Glass themes for [shiny](https://shiny.posit.co/). Call
[`glass_theme()`](https://ericrayanderson.github.io/shinyglass/reference/glass_theme.md)
and pass the result to `theme =` on
[`fluidPage()`](https://rdrr.io/pkg/shiny/man/fluidPage.html),
[`navbarPage()`](https://rdrr.io/pkg/shiny/man/navbarPage.html), or any
[bslib](https://rstudio.github.io/bslib/)-aware page function to get
translucent surfaces, backdrop blur, and system typography.

## Getting started

    library(shiny)
    library(shinyglass)

    ui <- fluidPage(
      theme = glass_theme(preset = "auto", intensity = 0.45),
      titlePanel("Liquid Glass"),
      glass_intensity_slider("glass_intensity"),
      glass_theme_toggle(selected = "auto"),
      sliderInput("n", "Bars", 5, 30, 15),
      plotOutput("plot")
    )

    server <- function(input, output, session) {
      observe_glass_theme_toggle(input, session)
      observe_glass_intensity(input, session, "glass_intensity")
      output$plot <- renderPlot(
        barplot(seq_len(input$n), col = "#007AFF", border = NA)
      )
    }

Light and dark presets are available via `glass_theme(preset = "dark")`,
or `preset = "auto"` to follow the OS. Switch at runtime with
[`update_glass_theme()`](https://ericrayanderson.github.io/shinyglass/reference/update_glass_theme.md)
or
[`glass_theme_toggle()`](https://ericrayanderson.github.io/shinyglass/reference/glass_theme_toggle.md).
Material density is controlled with
[`glass_intensity_slider()`](https://ericrayanderson.github.io/shinyglass/reference/glass_intensity_slider.md)
(Ultra Clear to Tinted) or `glass_theme(intensity = )`. Accent color,
blur, saturation, corner radius, and JS behaviors (`tint`, `specular`,
`nav_morph`) are configurable.

For [teal](https://insightsengineering.github.io/teal/) apps, set
`options(teal.bs_theme = glass_theme())` before calling `teal::init()`.

## See also

[`glass_theme()`](https://ericrayanderson.github.io/shinyglass/reference/glass_theme.md),
[`glass_intensity_slider()`](https://ericrayanderson.github.io/shinyglass/reference/glass_intensity_slider.md),
[`update_glass_theme()`](https://ericrayanderson.github.io/shinyglass/reference/update_glass_theme.md),
[`glass_theme_toggle()`](https://ericrayanderson.github.io/shinyglass/reference/glass_theme_toggle.md)

## Author

**Maintainer**: Eric Anderson <eric.ray.anderson@gmail.com> \[copyright
holder\]

Authors:

- Eric Anderson <eric.ray.anderson@gmail.com> \[copyright holder\]
