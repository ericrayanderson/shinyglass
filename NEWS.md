# shinyglass (development version)

* Teal gallery visual coverage (`inst/scripts/visual-test-teal.R`) plus CSS
  fixes for teal/teal.slice: pin filter sidebars so they no longer expand
  full-width over module tables, skip glass frames on empty
  `shiny-html-output` placeholders, raise modal opacity, and glass teal
  nav/filter/accordion chrome. Example: `inst/examples/teal-glass-demo.R`.
* Checked and documented under R 4.6.
* Simplify the README to a short background and quick start.
* Inject the glass preset via an `htmlDependency` head script instead of
  a `tagFunction` that returned tags (avoids an htmltools warning when
  resolving theme dependencies).
* CRAN packaging: exclude pkgdown `docs/`, vendor demos, and large
  screenshots from the source tarball; load README images from GitHub;
  trim Suggests to packages used by shipped examples and tests.
* Add tier A/B visual coverage: SuperZIP (leaflet), shinyWidgets gallery,
  and a bs4Dash AdminLTE3 demo, with chromote capture script
  `inst/scripts/visual-test-tier-ab.R` and example launchers.
* Fix `replace_page_theme()` for complex nested `theme =` expressions
  (needed to glass-wrap the shinyWidgets gallery).
* Fix overlapping glass frames in multi-column layouts (e.g. dreamRs
  gh-dashboard avatar + statiCards): clip plot/html outputs to their
  surfaces, constrain flex columns, and ellipsize long avatar text.

# shinyglass (development)

* Teal gallery visual coverage (`inst/scripts/visual-test-teal.R`) and CSS
  fixes for teal/teal.slice: filter sidebars no longer expand full-width over
  module tables, empty `shiny-html-output` placeholders no longer render as
  thin glass bars, modals are more opaque, and teal nav/filter/accordion
  chrome picks up glass surfaces.
* New example: `inst/examples/teal-glass-demo.R` (`options(teal.bs_theme = glass_theme())`).

# shinyglass 0.1.0

* Initial release.
* `glass_theme()` returns a 'bslib' theme with Apple-inspired Liquid Glass
  styling for 'shiny' applications.