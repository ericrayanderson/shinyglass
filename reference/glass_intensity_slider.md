# Liquid Glass intensity slider (iOS 27-style)

UI control matching iOS 27 **Settings -\> Appearance -\> Liquid Glass**:
a continuous slider from **Ultra Clear** (`0`) to **Tinted** (`1`) that
live-updates the glass material without a page reload.

## Usage

``` r
glass_intensity_slider(
  inputId = "glass_intensity",
  label = "Liquid Glass",
  value = NULL,
  min = 0,
  max = 1,
  step = 0.01,
  min_label = "Ultra Clear",
  max_label = "Tinted",
  preview = TRUE,
  width = NULL
)
```

## Arguments

- inputId:

  The `input` slot that will be used to access the value.

- label:

  Display label for the control (or `NULL` for none).

- value:

  Initial intensity in \\\[0, 1\]\\. If `NULL`, uses the theme default
  from
  [`glass_theme()`](https://ericrayanderson.github.io/shinyglass/reference/glass_theme.md)
  / the client current intensity.

- min, max, step:

  Range for the underlying range input. Defaults cover the full Ultra
  Clear -\> Tinted spectrum.

- min_label, max_label:

  End-cap captions (iOS uses "Ultra Clear" / "Tinted").

- preview:

  Show three mini glass chips as a live material sample.

- width:

  CSS width (passed to
  [`shiny::validateCssUnit()`](https://rstudio.github.io/htmltools/reference/validateCssUnit.html)).

## Value

A Shiny UI tag hierarchy.

## Details

The client applies changes immediately via
`window.shinyglass.setIntensity()`. The value is also a normal Shiny
input (`input[[inputId]]`) so the server can react or persist it. Pair
with
[`glass_theme()`](https://ericrayanderson.github.io/shinyglass/reference/glass_theme.md)
`intensity=` for the starting value, and optionally
[`observe_glass_intensity()`](https://ericrayanderson.github.io/shinyglass/reference/observe_glass_intensity.md)
to push server-driven updates through
[`update_glass_theme()`](https://ericrayanderson.github.io/shinyglass/reference/update_glass_theme.md).

## Examples

``` r
if (interactive()) {
  library(shiny)
  library(shinyglass)

  ui <- fluidPage(
    theme = glass_theme(intensity = 0.35),
    glass_theme_toggle(),
    glass_intensity_slider("glass_intensity"),
    plotOutput("p")
  )

  server <- function(input, output, session) {
    observe_glass_theme_toggle(input, session)
    # optional: mirror slider -> server message (client already updates live)
    observe_glass_intensity(input, session, "glass_intensity")
    output$p <- renderPlot(plot(rnorm(100), rnorm(100), pch = 16, col = "#007AFF"))
  }

  shinyApp(ui, server)
}
```
