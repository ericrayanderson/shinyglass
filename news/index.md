# Changelog

## shinyglass (development version)

- Fix contrast on range value chips (`sliderInput` bubbles, noUi
  tooltips): use luminance-aware ink via `glass-on()`, scoped so badges
  and other Bootstrap surfaces are unchanged.
- README hero uses denser bslib dashboard light/dark screenshots.

## shinyglass 0.1.0

- Initial release.
- [`glass_theme()`](https://ericrayanderson.github.io/shinyglass/reference/glass_theme.md)
  returns a [bslib](https://rstudio.github.io/bslib/) theme with Liquid
  Glass styling for [shiny](https://shiny.posit.co/) apps: translucent
  surfaces, backdrop blur, soft depth, and system typography.
- Light and dark presets, with options for accent color, blur,
  saturation, and corner radius.
- Works with
  [`fluidPage()`](https://rdrr.io/pkg/shiny/man/fluidPage.html),
  [`navbarPage()`](https://rdrr.io/pkg/shiny/man/navbarPage.html),
  [`bslib::page_sidebar()`](https://rstudio.github.io/bslib/reference/page_sidebar.html),
  and other bslib-aware page functions. Pass the theme via
  `theme = glass_theme()`, or for
  [teal](https://insightsengineering.github.io/teal/) apps via
  `options(teal.bs_theme = glass_theme())`.
- Styles common Bootstrap and Shiny surfaces (cards, navbars, sidebars,
  inputs, tables, plots, modals) and holds up on denser UIs such as
  leaflet maps, DT, shinyWidgets, bs4Dash, and teal filter panels.
