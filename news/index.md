# Changelog

## shinyglass 0.2.0

### Breaking changes

- Light and dark glass surfaces are now dual **CSS custom-property
  packs** on `[data-glass-preset]`. Switching preset no longer requires
  recompiling Sass or reloading the page. Apps that overrode Sass-only
  `$glass-*` tokens should target `--glass-*` CSS variables (or
  `[data-glass-preset="dark"]`) instead.
- [`glass_theme()`](https://ericrayanderson.github.io/shinyglass/reference/glass_theme.md)
  always builds on the Bootstrap 5 base theme (not Bootswatch `darkly`
  for dark). Dark appearance comes from the CSS variable pack so
  light↔︎dark can toggle live. Visuals should match 0.1.x closely; if you
  relied on darkly-specific chrome outside glass surfaces, re-check dark
  mode.
- Private escape hatch `window.__shinyglassDisableTint` still works, but
  the supported API is `glass_theme(tint = FALSE)` /
  `update_glass_theme(tint = …)`.

### New features

- \[glass_intensity_slider()\] / \[observe_glass_intensity()\] — iOS
  27-style **Ultra Clear → Tinted** control. `glass_theme(intensity = )`
  sets the starting value (`0`–`1`, default `0.45`);
  \[update_glass_theme()\] and `window.shinyglass.setIntensity()` update
  it live.

- Demo app `intensity-slider-demo.R` and shinyapps app
  **shinyglass-intensity**; dashboard demo ships the intensity slider in
  the sidebar.

- iOS 27 material polish: stronger darkened edges, brighter specular
  highlights, intensity-scaled fill/blur for clearer layer separation
  and readability.

- Dark-mode nav tab ink keeps WCAG UI 3:1 on glass (inactive tabs).

- Closer iOS 27 Liquid Glass: defined borders (not shadow-only),
  chromatic edge refraction cues, lighter dark-mode glass, thicker
  elevated chrome, ambient specular drift + pointer override, stronger
  diffusion blur defaults (`blur = 36`, `saturation = 200`).

- Runtime light/dark switching via
  `document.documentElement.dataset.glassPreset` without a full reload.

- `glass_theme(preset = "auto")` follows `prefers-color-scheme` and
  updates when the OS theme changes.

- \[update_glass_theme()\] to change `preset`, `tint`, and **`primary`**
  (live accent via `--glass-accent` / `--bs-primary`) from the server.
  Recolors primary buttons, Shiny
  [`checkboxInput()`](https://rdrr.io/pkg/shiny/man/checkboxInput.html)
  / radios / switches, ion.rangeSlider bars, value chips, and active
  nav/list items without a Sass recompile.

- \[glass_theme_toggle()\] / \[observe_glass_theme_toggle()\] drop-in
  Light / Dark / Auto buttons.

- Behavior knobs on \[glass_theme()\]: `tint`, `specular`, and
  `nav_morph` (all default `TRUE`, matching 0.1.x JS behavior).

- Client helpers: `window.shinyglass.setPreset()` / `.getPreset()` /
  `.setTint()` / `.setPrimary()` / `.getPrimary()`.

### Improvements

- Liquid Glass material fidelity (Tahoe / iOS 26 inspired): multi-layer
  surfaces (illumination fill, dual-edge rim/lip, ambient + pointer
  specular), chrome vs content hierarchy (less glass-on-glass), softer
  wallpaper orbs, larger concentric radii, capsule-leaning controls.

- New `glass_theme(material = "regular"|"clear")`. Clear is more
  transparent for media-rich layouts. Defaults: `blur = 32`,
  `radius = "1.5rem"`, `saturation = 190`.

- DataTables / Bootstrap pagination chips: style the visible
  `.page-link` surface (DT uses `<li.paginate_button><a.page-link>`).
  Fixes solid black page numbers and light-grey ellipsis chips in dark
  mode on the dashboard demo / README screenshots.

- Visual QA harness: `inst/scripts/audit-glass-contrast.R` (+ `.js`)
  runs a dual-theme computed-style audit (low contrast, solid-black
  chips, Bootstrap light greys in dark, dark ink on accent, DT
  pagination structure) across demo / dashboard / inputs-gallery.
  Checklist and definition of done in `inst/scripts/VISUAL-QA.md`.

- Selectize fields: force body/menu ink on inputs and multi-select tags
  (selectize default near-black item text failed dark mode); opaque
  `--glass-menu-bg` fills in dark; dropdown options use menu colors.

- Ecosystem chrome: **plotly** modebar + frame, **gt** tables,
  **waiter** / shinybusy overlays, **shinyalert**/SweetAlert2 popups,
  denser **shinydashboardPlus** controlbar/dropdowns/user menu, light
  **rhandsontable** / echarts/highcharter hosts. Examples:
  `plotly-gt-demo.R`, `shinydashboardPlus-glass-demo.R`.

- Live demo
  [shinyglass-plotly-gt](https://ericrayanderson.shinyapps.io/shinyglass-plotly-gt/);
  README light/dark screenshots for plotly+gt.

- CI workflow `visual-qa` (testthat + dual-theme contrast audit) and
  committed `inst/scripts/audit-baseline.json`.

- Navbar brand / page title ink uses `--glass-body-color` (no more white
  brand on light glass). Plotly hosts no longer clip x-axis titles.

- Active-on-accent contrast: lower Bootstrap `$min-contrast-ratio` to
  **3** so `color-contrast()` picks white on brand blues/purples (white
  on `#007AFF` is ~4.02:1 and failed the old 4.5 gate). Solid `.bg-*` /
  `.text-bg-*` fills (including `bslib::value_box(theme=)`) get
  luminance-based ink via `glass-on()` / `--glass-on-*` — not body color
  on solid primary. Safety nets remain for checks, radios, switches,
  pagination, and list-group active.

- Accent rules target Shiny markup (`.shiny-input-checkbox`) as well as
  Bootstrap `.form-check-input`.

- Plot / image outputs get a softer glass frame (lighter nesting inside
  cards).

- `prefers-reduced-motion: reduce` disables nav morph, specular, tint
  sampling, and decorative transitions (JS + CSS).

- Demo and bslib dashboard examples: theme toggle helper; dashboard
  accent select calls `update_glass_theme(primary = …)`.

- Vignettes cover migration, primary updates, toggle helper, and reduced
  motion.

- Unit tests cover dual CSS packs, head script knobs, active-color vars,
  and
  [`update_glass_theme()`](https://ericrayanderson.github.io/shinyglass/reference/update_glass_theme.md)
  messaging.

### Bug fixes

- Demo app “Show smooth” draws a density curve (checkbox was previously
  ignored).
- Theme message routing hardened for hosts that rewrite Shiny custom
  messages (e.g. shinyapps.io).
- `shiny-glass.js` no longer crashes when the script loads in `<head>`
  before `document.body` exists.

## shinyglass 0.1.1

CRAN release: 2026-08-02

- Fix:
  [`bslib::sidebar()`](https://rstudio.github.io/bslib/reference/sidebar.html)
  / `page_sidebar()` layout no longer collapses to a full-width stack.
  Glass floating-sidebar rules now win over bslib’s later
  `position`/`width` cascade, and open sidebars reserve space in main so
  value boxes and cards stay fully visible beside the chrome (not under
  it).
- Fix: nested `layout_sidebar()` no longer double-floats. Inner sidebars
  keep glass styling but use bslib’s in-flow grid so content is not
  pushed into a large empty gutter beside a second absolute panel.
- Improve: AdminLTE chrome (classic `shinydashboard` and `bs4Dash`) gets
  stronger glass overlay — translucent header/sidebar, soft-tinted
  value/info boxes, and clearer menu active states — without breaking
  AdminLTE layout.

## shinyglass 0.1.0

CRAN release: 2026-07-28

- Initial release.
- [`glass_theme()`](https://ericrayanderson.github.io/shinyglass/reference/glass_theme.md)
  returns a [bslib](https://rstudio.github.io/bslib/) theme with Liquid
  Glass styling for [shiny](https://shiny.posit.co/) apps: translucent
  surfaces, backdrop blur, soft depth, and system typography.
- Light and dark presets, with options for accent color, blur,
  saturation, and corner radius.
- Works with
  [`fluidPage()`](https://rdrr.io/pkg/shiny/man/fluidPage.html),
  [`navbarPage()`](https://rdrr.io/pkg/shiny/man/navbarPage.html),
  [`bslib::page_sidebar()`](https://rstudio.github.io/bslib/reference/page_sidebar.html),
  and other page functions that accept a bslib theme. Pass the theme via
  `theme = glass_theme()`, or for
  [teal](https://insightsengineering.github.io/teal/) apps via
  `options(teal.bs_theme = glass_theme())`.
- Styles common Bootstrap and Shiny surfaces (cards, navbars, sidebars,
  inputs, tables, plots, modals) and holds up on denser UIs such as
  leaflet maps, DT, shinyWidgets, bs4Dash, and teal filter panels.
