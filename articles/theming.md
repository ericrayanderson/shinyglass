# Theming and light/dark

## Basics

``` r

library(shiny)
library(shinyglass)

ui <- fluidPage(
  theme = glass_theme(), # or preset = "dark" / "auto"
  titlePanel("Liquid Glass"),
  plotOutput("p")
)
```

[`glass_theme()`](https://ericrayanderson.github.io/shinyglass/reference/glass_theme.md)
returns a **bslib** theme. Pass it as `theme =` to
[`fluidPage()`](https://rdrr.io/pkg/shiny/man/fluidPage.html),
[`navbarPage()`](https://rdrr.io/pkg/shiny/man/navbarPage.html),
[`bslib::page_sidebar()`](https://rstudio.github.io/bslib/reference/page_sidebar.html),
and other page helpers that accept a bslib theme.

## Presets

| `preset` | Behavior |
|----|----|
| `"light"` | Light glass pack (default) |
| `"dark"` | Dark glass pack |
| `"auto"` | Follows `prefers-color-scheme`; updates when the OS theme changes |

Light and dark surface tokens ship as dual CSS custom-property packs on
`[data-glass-preset]`. Switching preset updates
`document.documentElement.dataset.glassPreset` — no Sass recompile and
no full page reload.

## Runtime updates from the server

``` r

ui <- fluidPage(
  theme = glass_theme(preset = "auto"),
  glass_theme_toggle(selected = "auto"),
  selectInput("accent", "Accent", c(
    Blue = "#007AFF", Purple = "#AF52DE", Orange = "#FF9500"
  ))
)

server <- function(input, output, session) {
  observe_glass_theme_toggle(input, session)
  observeEvent(input$accent, {
    update_glass_theme(session, primary = input$accent)
  }, ignoreInit = TRUE)
}
```

[`update_glass_theme()`](https://ericrayanderson.github.io/shinyglass/reference/update_glass_theme.md)
accepts:

| Argument  | Effect                                            |
|-----------|---------------------------------------------------|
| `preset`  | `"light"` / `"dark"` / `"auto"`                   |
| `tint`    | Content-aware ambient color from plots/images     |
| `primary` | Live accent via CSS variables (`--bs-primary`, …) |

`primary` updates Bootstrap accent CSS variables so buttons, checked
controls, and other accent surfaces follow without a reload. A few
Sass-baked one-offs may still need a full reload to pick up a new color.

## Theme toggle helper

``` r

ui <- fluidPage(
  theme = glass_theme(preset = "auto"),
  glass_theme_toggle(),           # Light / Dark / Auto buttons
  # ...
)

server <- function(input, output, session) {
  observe_glass_theme_toggle(input, session)
}
```

Buttons call `window.shinyglass.setPreset()` immediately and also fire
Shiny inputs (`glass_toggle_light`, …) so the server can stay in sync.

## Behavior knobs

``` r

glass_theme(
  preset = "auto",
  primary = "#AF52DE",
  blur = 36,
  saturation = 200,
  radius = "1.5rem",
  material = "regular", # or "clear" over media-rich content
  intensity = 0.45,     # 0 Ultra Clear → 1 Tinted (iOS 27)
  tint = TRUE,      # sample plot/image colors into glass surfaces
  specular = TRUE,  # pointer specular highlight
  nav_morph = TRUE  # compact navbar while scrolling down
)
```

`material = "regular"` is the adaptive Tahoe-style fill (default). Use
`"clear"` when chrome sits over rich media and labels stay bold.

Use \[glass_intensity_slider()\] for a live Ultra Clear → Tinted control
(same idea as iOS 27 Settings → Appearance → Liquid Glass):

``` r

glass_intensity_slider("glass_intensity", value = 0.45)
```

All three JS behaviors default to `TRUE` (same as 0.1.x). They respect
`prefers-reduced-motion: reduce` where relevant. Advanced escape hatch:
`window.__shinyglassDisableTint = true` still disables tint.

## CSS variables (migration from 0.1.x)

**Breaking in 0.2.0:** light/dark surfaces are dual CSS packs, not a
Bootswatch `darkly` rebuild. Prefer CSS custom properties over Sass
`$glass-*` tokens when customizing:

``` css
:root {
  /* shared knobs also set by glass_theme(blur=..., radius=...) */
  --glass-blur: 36px;
  --glass-radius: 1.25rem;
  --bs-primary: #007AFF;       /* also updated by update_glass_theme(primary=) */
  --glass-primary: #007AFF;
}

:root[data-glass-preset="dark"] {
  /* override a dark-pack value if needed */
  --glass-bg: rgba(255, 255, 255, 0.1);
}
```

Apps that overrode Sass-only `$glass-*` tokens should target `--glass-*`
or `[data-glass-preset="dark"]` instead.

## Client helpers

``` js
window.shinyglass.setPreset("dark"); // or "light" / "auto"
window.shinyglass.getPreset();       // resolved "light" | "dark"
window.shinyglass.getMode();         // requested mode incl. "auto"
window.shinyglass.setTint(false);
window.shinyglass.setPrimary("#AF52DE");
window.shinyglass.getPrimary();
```

## Teal

``` r

options(teal.bs_theme = glass_theme(preset = "auto"))
# then teal::init(...) as usual
```

## Reduced motion

When the user prefers reduced motion (`prefers-reduced-motion: reduce`):

- Navbar morph transforms are disabled (JS + CSS)
- Pointer specular tracking is skipped
- Content tint sampling is skipped
- Decorative transitions on cards/inputs/nav are removed

This is automatic — no app code required.

## Active-on-accent contrast

Bootstrap’s `color-contrast()` often picks **black** ink for system blue
`#007AFF`.
[`glass_theme()`](https://ericrayanderson.github.io/shinyglass/reference/glass_theme.md)
forces light ink on primary fills so checked checkboxes, radios,
switches, and active pagination stay readable.
