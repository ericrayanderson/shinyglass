# Light / dark / auto theme toggle buttons

Drop-in button group for switching the glass preset. Each button sets
the preset on the client immediately (`window.shinyglass.setPreset`) and
also has a 'shiny' input id so
[`observe_glass_theme_toggle()`](https://ericrayanderson.github.io/shinyglass/reference/observe_glass_theme_toggle.md)
can keep the server in sync (important on hosts that rewrite custom
messages).

## Usage

``` r
glass_theme_toggle(
  inputId = "glass_toggle",
  selected = c("auto", "light", "dark"),
  labels = c(light = "Light", dark = "Dark", auto = "Auto (OS)"),
  class = "d-flex flex-wrap gap-2 glass-theme-toggle"
)
```

## Arguments

- inputId:

  Base id. Buttons are `{inputId}_light`, `{inputId}_dark`, and
  `{inputId}_auto`.

- selected:

  Initially highlighted mode (`"light"`, `"dark"`, or `"auto"`).
  Cosmetic only; the page theme still comes from
  [`glass_theme()`](https://ericrayanderson.github.io/shinyglass/reference/glass_theme.md).

- labels:

  Named character vector for button labels. Names must be `light`,
  `dark`, and/or `auto`.

- class:

  Extra CSS classes for the wrapper.

## Value

An
[`htmltools::tag()`](https://rstudio.github.io/htmltools/reference/builder.html)
button group.

## See also

[`observe_glass_theme_toggle()`](https://ericrayanderson.github.io/shinyglass/reference/observe_glass_theme_toggle.md),
[`update_glass_theme()`](https://ericrayanderson.github.io/shinyglass/reference/update_glass_theme.md)
