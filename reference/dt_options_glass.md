# DT options that pair with glass plot surfaces

Host CSS already skins DataTables (pagination, ink, opaque/clear
panels). This helper is optional: it keeps tables inside glass cards
with wrapping headers and in-card horizontal scroll — the same contract
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
