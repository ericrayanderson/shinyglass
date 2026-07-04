# Apple Liquid Glass theme for Shiny

Returns a \[bslib::bs_theme()\] object styled with Apple's Liquid Glass
aesthetic. Pass it to \`fluidPage()\`, \`navbarPage()\`, or any
bslib-aware page function; that is all you need.

## Usage

``` r
glass_theme(
  preset = c("light", "dark"),
  primary = "#007AFF",
  blur = 28,
  saturation = 200,
  radius = "1.25rem",
  ...
)
```

## Arguments

- preset:

  \`"light"\` or \`"dark"\`. Controls the overall color scheme.

- primary:

  Primary accent color. Defaults to Apple system blue (\`#007AFF\`).

- blur:

  Backdrop blur radius in pixels.

- saturation:

  Backdrop saturation percentage.

- radius:

  Default border radius for glass surfaces.

- ...:

  Additional arguments forwarded to \[bslib::bs_theme()\].

## Value

A \[bslib::bs_theme()\] object.

## Examples

``` r
if (FALSE) { # \dontrun{
library(shiny)
library(shinyglass)

ui <- fluidPage(
  theme = glass_theme(),
  titlePanel("Liquid Glass"),
  selectInput("color", "Color", c("Blue", "Purple", "Orange")),
  plotOutput("plot")
)
} # }
```
