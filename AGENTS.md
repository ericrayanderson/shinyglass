# shinyglass agent notes

shinyglass adds Liquid Glass themes to Shiny apps. The look matches Apple iOS 27 as far as a browser can: translucent surfaces, backdrop blur, and an intensity slider from Ultra Clear to Tinted.

This file is for AI coding assistants. Read it before editing the package. Prefer the exported functions and the vignettes over guessing CSS.

## Apply it to an existing app

Pass `glass_theme()` as `theme` on a bslib page, then register the controls in the server.

```r
library(shiny)
library(bslib)
library(shinyglass)

ui <- page_sidebar(
  title = "Existing app",
  theme = glass_theme(preset = "auto", intensity = 0.5),
  sidebar = sidebar(
    glass_theme_toggle(),
    glass_intensity_slider()
  ),
  "Main column"
)

server <- function(input, output, session) {
  observe_glass(input, session)
}

shinyApp(ui, server)
```

`page_fluid()`, `page_navbar()`, `page_fillable()`, and `navbarPage()` take the same `theme` argument. `fluidPage(theme = glass_theme())` works too.

For a new app, `glass_page()` wraps `fluidPage()`, turns persistence on, and includes the Light / Dark / Auto toggle, the intensity slider, and accent wells. Still call `observe_glass()` in the server.

```r
ui <- glass_page(
  title = "Hello, glass",
  sliderInput("n", "Bars", 5, 30, 15),
  plotOutput("plot")
)
```

## Arguments that matter

`glass_theme()` defaults:

| Argument | Default | Allowed |
| --- | --- | --- |
| `preset` | `"light"` on `glass_theme()`, `"auto"` on `glass_page()` | `"light"`, `"dark"`, `"auto"` |
| `intensity` | `0.5` | numeric from `0` (Ultra Clear) to `1` (Tinted) |
| `primary` | `"#007AFF"` | hex or `rgb()` color |
| `material` | `"regular"` | `"regular"`. `"clear"` is deprecated |
| `plot_surface` | `"clear"` | `"clear"`, `"opaque"` |
| `scene` | `"default"` (`"tahoe"` on `glass_page()`) | `names(glass_scenes())` |
| `persist` | `FALSE` (`TRUE` on `glass_page()`) | logical |
| `refraction`, `morph`, `press`, `scroll_edge`, `minimize_tabs` | `TRUE` | logical |
| `icon_style` | `"clear"` | `"clear"`, `"color"`, `"all"` |
| `floating_sidebar` | `FALSE` | logical |
| `specular` | `TRUE` | logical. Highlights are static top and bottom bands |

`update_glass_theme(session, ...)` changes these in a running app. `NULL` means leave that setting alone.

When the user picks Auto, `input$glass_preset` stays `"auto"`. Plot ink must use `glass_resolved_preset(input)`, which is `"light"` or `"dark"`.

## 0.5.0 migration

`vignette("migrating")` is the full note. The short version:

- Default intensity moved from `0.45` to `0.5`.
- `material = "clear"` is deprecated. It warns and, when `intensity` is omitted, maps to `0.12`. Pass `intensity` instead. The same mapping applies to `update_glass_theme(material = "clear")` and `setMaterial("clear")`.
- Specular highlights no longer follow the pointer. `specular = FALSE` hides them.
- Chromium refracts the backdrop (`refraction = TRUE`). Safari and Firefox keep blur and tint.
- `morph`, `press`, `scroll_edge`, `minimize_tabs`, and `icon_style` are on by default. `floating_sidebar` stays off.
- Existing page functions and click targets keep working. You do not need a new page function.

## Accessibility

The page sets `data-glass-reduced-transparency`, `data-glass-contrast`, and `data-glass-forced-colors` on `<html>`.

- Reduce Transparency uses opaque fills and no backdrop blur, including the refraction lens.
- Increase Contrast and forced colors override the inline `--glass-*` values.
- Reduced motion skips the press spring and the tab-bar shrink.
- Light-mode icon ink is `#1d1d1f`, so a white glyph is not used on light glass. Dark mode uses near-white.
- Body text targets 4.5:1. Large chrome targets 3:1. User photos are blurred and washed.

`glass_flatten(session, TRUE)` or `?glass_flatten=1` removes blur for screenshots, chromote, and PDF. Print CSS does this on its own.

## shinychat, offcanvas, and React

shinychat `page_chat(theme = glass_theme())` picks up the glass packs, including the composer and the history sidebar. bslib `offcanvas()` is styled the same way. The worked example is `inst/examples/shinychat-glass`.

shinyreact must receive the theme by name. An unnamed theme drops Bootstrap and the compiled CSS.

```r
ui <- glass_page_react(theme = glass_theme(preset = "auto"))
```

`shinyreact::page_react_html()` has no `theme` argument. Pass `extra_deps = glass_theme_dependencies()`. The React components (`GlassPage`, `GlassSidebar`, `GlassCard`, `GlassButton`, `GlassIntensitySlider`, `useGlassTheme`) live on `window.shinyglass`. See `vignette("shinyreact")` and `vignette("shinychat")`.

## Pitfalls

- Do not set panel or text colors in app CSS. Use `--glass-*` tokens from `glass_css_tokens()` or `glass_theme(tokens = list(blur = "28px"))`.
- Plot and table hosts are transparent by default. Pass `bg = "transparent"` into `renderPlot()`, or set `plot_surface = "opaque"` when the wallpaper makes the graphic hard to read.
- `observe_glass()` only watches the default ids (`glass_toggle`, `glass_intensity`, `glass_accent`). Custom ids need the matching `observe_glass_*()` helper.
- `glass_theme(persist = FALSE)` is the default. `glass_page(persist = TRUE)` remembers preset, intensity, accent, and scene for that path.
- Keep `inst/scss/glass.scss` and `inst/js/glass-ios27.js` byte-identical to `python/src/shinyglass/static/`. Copy with `cp` after editing the `inst/` file.
- Do not add a second React bundle. The module uses `window.shinyreact.React`.

## Tests

From the repo root, with the package loadable:

```r
pkgload::load_all(".", quiet = TRUE)
testthat::test_local()
```

Contrast audit (needs Chrome):

```sh
Rscript inst/scripts/audit-glass-contrast.R
Rscript inst/scripts/audit-glass-contrast.R --apps=dashboard --presets=dark
```

Playwright, from `inst/scripts/browser` after `npm ci` and `npx playwright install chromium`:

```sh
RUN_COMPAT_TESTS=1 npx playwright test compat.spec.js
RUN_SHINY_TESTS=1 npx playwright test shiny.spec.js
RUN_CHAT_TESTS=1 npx playwright test chat.spec.js
```

`R CMD check` must stay free of new NOTES. `urlchecker::url_check()` and `spelling::spell_check_package()` run in CI. New prose in `NEWS.md`, `README.md`, and vignettes has to pass the word list in `inst/WORDLIST`.

## Repo conventions

- Put user-visible changes in `NEWS.md` under the current version. Do not bump `Version` unless asked.
- Commit as Eric Anderson <eric.ray.anderson@gmail.com> with `git -c user.name` and `git -c user.email`. Do not change git config.
- Do not submit to CRAN unless asked.
- `AGENTS.md` is listed in `.Rbuildignore`. It is for the repo, not the installed package.
