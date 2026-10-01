# HTML dependency for the shinyreact components

[`shinyreact::page_react()`](https://posit-dev.github.io/shinyreact/r/reference/page_react.html)
serves `www/ui.js` as an ES module and exposes one React on
`window.shinyreact`. `glass_react_dependency()` is the matching module,
`inst/js/shinyglass-react.js`. It registers `useGlassTheme`,
`GlassPage`, `GlassMain`, `GlassSidebar`, `GlassSurface`, `GlassCard`,
`GlassStack`, `GlassButton`, `GlassTitle`, `GlassMuted`, and
`GlassRange` on `window.shinyglass` and as named exports.

## Usage

``` r
glass_react_dependency()
```

## Value

An
[`htmltools::htmlDependency()`](https://rstudio.github.io/htmltools/reference/htmlDependency.html).

## Details

The module does not import React and does not bundle a second copy.
Components call `window.shinyreact.React` when they render. Styling is
class names (`.glass-page`, `.glass-sidebar`, `.glass-surface`,
`.glass-button-primary`, and so on). Colors, blur, and radius come from
the `--glass-*` custom properties already defined by
[`glass_theme()`](https://ericrayanderson.github.io/shinyglass/reference/glass_theme.md),
so the React pieces stay in sync with the R and Python themes.

[`glass_page_react()`](https://ericrayanderson.github.io/shinyglass/reference/glass_page_react.md)
bundles this dependency into the theme, which
[`shiny::bootstrapPage()`](https://rdrr.io/pkg/shiny/man/bootstrapPage.html)
emits before the app module. `www/ui.js` can read `window.shinyglass` at
top level.
[`glass_theme_dependencies()`](https://ericrayanderson.github.io/shinyglass/reference/glass_theme_dependencies.md)
appends the same dependency for
[`shinyreact::page_react_html()`](https://posit-dev.github.io/shinyreact/r/reference/page_react_html.html).
A plain
[`glass_theme()`](https://ericrayanderson.github.io/shinyglass/reference/glass_theme.md)
does not load the module, so classic Shiny pages are unchanged.

An npm package is intentionally not the distribution. shinyreact's
default app has no build step, and htmltools serves this file at a
versioned URL, so a hardcoded `import` in `www/ui.js` would break on
every package version. The global matches how shinyreact itself is
consumed.

## See also

[`glass_page_react()`](https://ericrayanderson.github.io/shinyglass/reference/glass_page_react.md),
[`glass_theme_dependencies()`](https://ericrayanderson.github.io/shinyglass/reference/glass_theme_dependencies.md)

## Examples

``` r
dep <- glass_react_dependency()
dep$name
#> [1] "shinyglass-react"
```
