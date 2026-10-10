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
  `preset` is `"light"`, `"dark"`, or `"auto"` (default `"auto"`).
  `intensity` is numeric from `0` (Ultra Clear) to `1` (Tinted), default
  `0.5`. Persistence defaults to `TRUE` here. `floating_sidebar` stays
  off unless you opt in.

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

## See also

[shinyglass](https://ericrayanderson.github.io/shinyglass/reference/shinyglass-package.md),
[`glass_theme()`](https://ericrayanderson.github.io/shinyglass/reference/glass_theme.md),
[`observe_glass()`](https://ericrayanderson.github.io/shinyglass/reference/observe_glass.md),
[`glass_intensity_slider()`](https://ericrayanderson.github.io/shinyglass/reference/glass_intensity_slider.md)

Other glass themes:
[`glass_flatten()`](https://ericrayanderson.github.io/shinyglass/reference/glass_flatten.md),
[`glass_page_react()`](https://ericrayanderson.github.io/shinyglass/reference/glass_page_react.md),
[`glass_theme()`](https://ericrayanderson.github.io/shinyglass/reference/glass_theme.md),
[`glass_theme_dependencies()`](https://ericrayanderson.github.io/shinyglass/reference/glass_theme_dependencies.md),
[`update_glass_theme()`](https://ericrayanderson.github.io/shinyglass/reference/update_glass_theme.md)

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
