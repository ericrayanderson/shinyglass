# shinyglass 0.1.0

* Initial release.
* `glass_theme()` returns a [bslib](https://rstudio.github.io/bslib/) theme with
  Apple-inspired Liquid Glass styling for [shiny](https://shiny.posit.co/) apps:
  translucent surfaces, backdrop blur, soft depth, and system typography.
* Light and dark presets, with options for accent color, blur, saturation, and
  corner radius.
* Works with `fluidPage()`, `navbarPage()`, `bslib::page_sidebar()`, and other
  bslib-aware page functions. Pass the theme via `theme = glass_theme()`, or for
  [teal](https://insightsengineering.github.io/teal/) apps via
  `options(teal.bs_theme = glass_theme())`.
* Styles common Bootstrap and Shiny surfaces (cards, navbars, sidebars, inputs,
  tables, plots, modals) and holds up on denser UIs such as leaflet maps, DT,
  shinyWidgets, bs4Dash, and teal filter panels.
