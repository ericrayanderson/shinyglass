# DT options that pair with glass plot surfaces

Host CSS already skins DataTables (pagination, ink, opaque/clear
panels). This helper is optional: it keeps tables inside glass cards
with wrapping headers and in-card horizontal scroll, the same contract
used by the dashboard demo.

## Usage

``` r
dt_options_glass(..., page_length = 8, scroll_x = FALSE)
```

## Arguments

- ...:

  Named DT `options` that override the defaults.

- page_length:

  Rows per page.

- scroll_x:

  Enable DataTables `scrollX` (useful on narrow viewports).

## Value

A named list for `DT::datatable(options = )`.

## See also

[`gt_theme_glass()`](https://ericrayanderson.github.io/shinyglass/reference/gt_theme_glass.md),
[`glass_theme()`](https://ericrayanderson.github.io/shinyglass/reference/glass_theme.md)

Other glass plots:
[`glass_plot_colors()`](https://ericrayanderson.github.io/shinyglass/reference/glass_plot_colors.md),
[`gt_theme_glass()`](https://ericrayanderson.github.io/shinyglass/reference/gt_theme_glass.md),
[`plotly_glass()`](https://ericrayanderson.github.io/shinyglass/reference/plotly_glass.md),
[`theme_glass()`](https://ericrayanderson.github.io/shinyglass/reference/theme_glass.md)

## Examples

``` r
dt_options_glass(page_length = 8)
#> $pageLength
#> [1] 8
#> 
#> $dom
#> [1] "tip"
#> 
#> $scrollX
#> [1] FALSE
#> 
#> $autoWidth
#> [1] FALSE
#> 
dt_options_glass(searching = FALSE, scroll_x = TRUE)
#> $pageLength
#> [1] 8
#> 
#> $dom
#> [1] "tip"
#> 
#> $scrollX
#> [1] TRUE
#> 
#> $autoWidth
#> [1] FALSE
#> 
#> $searching
#> [1] FALSE
#> 
```
