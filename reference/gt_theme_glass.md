# gt table options that match glass chrome

Transparent table chrome so glass cards show through. Requires gt.

## Usage

``` r
gt_theme_glass(
  data,
  preset = NULL,
  input = NULL,
  surface = c("clear", "opaque")
)
```

## Arguments

- data:

  A [`gt::gt()`](https://gt.rstudio.com/reference/gt.html) table (or
  data frame, which is passed to `gt()`).

- preset, input, surface:

  See
  [`glass_plot_colors()`](https://ericrayanderson.github.io/shinyglass/reference/glass_plot_colors.md).

## Value

A gt table.

## See also

[`dt_options_glass()`](https://ericrayanderson.github.io/shinyglass/reference/dt_options_glass.md),
[`glass_plot_colors()`](https://ericrayanderson.github.io/shinyglass/reference/glass_plot_colors.md)

Other glass plots:
[`dt_options_glass()`](https://ericrayanderson.github.io/shinyglass/reference/dt_options_glass.md),
[`glass_plot_colors()`](https://ericrayanderson.github.io/shinyglass/reference/glass_plot_colors.md),
[`plotly_glass()`](https://ericrayanderson.github.io/shinyglass/reference/plotly_glass.md),
[`theme_glass()`](https://ericrayanderson.github.io/shinyglass/reference/theme_glass.md)

## Examples

``` r
if (requireNamespace("gt", quietly = TRUE)) {
  gt_theme_glass(head(mtcars), preset = "light")
}


  

mpg
```
