# plotly layout that matches glass chrome

Transparent paper/plot backgrounds and ink that follows the resolved
preset. Requires plotly. Call as `plotly_glass(p)` or
`do.call(plotly::layout, c(list(p), plotly_glass()))`.

## Usage

``` r
plotly_glass(
  p = NULL,
  preset = NULL,
  input = NULL,
  surface = c("clear", "opaque")
)
```

## Arguments

- p:

  Optional plotly object. When `NULL`, returns a named list of layout
  arguments.

- preset, input, surface:

  See
  [`glass_plot_colors()`](https://ericrayanderson.github.io/shinyglass/reference/glass_plot_colors.md).

## Value

`p` with layout applied, or a list of layout arguments.

## See also

[`glass_plot_colors()`](https://ericrayanderson.github.io/shinyglass/reference/glass_plot_colors.md),
[`theme_glass()`](https://ericrayanderson.github.io/shinyglass/reference/theme_glass.md)

Other glass plots:
[`dt_options_glass()`](https://ericrayanderson.github.io/shinyglass/reference/dt_options_glass.md),
[`glass_plot_colors()`](https://ericrayanderson.github.io/shinyglass/reference/glass_plot_colors.md),
[`gt_theme_glass()`](https://ericrayanderson.github.io/shinyglass/reference/gt_theme_glass.md),
[`theme_glass()`](https://ericrayanderson.github.io/shinyglass/reference/theme_glass.md)

## Examples

``` r
layout <- plotly_glass(preset = "dark")
layout$font$color
#> [1] "#f5f5f7"
```
