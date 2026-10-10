# One-call glass page

Wraps
[`shiny::fluidPage()`](https://rdrr.io/pkg/shiny/man/fluidPage.html)
with
[`glass_theme()`](https://ericrayanderson.github.io/shinyglass/reference/glass_theme.md)
and, by default, the Light / Dark / Auto toggle, intensity slider, and
accent wells. Pair with
[`observe_glass()`](https://ericrayanderson.github.io/shinyglass/reference/observe_glass.md)
in the server function.

## Usage

``` r
glass_page(
  ...,
  title = NULL,
  preset = "auto",
  intensity = 0.5,
  persist = TRUE,
  scene = "tahoe",
  wallpaper = NULL,
  plot_surface = "clear",
  flatten = FALSE,
  refraction = TRUE,
  morph = TRUE,
  press = TRUE,
  scroll_edge = TRUE,
  minimize_tabs = TRUE,
  icon_style = c("clear", "color", "all"),
  floating_sidebar = FALSE,
  controls = TRUE,
  theme = NULL
)
```

## Arguments

- ...:

  UI elements passed to
  [`shiny::fluidPage()`](https://rdrr.io/pkg/shiny/man/fluidPage.html).

- title:

  Optional page title
  ([`shiny::titlePanel()`](https://rdrr.io/pkg/shiny/man/titlePanel.html)).

- preset, intensity, persist, scene, wallpaper, plot_surface, flatten,
  refraction, morph, press, scroll_edge, minimize_tabs, icon_style,
  floating_sidebar:

  Forwarded to
  [`glass_theme()`](https://ericrayanderson.github.io/shinyglass/reference/glass_theme.md).
  Persistence defaults to `TRUE` here. `floating_sidebar` stays off
  unless you opt in.

- controls:

  `TRUE` for the default control row (toggle, intensity, accent),
  `FALSE` for none, or a character vector subset of `"toggle"`,
  `"intensity"`, `"accent"`.

- theme:

  Optional pre-built
  [`glass_theme()`](https://ericrayanderson.github.io/shinyglass/reference/glass_theme.md)
  object. When `NULL`, one is created from the arguments above.

## Value

A Shiny UI tag list suitable as `shinyApp(ui = ...)`.

## Examples

``` r
if (interactive()) {
  library(shiny)
  library(shinyglass)

  ui <- glass_page(
    title = "Hello, glass",
    plotOutput("plot")
  )
  server <- function(input, output, session) {
    observe_glass(input, session)
    output$plot <- renderPlot(plot(1:10), bg = "transparent")
  }
  shinyApp(ui, server)
}
```
