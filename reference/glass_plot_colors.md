# Ink and grid colors for the current glass appearance

Ink and grid colors for the current glass appearance

## Usage

``` r
glass_plot_colors(preset = NULL, input = NULL)
```

## Arguments

- preset:

  `"light"` or `"dark"`. When `NULL`, uses
  [`glass_resolved_preset()`](https://ericrayanderson.github.io/shinyglass/reference/glass_resolved_preset.md)
  on `input`.

- input:

  Optional Shiny `input` (used when `preset` is `NULL`).

## Value

A list with `preset`, `ink`, `grid`, `fill`, and `paper`.
