# Ink and grid colors for the current glass appearance

Returns the ink, grid, fill, and paper colors for a light or dark glass
page. Pass `surface = "opaque"` when a chart must sit on a near-solid
panel.

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

## See also

[`theme_glass()`](https://ericrayanderson.github.io/shinyglass/reference/theme_glass.md),
[`plotly_glass()`](https://ericrayanderson.github.io/shinyglass/reference/plotly_glass.md),
[`glass_resolved_preset()`](https://ericrayanderson.github.io/shinyglass/reference/glass_resolved_preset.md)

Other glass plots:
[`dt_options_glass()`](https://ericrayanderson.github.io/shinyglass/reference/dt_options_glass.md),
[`gt_theme_glass()`](https://ericrayanderson.github.io/shinyglass/reference/gt_theme_glass.md),
[`plotly_glass()`](https://ericrayanderson.github.io/shinyglass/reference/plotly_glass.md),
[`theme_glass()`](https://ericrayanderson.github.io/shinyglass/reference/theme_glass.md)

## Examples

``` r
glass_plot_colors("light")
#> $preset
#> [1] "light"
#> 
#> $ink
#> [1] "#1d1d1f"
#> 
#> $grid
#> [1] "rgba(29,29,31,0.10)"
#> 
#> $fill
#> [1] "#007AFF"
#> 
#> $paper
#> [1] "rgba(0,0,0,0)"
#> 
#> $surface
#> [1] "clear"
#> 
glass_plot_colors("dark", surface = "opaque")$paper
#> [1] "rgba(28,28,30,0.94)"
```
