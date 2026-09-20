# Flatten glass for print, PDF, and screenshots

Neutralizes backdrop blur and translucent fills so chromote, `pagedown`,
print-to-PDF, static HTML, and shareable shots stay readable. The live
page can enter or leave flatten without a reload.

## Usage

``` r
glass_flatten(session, on = TRUE)
```

## Arguments

- session:

  A Shiny session object.

- on:

  `TRUE` to flatten, `FALSE` to restore live glass.

## Value

`session`, invisibly.

## Details

Ways to enter flatten:

- [`glass_theme()`](https://ericrayanderson.github.io/shinyglass/reference/glass_theme.md)
  `flatten = TRUE` (first paint)

- `glass_flatten()` /
  [`update_glass_theme()`](https://ericrayanderson.github.io/shinyglass/reference/update_glass_theme.md)
  `flatten = TRUE` (live)

- `window.shinyglass.setFlatten(true)` (or `.enterFlatten()` /
  `.exitFlatten()`)

- Query string `?glass_flatten=1` (handy for chromote / visual QA)

- `@media print` (automatic for browser print / PDF)

## See also

[`update_glass_theme()`](https://ericrayanderson.github.io/shinyglass/reference/update_glass_theme.md),
[`glass_theme()`](https://ericrayanderson.github.io/shinyglass/reference/glass_theme.md)

## Examples

``` r
if (interactive()) {
  library(shiny)
  library(shinyglass)

  ui <- fluidPage(
    theme = glass_theme(),
    actionButton("flat", "Flatten for capture"),
    actionButton("live", "Live glass")
  )
  server <- function(input, output, session) {
    observeEvent(input$flat, glass_flatten(session, TRUE))
    observeEvent(input$live, glass_flatten(session, FALSE))
  }
  shinyApp(ui, server)
}
```
