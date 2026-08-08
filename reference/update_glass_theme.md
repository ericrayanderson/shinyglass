# Update glass theme options in a running app

Send a message to the browser to change the Liquid Glass preset or
content-tint behavior without reloading the page. Requires a page that
used
[`glass_theme()`](https://ericrayanderson.github.io/shinyglass/reference/glass_theme.md)
(so `shiny-glass.js` is loaded).

## Usage

``` r
update_glass_theme(session, preset = NULL, tint = NULL)
```

## Arguments

- session:

  A Shiny session object (usually the `session` argument of the server
  function).

- preset:

  Optional. `"light"`, `"dark"`, or `"auto"`.

- tint:

  Optional logical. Enable or disable content-aware ambient tint.

## Value

`session`, invisibly.

## Examples

``` r
if (interactive()) {
  library(shiny)
  library(shinyglass)

  ui <- fluidPage(
    theme = glass_theme(),
    actionButton("dark", "Dark"),
    actionButton("light", "Light")
  )

  server <- function(input, output, session) {
    observeEvent(input$dark, update_glass_theme(session, preset = "dark"))
    observeEvent(input$light, update_glass_theme(session, preset = "light"))
  }

  shinyApp(ui, server)
}
```
