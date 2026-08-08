# Theming and light/dark

## Basics

``` r

library(shiny)
library(shinyglass)

ui <- fluidPage(
  theme = glass_theme(), # or preset = "dark" / "auto"
  titlePanel("Liquid Glass"),
  plotOutput("p")
)
```

[`glass_theme()`](https://ericrayanderson.github.io/shinyglass/reference/glass_theme.md)
returns a **bslib** theme. Pass it as `theme =` to
[`fluidPage()`](https://rdrr.io/pkg/shiny/man/fluidPage.html),
[`navbarPage()`](https://rdrr.io/pkg/shiny/man/navbarPage.html),
[`bslib::page_sidebar()`](https://rstudio.github.io/bslib/reference/page_sidebar.html),
and other page helpers that accept a bslib theme.

## Presets

| `preset` | Behavior |
|----|----|
| `"light"` | Light glass pack (default) |
| `"dark"` | Dark glass pack |
| `"auto"` | Follows `prefers-color-scheme`; updates when the OS theme changes |

Light and dark surface tokens ship as dual CSS custom-property packs on
`[data-glass-preset]`. Switching preset updates
`document.documentElement.dataset.glassPreset` — no Sass recompile and
no full page reload.

## Runtime updates from the server

``` r

ui <- fluidPage(
  theme = glass_theme(preset = "auto"),
  actionButton("dark", "Dark"),
  actionButton("light", "Light"),
  actionButton("auto", "Auto")
)

server <- function(input, output, session) {
  observeEvent(input$dark, update_glass_theme(session, preset = "dark"))
  observeEvent(input$light, update_glass_theme(session, preset = "light"))
  observeEvent(input$auto, update_glass_theme(session, preset = "auto"))
}
```

[`update_glass_theme()`](https://ericrayanderson.github.io/shinyglass/reference/update_glass_theme.md)
can also set `tint` (content-aware ambient color from plots and images).

## Behavior knobs

``` r

glass_theme(
  preset = "auto",
  primary = "#AF52DE",
  blur = 28,
  saturation = 200,
  radius = "1.25rem",
  tint = TRUE,      # sample plot/image colors into glass surfaces
  specular = TRUE,  # pointer specular highlight
  nav_morph = TRUE  # compact navbar while scrolling down
)
```

All three JS behaviors default to `TRUE` (same as 0.1.x). They respect
`prefers-reduced-motion: reduce` where relevant. Advanced escape hatch:
`window.__shinyglassDisableTint = true` still disables tint.

## CSS variables (migration)

Prefer CSS custom properties over Sass `$glass-*` tokens when
customizing:

``` css
:root {
  /* shared knobs also set by glass_theme(blur=..., radius=...) */
  --glass-blur: 28px;
  --glass-radius: 1.25rem;
}

:root[data-glass-preset="dark"] {
  /* override a dark-pack value if needed */
  --glass-bg: rgba(255, 255, 255, 0.1);
}
```

## Client helpers

``` js
window.shinyglass.setPreset("dark"); // or "light" / "auto"
window.shinyglass.getPreset();       // resolved "light" | "dark"
window.shinyglass.getMode();         // requested mode incl. "auto"
window.shinyglass.setTint(false);
```

## Teal

``` r

options(teal.bs_theme = glass_theme(preset = "auto"))
# then teal::init(...) as usual
```

## Reduced motion

When the user prefers reduced motion, navbar morph and specular tracking
are disabled, and content tint is skipped.
