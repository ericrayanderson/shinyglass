# Light / dark / auto preset select input

Drop-in
[`shiny::selectInput()`](https://rdrr.io/pkg/shiny/man/selectInput.html)
for the glass theme preset. The client applies the change
**immediately** via `window.shinyglass.setPreset()` (marked with
`data-glass-preset-input`), so Light/Dark/Auto works even when custom
messages are delayed or rewritten (e.g. on some shinyapps.io hosts).
Pair with
[`observe_glass_preset_input()`](https://ericrayanderson.github.io/shinyglass/reference/observe_glass_preset_input.md)
so the server stays in sync.

## Usage

``` r
glass_preset_input(
  inputId = "glass_preset",
  label = "Theme preset",
  selected = c("auto", "light", "dark"),
  choices = c(Light = "light", Dark = "dark", `Auto (OS)` = "auto"),
  width = NULL
)
```

## Arguments

- inputId:

  The `input` slot that will be used to access the value.

- label:

  Display label for the control (or `NULL` for none).

- selected:

  Initially selected mode (`"light"`, `"dark"`, or `"auto"`).

- choices:

  Named character vector of choices. Defaults to Light / Dark / Auto
  (OS). Names are labels; values must be `light`, `dark`, and/or `auto`.

- width:

  The width of the input (e.g. `"100%"`).

## Value

A
[`shiny::selectInput()`](https://rdrr.io/pkg/shiny/man/selectInput.html)
tag (with glass client bindings).

## See also

[`observe_glass_preset_input()`](https://ericrayanderson.github.io/shinyglass/reference/observe_glass_preset_input.md),
[`glass_theme_toggle()`](https://ericrayanderson.github.io/shinyglass/reference/glass_theme_toggle.md),
[`update_glass_theme()`](https://ericrayanderson.github.io/shinyglass/reference/update_glass_theme.md)
