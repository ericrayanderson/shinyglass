# plotly layout that matches glass chrome

Transparent paper/plot backgrounds and ink that follows the resolved
preset. Requires plotly. Call as `plotly_glass(p)` or
`do.call(plotly::layout, c(list(p), plotly_glass()))`.

## Usage

``` r
plotly_glass(p = NULL, preset = NULL, input = NULL)
```

## Arguments

- p:

  Optional plotly object. When `NULL`, returns a named list of layout
  arguments.

- preset, input:

  See
  [`glass_plot_colors()`](https://ericrayanderson.github.io/shinyglass/reference/glass_plot_colors.md).

## Value

`p` with layout applied, or a list of layout arguments.
