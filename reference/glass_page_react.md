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

`glass_page_react()` is that call, plus
[`glass_react_dependency()`](https://ericrayanderson.github.io/shinyglass/reference/glass_react_dependency.md).
The React client still owns the DOM. Build it from `GlassPage`,
`GlassSidebar`, `GlassSurface` / `GlassCard`, and `GlassButton` on
`window.shinyglass`. `useGlassTheme()` tracks the live mode (`light` /
`dark` / `auto`), the resolved preset, scene, material, and intensity,
and its setters call `window.shinyglass.setPreset()` and the other
existing mutators. Wallpaper, type, and `--glass-*` tokens apply to the
document. Those component classes are what pick up Liquid Glass. Do not
set panel or text colors in the client's own CSS.

Shadow roots do not see document class rules. `--glass-*` custom
properties inherit. Call `window.shinyglass.adoptShadow(shadowRoot)`
from the component that created the root to inject a `.glass-surface`
rule.

For
[`shinyreact::page_react_html()`](https://posit-dev.github.io/shinyreact/r/reference/page_react_html.html),
pass
[`glass_theme_dependencies()`](https://ericrayanderson.github.io/shinyglass/reference/glass_theme_dependencies.md)
as `extra_deps`. That helper does not need shinyreact. It includes the
React module.

## See also

[`glass_theme()`](https://ericrayanderson.github.io/shinyglass/reference/glass_theme.md),
[`glass_theme_dependencies()`](https://ericrayanderson.github.io/shinyglass/reference/glass_theme_dependencies.md),
[`glass_react_dependency()`](https://ericrayanderson.github.io/shinyglass/reference/glass_react_dependency.md)

## Examples

``` r
if (interactive() && requireNamespace("shinyreact", quietly = TRUE)) {
  # App directory must contain www/ui.js. See the shipped example:
  # system.file("examples/shinyreact-glass", package = "shinyglass")
  ui <- glass_page_react(theme = glass_theme(preset = "auto", scene = "tahoe"))
}
```
