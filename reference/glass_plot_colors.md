# Ink and grid colors for the current glass appearance

Ink and grid colors for the current glass appearance

## Usage

``` r
glass_plot_colors(preset = NULL, input = NULL, surface = c("clear", "opaque"))
```

## Arguments

- preset:

  `"light"` or `"dark"`. When `NULL`, uses
  [`glass_resolved_preset()`](https://ericrayanderson.github.io/shinyglass/reference/glass_resolved_preset.md)
  on `input`.

- input:

  Optional Shiny `input` (used when `preset` is `NULL`).

- surface:

  `"clear"` (transparent paper, default) or `"opaque"` (~94% panel
  fill). Pair `"opaque"` with
  [`glass_theme()`](https://ericrayanderson.github.io/shinyglass/reference/glass_theme.md)
  `plot_surface = "opaque"` when the host CSS is not enough (for example
  exported ggplot images).

## Value

A list with `preset`, `ink`, `grid`, `fill`, `paper`, and `surface`.
