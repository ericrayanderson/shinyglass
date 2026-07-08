# Changelog

## shinyglass (development version)

- Fix overlapping glass frames in multi-column layouts (e.g. dreamRs
  gh-dashboard avatar + statiCards): clip plot/html outputs to their
  surfaces, constrain flex columns, and ellipsize long avatar text.

## shinyglass 0.1.0

- Initial release.
- [`glass_theme()`](https://ericrayanderson.github.io/shinyglass/reference/glass_theme.md)
  returns a ‘bslib’ theme with Apple-inspired Liquid Glass styling for
  ‘shiny’ applications.
