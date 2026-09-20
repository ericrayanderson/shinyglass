# Override glass CSS tokens on a theme

Injects `:root { --glass-*: ... }` without forking SCSS. Accepts public
token names from
[`glass_css_tokens()`](https://ericrayanderson.github.io/shinyglass/reference/glass_css_tokens.md)
(`"blur"`), CSS names (`"--glass-blur"`), or `glass-blur`. Unknown names
that already start with `--` are passed through; others must be in the
catalog.

## Usage

``` r
glass_add_tokens(theme, tokens = list(), ...)
```

## Arguments

- theme:

  A
  [`glass_theme()`](https://ericrayanderson.github.io/shinyglass/reference/glass_theme.md)
  /
  [`bslib::bs_theme()`](https://rstudio.github.io/bslib/reference/bs_theme.html)
  object.

- tokens:

  Named list or character vector of CSS values.

- ...:

  Additional `name = value` overrides.

## Value

The theme, with an extra HTML dependency.

## Examples

``` r
th <- glass_theme()
th <- glass_add_tokens(th, list(blur = "28px", radius = "1.25rem"))
```
