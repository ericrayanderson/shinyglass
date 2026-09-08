# ggplot2 theme that follows glass light/dark ink

Transparent panel and plot backgrounds so the page wallpaper shows
through glass cards. Requires ggplot2 (a Suggests dependency).

## Usage

``` r
theme_glass(preset = NULL, base_size = 13, input = NULL, ...)
```

## Arguments

- preset:

  `"light"` or `"dark"`. When `NULL`, uses
  [`glass_resolved_preset()`](https://ericrayanderson.github.io/shinyglass/reference/glass_resolved_preset.md).

- base_size:

  Base font size passed to
  [`ggplot2::theme_minimal()`](https://ggplot2.tidyverse.org/reference/ggtheme.html).

- input:

  Optional Shiny `input`.

- ...:

  Additional
  [`ggplot2::theme()`](https://ggplot2.tidyverse.org/reference/theme.html)
  arguments.

## Value

A ggplot2 theme object.

## Examples

``` r
if (requireNamespace("ggplot2", quietly = TRUE)) {
  ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) +
    ggplot2::geom_point() +
    theme_glass("light")
}
```
