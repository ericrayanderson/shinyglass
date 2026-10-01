# Liquid Glass page for a shinyreact client

[`shinyreact::page_react()`](https://posit-dev.github.io/shinyreact/r/reference/page_react.html)
emits no body HTML and, unless you pass a `theme`, serves **no
Bootstrap**.
[`glass_theme()`](https://ericrayanderson.github.io/shinyglass/reference/glass_theme.md)
is a
[`bslib::bs_theme()`](https://rstudio.github.io/bslib/reference/bs_theme.html),
so the supported call is `page_react(theme = glass_theme())`. Passing
the theme as an unnamed argument does not set that parameter: shinyreact
then suppresses the Bootstrap dependency, which is also where the
compiled glass CSS lives, and the page keeps the JS without the look.

## Usage

``` r
glass_page_react(..., theme = NULL)
```

## Arguments

- ...:

  Passed to
  [`shinyreact::page_react()`](https://posit-dev.github.io/shinyreact/r/reference/page_react.html)
  (`src_dir`, `title`, `lang`, and so on). Do not pass `theme` here.

- theme:

  A
  [`glass_theme()`](https://ericrayanderson.github.io/shinyglass/reference/glass_theme.md)
  (or other
  [`bslib::bs_theme()`](https://rstudio.github.io/bslib/reference/bs_theme.html)).
  Defaults to
  [`glass_theme()`](https://ericrayanderson.github.io/shinyglass/reference/glass_theme.md).

## Value

UI suitable for `shinyApp(ui = ...)`.

## Details

`glass_page_react()` is that call. The React client still owns the DOM.
Wallpaper, type, and `--glass-*` tokens apply to the document. Bootstrap
classes (`.card`, `.btn`, `.form-control`, `.shiny-plot-output`) and the
opt-in `.glass-surface` panel pick up Liquid Glass. Hard-coded colors in
the client's own CSS do not track light/dark; prefer
`var(--glass-body-color)` and `.glass-surface`.

Shadow roots do not see document class rules. `--glass-*` custom
properties inherit. Call `window.shinyglass.adoptShadow(shadowRoot)`
from the component that created the root to inject a `.glass-surface`
rule.

For
[`shinyreact::page_react_html()`](https://posit-dev.github.io/shinyreact/r/reference/page_react_html.html),
pass
[`glass_theme_dependencies()`](https://ericrayanderson.github.io/shinyglass/reference/glass_theme_dependencies.md)
as `extra_deps`. That helper does not need shinyreact.

## See also

[`glass_theme()`](https://ericrayanderson.github.io/shinyglass/reference/glass_theme.md),
[`glass_theme_dependencies()`](https://ericrayanderson.github.io/shinyglass/reference/glass_theme_dependencies.md)

## Examples

``` r
if (interactive() && requireNamespace("shinyreact", quietly = TRUE)) {
  # App directory must contain www/ui.js. See the shipped example:
  # system.file("examples/shinyreact-glass", package = "shinyglass")
  ui <- glass_page_react(theme = glass_theme(preset = "auto", scene = "tahoe"))
}
```
