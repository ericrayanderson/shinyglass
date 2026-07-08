# Changelog

## shinyglass (development version)

- CRAN packaging: exclude pkgdown `docs/`, vendor demos, and large
  screenshots from the source tarball; load README images from GitHub;
  trim Suggests to packages used by shipped examples and tests.
- Refresh the README and pkgdown site for end users: feature list,
  clearer examples, and no developer-only testing notes.
- Add tier A/B visual coverage: SuperZIP (leaflet), shinyWidgets
  gallery, and a bs4Dash AdminLTE3 demo, with chromote capture script
  `inst/scripts/visual-test-tier-ab.R` and example launchers.
- Fix `replace_page_theme()` for complex nested `theme =` expressions
  (needed to glass-wrap the shinyWidgets gallery).
- Fix overlapping glass frames in multi-column layouts (e.g. dreamRs
  gh-dashboard avatar + statiCards): clip plot/html outputs to their
  surfaces, constrain flex columns, and ellipsize long avatar text.

## shinyglass 0.1.0

- Initial release.
- [`glass_theme()`](https://ericrayanderson.github.io/shinyglass/reference/glass_theme.md)
  returns a ‘bslib’ theme with Apple-inspired Liquid Glass styling for
  ‘shiny’ applications.
