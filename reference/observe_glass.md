# Observe every built-in glass control

Registers
[`observe_glass_theme_toggle()`](https://ericrayanderson.github.io/shinyglass/reference/observe_glass_theme_toggle.md),
[`observe_glass_intensity()`](https://ericrayanderson.github.io/shinyglass/reference/observe_glass_intensity.md),
and
[`observe_glass_accent()`](https://ericrayanderson.github.io/shinyglass/reference/observe_glass_accent.md)
with the default input ids used by
[`glass_page()`](https://ericrayanderson.github.io/shinyglass/reference/glass_page.md).

## Usage

``` r
observe_glass(
  input,
  session,
  toggle_id = "glass_toggle",
  intensity_id = "glass_intensity",
  accent_id = "glass_accent"
)
```

## Arguments

- input, session:

  Shiny `input` and `session` objects.

- toggle_id, intensity_id, accent_id:

  Input ids matching the UI controls.

## Value

`NULL`, invisibly.
