# Liquid Glass theme for Shiny

Create a
[`bslib::bs_theme()`](https://rstudio.github.io/bslib/reference/bs_theme.html)
styled with a Liquid Glass look: translucent surfaces, backdrop blur,
soft depth, and system typography. Pass the result to `theme =` on
[`fluidPage()`](https://rdrr.io/pkg/shiny/man/fluidPage.html),
[`navbarPage()`](https://rdrr.io/pkg/shiny/man/navbarPage.html),
[`bslib::page_sidebar()`](https://rstudio.github.io/bslib/reference/page_sidebar.html),
or any other page function that accepts a bslib theme.

## Usage

``` r
glass_theme(
  preset = c("light", "dark", "auto"),
  primary = "#007AFF",
  blur = 28,
  saturation = 200,
  radius = "1.25rem",
  tint = TRUE,
  specular = TRUE,
  nav_morph = TRUE,
  ...
)
```

## Arguments

- preset:

  `"light"`, `"dark"`, or `"auto"`. `"auto"` follows
  `prefers-color-scheme` and updates when the OS theme changes.

- primary:

  Accent color for buttons, links, and focus rings. Defaults to system
  blue (`#007AFF`).

- blur:

  Backdrop blur radius in pixels.

- saturation:

  Backdrop saturation percentage.

- radius:

  Default border radius for glass surfaces (CSS length).

- tint:

  Content-aware ambient tint from plots/images (JS).

- specular:

  Pointer-driven specular highlight on glass surfaces (JS).

- nav_morph:

  Compact navbar on scroll down; expand on scroll up (JS).

- ...:

  Additional arguments forwarded to
  [`bslib::bs_theme()`](https://rstudio.github.io/bslib/reference/bs_theme.html).

## Value

A
[`bslib::bs_theme()`](https://rstudio.github.io/bslib/reference/bs_theme.html)
object suitable for Shiny page functions.

## Details

Light and dark surface tokens are compiled into dual CSS custom-property
packs. Switching `preset` at runtime (via
[`update_glass_theme()`](https://ericrayanderson.github.io/shinyglass/reference/update_glass_theme.md)
or `preset = "auto"`) updates
`document.documentElement.dataset.glassPreset` without recompiling Sass
or reloading the page.

## Examples

``` r
theme <- glass_theme()
dark <- glass_theme(preset = "dark", primary = "#BF5AF2")
auto <- glass_theme(preset = "auto", tint = FALSE)

if (interactive()) {
  library(shiny)

  ui <- fluidPage(
    theme = glass_theme(preset = "auto"),
    titlePanel("Liquid Glass"),
    actionButton("toggle", "Toggle light / dark"),
    selectInput("color", "Color", c("Blue", "Purple", "Orange")),
    plotOutput("plot")
  )

  server <- function(input, output, session) {
    mode <- reactiveVal("light")
    observeEvent(input$toggle, {
      mode(if (identical(mode(), "light")) "dark" else "light")
      update_glass_theme(session, preset = mode())
    })
  }

  shinyApp(ui, server)
}
```
