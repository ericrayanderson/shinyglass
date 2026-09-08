# Accent color wells

Compact row of color wells. The client applies
`window.shinyglass.setPrimary()` immediately; the value is also a Shiny
input (`input[[inputId]]`) so the server can persist or restyle plots.
Pair with
[`observe_glass_accent()`](https://ericrayanderson.github.io/shinyglass/reference/observe_glass_accent.md)
if you also want
[`update_glass_theme()`](https://ericrayanderson.github.io/shinyglass/reference/update_glass_theme.md)
to echo the change.

## Usage

``` r
glass_accent_input(
  inputId = "glass_accent",
  label = "Accent",
  selected = "blue",
  colors = glass_system_colors()
)
```

## Arguments

- inputId:

  The `input` slot that will be used to access the hex value.

- label:

  Display label (or `NULL` for none).

- selected:

  Initially selected well: a name in `colors` or a hex string.

- colors:

  Named character vector of hex colors. Defaults to
  [`glass_system_colors()`](https://ericrayanderson.github.io/shinyglass/reference/glass_system_colors.md).

## Value

A Shiny UI tag hierarchy.
