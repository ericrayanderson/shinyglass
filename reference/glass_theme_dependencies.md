# HTML dependencies for a glass theme

Turns
[`glass_theme()`](https://ericrayanderson.github.io/shinyglass/reference/glass_theme.md)
into the
[`htmltools::htmlDependency()`](https://rstudio.github.io/htmltools/reference/htmlDependency.html)
list that
[`bslib::bs_theme_dependencies()`](https://rstudio.github.io/bslib/reference/bs_theme_dependencies.html)
would attach on a Bootstrap page. Use this when the page has no `theme`
argument, in particular
`shinyreact::page_react_html(extra_deps = glass_theme_dependencies(...))`.

## Usage

``` r
glass_theme_dependencies(theme = glass_theme())
```

## Arguments

- theme:

  A
  [`glass_theme()`](https://ericrayanderson.github.io/shinyglass/reference/glass_theme.md)
  (or other
  [`bslib::bs_theme()`](https://rstudio.github.io/bslib/reference/bs_theme.html)).
  Defaults to
  [`glass_theme()`](https://ericrayanderson.github.io/shinyglass/reference/glass_theme.md).

## Value

A list of
[`htmltools::htmlDependency()`](https://rstudio.github.io/htmltools/reference/htmlDependency.html)
objects (Bootstrap 5, the compiled glass rules, the preset head script,
and `shiny-glass.js`).

## Details

[`glass_page_react()`](https://ericrayanderson.github.io/shinyglass/reference/glass_page_react.md)
is the easier entry for
[`shinyreact::page_react()`](https://posit-dev.github.io/shinyreact/r/reference/page_react.html).

## See also

[`glass_page_react()`](https://ericrayanderson.github.io/shinyglass/reference/glass_page_react.md),
[`glass_theme()`](https://ericrayanderson.github.io/shinyglass/reference/glass_theme.md)

## Examples

``` r
deps <- glass_theme_dependencies(glass_theme(preset = "dark"))
```
