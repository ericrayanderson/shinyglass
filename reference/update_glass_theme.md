# Update glass theme options in a running app

Send a message to the browser to change the Liquid Glass preset, accent
color, or content-tint behavior without reloading the page. Requires a
page that used
[`glass_theme()`](https://ericrayanderson.github.io/shinyglass/reference/glass_theme.md)
(so `shiny-glass.js` is loaded).

## Usage

``` r
update_glass_theme(
  session,
  preset = NULL,
  tint = NULL,
  primary = NULL,
  intensity = NULL
)
```

## Arguments

- session:

  A Shiny session object (usually the `session` argument of the server
  function).

- preset:

  Optional. `"light"`, `"dark"`, or `"auto"`.

- tint:

  Optional logical. Enable or disable content-aware ambient tint.

- primary:

  Optional accent color (hex like `"#AF52DE"` or
  [`rgb()`](https://rdrr.io/r/grDevices/rgb.html)).

- intensity:

  Optional numeric in \\\[0, 1\]\\: Ultra Clear (`0`) to Tinted (`1`).

## Value

`session`, invisibly.

## Details

`primary` updates CSS variables (`--bs-primary`, `--bs-primary-rgb`,
`--glass-primary`) so buttons, checks, and other accent surfaces follow
the new color. Sass-baked one-off colors may not all switch until a full
reload.

## Examples

``` r
if (interactive()) {
  library(shiny)
  library(shinyglass)

  ui <- fluidPage(
    theme = glass_theme(),
    glass_theme_toggle(),
    selectInput("accent", "Accent", c("#007AFF", "#AF52DE", "#FF9500"))
  )

  server <- function(input, output, session) {
    observe_glass_theme_toggle(input, session)
    observeEvent(input$accent, {
      update_glass_theme(session, primary = input$accent)
    }, ignoreInit = TRUE)
  }

  shinyApp(ui, server)
}
```
