# shinyglass

<!-- badges: start -->
[![License: GPL-3](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](https://www.r-project.org/Licenses/GPL-3)
[![R-CMD-check](https://github.com/ericrayanderson/shinyglass/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/ericrayanderson/shinyglass/actions/workflows/R-CMD-check.yaml)
[![visual-qa](https://github.com/ericrayanderson/shinyglass/actions/workflows/visual-qa.yaml/badge.svg)](https://github.com/ericrayanderson/shinyglass/actions/workflows/visual-qa.yaml)
<!-- badges: end -->

Glass themes for [Shiny](https://shiny.posit.co/), built on [bslib](https://rstudio.github.io/bslib/). Add translucent surfaces, live light/dark switching, and adjustable glass intensity to your app.

[Documentation](https://ericrayanderson.github.io/shinyglass/) · [Theming guide](https://ericrayanderson.github.io/shinyglass/articles/theming.html) · [Release notes](https://ericrayanderson.github.io/shinyglass/news/index.html)

<p align="center">
<img src="https://raw.githubusercontent.com/ericrayanderson/shinyglass/main/man/figures/intensity-slider.gif" width="72%" alt="Glass intensity changing from clear to tinted">
</p>

## Install

CRAN **0.4.0**:

```r
install.packages("shinyglass")
```

Development builds (GitHub):

```r
# install.packages("remotes")
remotes::install_github("ericrayanderson/shinyglass")
```

## Quick start

```r
library(shiny)
library(shinyglass)

ui <- glass_page(
  title = "Hello, glass",
  persist = TRUE,
  scene = "tahoe",
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
```

`glass_page()` includes Light / Dark / Auto, the intensity slider, and accent
wells. Set `persist = TRUE` (the default here) to remember those choices.

The intensity slider mirrors iOS 27 **Settings → Appearance → Liquid Glass**
(continuous Ultra Clear → Tinted). The default is `0.5`, Apple's midpoint.
Browsers cannot read that OS slider, so the in-app control is the supported
way to match the look. Reduce Transparency paints solid fills with no backdrop
blur. Increase Contrast and forced colors override the glass variables.

Defaults also follow iOS 27 as far as a browser can. Chromium refracts the
backdrop through a squircle lens. Safari and Firefox keep blur and tint.
Active pills and tabs spring into each other, buttons press with a short
spring, and floating bars pick up a scroll-edge fade. Tab bars shrink while
you scroll down. Specular highlights are static (no pointer tilt). Icons in
bars and non-primary buttons are monochrome clear glass (`icon_style =
"clear"`). Pass `icon_style = "color"` to keep author colors. The detached
sidebar is opt-in: `floating_sidebar = TRUE`.

Dense charts and tables can opt into a regular panel with
`glass_theme(plot_surface = "opaque")` while nav and controls stay on glass.
The default `"clear"` look still shows the wallpaper through plot hosts.
Use `glass_plot_surface_input()` to toggle live (ggplot / plotly / gt / DT).

Named wallpaper scenes (`tahoe`, `dusk`, `mesh`, `aurora`, `harbor`, `grove`)
and optional `wallpaper=` photos stay behind a blur + wash so text meets the
contrast floor. For chromote, PDF, or screenshots, call `glass_flatten()` or
open the app with `?glass_flatten=1`.

Power users can read `glass_css_tokens()` and override `--glass-*` variables
with `glass_theme(tokens = list(blur = "28px"))` without forking SCSS.

## Live demos

Apps may take a moment to wake up.

| Demo | Explore |
|------|---------|
| [Basics](https://ericrayanderson.shinyapps.io/shinyglass-demo/) | Theme switching and core controls |
| [Dashboard](https://ericrayanderson.shinyapps.io/shinyglass-dashboard/) | Cards, plots, and tables |
| [Inputs](https://ericrayanderson.shinyapps.io/shinyglass-inputs/) | Shiny input controls |
| [Olympic medals](https://ericrayanderson.shinyapps.io/shinyglass-olympics/) | A complete dashboard |
| [plotly + gt](https://ericrayanderson.shinyapps.io/shinyglass-plotly-gt/) | Interactive charts and tables |

Built for Bootstrap 5 and bslib. See [compatibility](https://ericrayanderson.github.io/shinyglass/articles/compatibility.html) for supported widgets and older layouts.

More: [examples](https://github.com/ericrayanderson/shinyglass/tree/main/inst/examples) ·
[experimental Python package](https://github.com/ericrayanderson/shinyglass/tree/main/python) ·
[testing](https://github.com/ericrayanderson/shinyglass/blob/main/inst/scripts/VISUAL-QA.md) ·
[deployment](https://github.com/ericrayanderson/shinyglass/blob/main/inst/scripts/SHINYAPPS-DEPLOY.md)
