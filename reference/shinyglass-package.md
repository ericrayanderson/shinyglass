# Liquid Glass Design Themes for 'shiny' Applications

Drop-in Liquid Glass themes for [shiny](https://shiny.posit.co/). This
is the installed usage page. `help("shinyglass")` and
`help("shinyglass-package")` open it (`?shinyglass` is the same page).
[`vignette("shinyglass")`](https://ericrayanderson.github.io/shinyglass/articles/shinyglass.md)
is this recipe, and `browseVignettes("shinyglass")` lists that vignette.

## Details

Pass
[`glass_theme()`](https://ericrayanderson.github.io/shinyglass/reference/glass_theme.md)
to `theme` on a bslib page or
[`fluidPage()`](https://rdrr.io/pkg/shiny/man/fluidPage.html), or start
from
[`glass_page()`](https://ericrayanderson.github.io/shinyglass/reference/glass_page.md).
Intensity runs from `0` (Ultra Clear) to `1` (Tinted). The default is
`0.5`.

## Minimal app

[`glass_page()`](https://ericrayanderson.github.io/shinyglass/reference/glass_page.md)
includes Light / Dark / Auto, the intensity slider, and accent wells,
and it turns persistence on. Call
[`observe_glass()`](https://ericrayanderson.github.io/shinyglass/reference/observe_glass.md)
in the server. Keep plot backgrounds transparent and take ink from
[`glass_plot_colors()`](https://ericrayanderson.github.io/shinyglass/reference/glass_plot_colors.md).

    library(shiny)
    library(shinyglass)

    ui <- glass_page(
      title = "Hello, glass",
      sliderInput("n", "Bars", 5, 30, 15),
      plotOutput("plot")
    )

    server <- function(input, output, session) {
      observe_glass(input, session)
      output$plot <- renderPlot({
        pal <- glass_plot_colors(input = input)
        barplot(seq_len(input$n), col = pal$fill, border = NA, col.axis = pal$ink)
      }, bg = "transparent")
    }

    shinyApp(ui, server)

## Mobile support

The same app works on desktop and phone with no extra code. Controls are
sized for touch, sidebars and popovers open and close as expected on a
phone, and pages do not scroll sideways. On a desktop, each live demo
has a Phone view button that shows it in a phone-sized frame.

![Basics demo in a phone-sized frame](figures/phone-frame-demo.png)

## Existing app

Keep the page function you already use. Pass the theme, add the
controls, and observe them.
[`page_sidebar()`](https://rstudio.github.io/bslib/reference/page_sidebar.html),
[`page_fluid()`](https://rstudio.github.io/bslib/reference/page.html),
[`page_navbar()`](https://rstudio.github.io/bslib/reference/page_navbar.html),
[`page_fillable()`](https://rstudio.github.io/bslib/reference/page_fillable.html),
and [`navbarPage()`](https://rdrr.io/pkg/shiny/man/navbarPage.html) all
take `theme`. `fluidPage(theme = glass_theme())` works too.

    library(shiny)
    library(bslib)
    library(shinyglass)

    ui <- page_sidebar(
      title = "Existing app",
      theme = glass_theme(preset = "auto", intensity = 0.5),
      sidebar = sidebar(
        glass_theme_toggle(),
        glass_intensity_slider()
      ),
      "Main column"
    )

    server <- function(input, output, session) {
      observe_glass(input, session)
    }

    shinyApp(ui, server)

[`fluidPage()`](https://rdrr.io/pkg/shiny/man/fluidPage.html) and
[`navbarPage()`](https://rdrr.io/pkg/shiny/man/navbarPage.html) take the
same `theme`:

    ui <- fluidPage(
      theme = glass_theme(preset = "auto", intensity = 0.5),
      glass_theme_toggle(),
      glass_intensity_slider(),
      plotOutput("plot")
    )

The server is unchanged: `observe_glass(input, session)`.

[`glass_theme()`](https://ericrayanderson.github.io/shinyglass/reference/glass_theme.md)
does not remember choices (`persist = FALSE`).
[`glass_page()`](https://ericrayanderson.github.io/shinyglass/reference/glass_page.md)
does (`persist = TRUE`).

## Key options

|  |  |  |
|----|----|----|
| Argument | Default | Allowed |
| `preset` | `"light"` on [`glass_theme()`](https://ericrayanderson.github.io/shinyglass/reference/glass_theme.md), `"auto"` on [`glass_page()`](https://ericrayanderson.github.io/shinyglass/reference/glass_page.md) | `"light"`, `"dark"`, `"auto"` |
| `intensity` | `0.5` | number from `0` (Ultra Clear) to `1` (Tinted) |
| `primary` | `"#007AFF"` | hex, [`rgb()`](https://rdrr.io/r/grDevices/rgb.html), or a name from [`glass_system_colors()`](https://ericrayanderson.github.io/shinyglass/reference/glass_system_colors.md) |
| `material` | `"regular"` | `"regular"`. `"clear"` is deprecated |
| `plot_surface` | `"clear"` | `"clear"`, `"opaque"` |
| `scene` | `"default"` (`"tahoe"` on [`glass_page()`](https://ericrayanderson.github.io/shinyglass/reference/glass_page.md)) | `names(glass_scenes())` |
| `persist` | `FALSE` (`TRUE` on [`glass_page()`](https://ericrayanderson.github.io/shinyglass/reference/glass_page.md)) | `TRUE` or `FALSE` |
| `refraction`, `morph`, `press`, `scroll_edge`, `minimize_tabs` | `TRUE` | `TRUE` or `FALSE` |
| `icon_style` | `"clear"` | `"clear"`, `"color"`, `"all"` |
| `floating_sidebar` | `FALSE` | `TRUE` or `FALSE` |
| `specular` | `TRUE` | `TRUE` or `FALSE`. Highlights are static bands |

[`update_glass_theme()`](https://ericrayanderson.github.io/shinyglass/reference/update_glass_theme.md)
changes these in a running app. `NULL` leaves that setting alone. When
the user picks Auto, `input$glass_preset` stays `"auto"`. Plot ink must
use
[`glass_resolved_preset()`](https://ericrayanderson.github.io/shinyglass/reference/glass_resolved_preset.md),
which is `"light"` or `"dark"`.

## Migrating to 0.5.0

[`vignette("migrating")`](https://ericrayanderson.github.io/shinyglass/articles/migrating.md)
is the full note.

- Default intensity moved from `0.45` to `0.5`.

- `material = "clear"` is deprecated. Delete it and pass `intensity`.
  When `intensity` is omitted, clear maps to `0.12` and warns. To keep
  that look, write `intensity = 0.12`.

- Specular highlights no longer follow the pointer. `specular = FALSE`
  hides them.

- `refraction`, `morph`, `press`, `scroll_edge`, `minimize_tabs`, and
  `icon_style = "clear"` are on by default. `floating_sidebar` stays
  off.

- Page functions and click targets stay the same.

## Pitfalls

- App CSS that sets panel or text colors fights the theme. Use
  `--glass-*` tokens from
  [`glass_css_tokens()`](https://ericrayanderson.github.io/shinyglass/reference/glass_css_tokens.md),
  or `glass_theme(tokens = list(blur = "28px"))`.

- Plots and tables are transparent. Pass `bg = "transparent"` to
  [`renderPlot()`](https://rdrr.io/pkg/shiny/man/renderPlot.html), or
  set `plot_surface = "opaque"` when the wallpaper makes the graphic
  hard to read. Color ink with
  [`glass_plot_colors()`](https://ericrayanderson.github.io/shinyglass/reference/glass_plot_colors.md).

- [`observe_glass()`](https://ericrayanderson.github.io/shinyglass/reference/observe_glass.md)
  only watches `glass_toggle`, `glass_intensity`, and `glass_accent`. A
  custom id needs the matching `observe_glass_*()` helper.

- For shinyreact, name the theme:
  `glass_page_react(theme = glass_theme())`. An unnamed theme drops the
  CSS. `page_react_html()` has no `theme` argument; pass
  `extra_deps = glass_theme_dependencies()`.

- shinychat: `page_chat(theme = glass_theme())`. bslib
  [`offcanvas()`](https://rstudio.github.io/bslib/reference/offcanvas.html)
  uses the same material.

- Reduced transparency, increased contrast, and forced colors override
  the glass.
  [`glass_flatten()`](https://ericrayanderson.github.io/shinyglass/reference/glass_flatten.md)
  or `?glass_flatten=1` removes blur for screenshots and PDF.

[`vignette("shinyglass")`](https://ericrayanderson.github.io/shinyglass/articles/shinyglass.md)
is this same recipe, installed with the package.

## See also

[`glass_page()`](https://ericrayanderson.github.io/shinyglass/reference/glass_page.md),
[`glass_theme()`](https://ericrayanderson.github.io/shinyglass/reference/glass_theme.md),
[`update_glass_theme()`](https://ericrayanderson.github.io/shinyglass/reference/update_glass_theme.md),
[`observe_glass()`](https://ericrayanderson.github.io/shinyglass/reference/observe_glass.md),
[`glass_intensity_slider()`](https://ericrayanderson.github.io/shinyglass/reference/glass_intensity_slider.md),
[`glass_plot_colors()`](https://ericrayanderson.github.io/shinyglass/reference/glass_plot_colors.md),
[`glass_page_react()`](https://ericrayanderson.github.io/shinyglass/reference/glass_page_react.md),
[`glass_flatten()`](https://ericrayanderson.github.io/shinyglass/reference/glass_flatten.md)

## Author

**Maintainer**: Eric Anderson <eric.ray.anderson@gmail.com> \[copyright
holder\]

Authors:

- Eric Anderson <eric.ray.anderson@gmail.com> \[copyright holder\]

## Examples

``` r
inherits(glass_theme(preset = "auto", intensity = 0.5), "bs_theme")
#> [1] TRUE
```
