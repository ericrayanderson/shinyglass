# Apple Liquid Glass theme for Shiny

Create a
[`bslib::bs_theme()`](https://rstudio.github.io/bslib/reference/bs_theme.html)
styled with an Apple-inspired Liquid Glass look: translucent surfaces,
backdrop blur, soft depth, and system typography. Pass the result to
`theme =` on
[`fluidPage()`](https://rdrr.io/pkg/shiny/man/fluidPage.html),
[`navbarPage()`](https://rdrr.io/pkg/shiny/man/navbarPage.html),
[`bslib::page_sidebar()`](https://rstudio.github.io/bslib/reference/page_sidebar.html),
or any other page function that accepts a bslib theme.

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

  `"light"` or `"dark"`. Switches the full color system.

- primary:

  Accent color for buttons, links, and focus rings. Defaults to Apple
  system blue (`#007AFF`).

- blur:

  Backdrop blur radius in pixels.

- saturation:

  Backdrop saturation percentage.

- radius:

  Default border radius for glass surfaces (CSS length).

- ...:

  Additional arguments forwarded to
  [`bslib::bs_theme()`](https://rstudio.github.io/bslib/reference/bs_theme.html).

## Value

A
[`bslib::bs_theme()`](https://rstudio.github.io/bslib/reference/bs_theme.html)
object suitable for Shiny page functions.

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

# Dark preset with a custom accent
ui <- fluidPage(
  theme = glass_theme(preset = "dark", primary = "#BF5AF2"),
  titlePanel("Dark glass")
)
} # }
```
