# shinyglass visual QA

Catch theme regressions where Bootstrap / DT / selectize paint the **visible**
node and glass styles only hit a wrapper (or dark-mode packs miss a surface).

## Automated audit (do this first)

From the package root:

```r
# full matrix (demo + dashboard + inputs + plotly_gt × light + dark)
Rscript inst/scripts/audit-glass-contrast.R

# dark-only dashboard (fast DT pagination check)
Rscript inst/scripts/audit-glass-contrast.R --apps=dashboard --presets=dark

# write machine-readable report (also refresh the committed baseline)
Rscript inst/scripts/audit-glass-contrast.R --json=inst/scripts/audit-baseline.json
```

CI runs this on every PR/push via `.github/workflows/visual-qa.yaml`.

Committed baseline: `inst/scripts/audit-baseline.json` (refresh after intentional
theme changes). Exit code **1** on any `FAIL`. Warnings (contrast between 3:1
and 4.5:1, e.g. white on `#007AFF` ≈ 4.02:1) do not fail the run.

What it checks:

| Code | Meaning |
|------|---------|
| `low-contrast` | Text vs background &lt; `--min-contrast` (default 3) |
| `solid-black-chip` | Opaque near-black control fill in **dark** mode |
| `bootstrap-light-grey` | Bootstrap `#e9ecef`-like fill in **dark** mode |
| `dark-ink-on-accent` | Near-black text on solid brand blue |
| `active-page-dark-ink` | Active DT/Bootstrap page chip not light ink |
| `dt-pagination-structure` | DT `.page-link` still solid black (wrapper-only styles) |
| static `scss-*` | Source rules present for pagination / value-box / checks |

Optional app: `--apps=...,shinywidgets` if `shinyWidgets` is installed.

Default matrix now includes `chrome` (`chrome-kitchen-sink.R`) and opens
datepicker / navbar menu / notifications / accordion / tooltip / popover /
server modal, plus intensity 0 and 1. Screenshot a pass with
`--screenshot-dir=visual-test-output/chrome`.

## Dual-theme matrix (minimum before release)

| App | light | dark | Interaction |
|-----|:-----:|:----:|-------------|
| `demo-app` | ✓ | ✓ | Theme toggle Light → Dark → Auto |
| `inputs-gallery` | ✓ | ✓ | Open selectize dropdown; open datepicker; Show modal |
| `bslib-dashboard` | ✓ | ✓ | DT page **2**; confirm page **1** active chip |
| `plotly-gt-demo` | ✓ | ✓ | Modebar icons readable; gt header/rows (if plotly+gt installed) |
| `chrome-kitchen-sink` | ✓ | ✓ | Datepicker, all 4 notification types, `showModal()`, navbar menu, accordion, tooltip/popover |
| `shinywidgets-gallery-glass` | ✓ | ✓ | Flip a switch / open a picker (if installed) |
| `shinydashboardPlus-glass-demo` | ✓ | ✓ | Controlbar + notification dropdown (if Plus installed) |

```r
Sys.setenv(SHINYGLASS_PRESET = "dark")  # or "light"
shiny::runApp("inst/examples/bslib-dashboard.R")
```

## Human README / promo checklist (2 minutes)

For **each** of light + dark screenshots:

1. **Pagination** — page 1 active (accent + light ink); 2–N readable; ellipsis not a light-grey brick; Previous/Next not solid black.
2. **Slider value chip** — readable ink on accent.
3. **Primary button** — light label on brand fill.
4. **Value boxes** — title + big number readable on every theme color shown.
5. **Selectize multi tags** — chip text readable; open dropdown is opaque.
6. **Active tab** — label contrast OK.
7. **Disabled control** — e.g. Previous on page 1; muted glass, not Bootstrap light grey in dark.
8. **Layout honesty** — if the app has a sidebar, show it (or truly collapse). Do not leave an empty left reserve under a full-width navbar.

## Failure pattern to remember

```text
Third-party markup:  <li.wrapper><a.visible>2</a></li>
Wrong:  style .wrapper only  →  Bootstrap paints .visible (black/grey chips)
Right:  style the visible surface (.page-link, .selectize-input, …)
```

Always verify **default · hover · focus · active · disabled** in **light and dark**.

## Broader visual harnesses

Existing screenshot runners (manual review of PNGs):

- `inst/scripts/visual-test-examples.R`
- `inst/scripts/visual-test-tier-ab.R` (SuperZIP, shinyWidgets, bs4Dash)
- `inst/scripts/visual-test-shiny-gallery.R`
- `inst/scripts/visual-test-teal.R`
- `inst/scripts/capture-demo-screenshots.R` (README figures)

## Definition of done (theme / demo change)

Before merge or shinyapps redeploy:

1. [ ] `Rscript inst/scripts/audit-glass-contrast.R` exits 0  
2. [ ] Spot-check dashboard DT pagination in dark  
3. [ ] Spot-check inputs-gallery selectize open + slider chip + datepicker  
3b. [ ] Spot-check chrome-kitchen-sink in dark: calendar, notifications, modal ×, navbar **More** menu, accordion
4. [ ] Recapture README figures if UI chrome changed  
   (`Rscript inst/scripts/capture-demo-screenshots.R` — keep dashboard sidebar visible)  
5. [ ] `Rscript -e 'devtools::test()'` (or `testthat::test_local()`)  
6. [ ] Redeploy demos if examples or package CSS changed  
   (`Rscript inst/scripts/deploy-shinyapps-demos.R`)

## High-risk surfaces (quick inventory)

- DT: pagination, length select, filter, sort headers  
- selectize: input, multi tags, dropdown, remove ×  
- ion.rangeSlider: track, handle, value chips  
- buttons: primary / outline / disabled / btn-check  
- checks / radios / switches (checked mark & knob)  
- tabs, dropdown menus, modals, notifications (all four types)  
- bootstrap-datepicker popup; `.btn-close`; file Browse chip  
- bslib accordion / tooltip / popover / toast; `page_navbar` + `nav_menu` 
- value boxes / `.bg-*` solid fills  
- sidebar open vs collapsed gutters  
- reactable / leaflet / shinyWidgets / bs4Dash when touching those demos  

## Runtime responsiveness regressions

```sh
cd inst/scripts/browser
npm ci
npx playwright install chromium
npx playwright test
```

These Chromium tests load the actual `inst/js/shiny-glass.js` with jQuery and a
recording Shiny transport. They cover initial Auto/OS changes, keyboard preset
and intensity controls, duplicate message delivery, dynamic sliders, reconnect
hook installation, and idle widget/media work after a burst of text updates.
They do not measure R execution time, actual WebSocket reconnects, or GPU paint
cost. The existing R tests and demo contrast audit remain separate CI gates.

For reports of sluggishness, compare the same app/data/browser with plain bslib,
then glass with `tint = FALSE, specular = FALSE, nav_morph = FALSE,
ambient_motion = FALSE`, then default
glass. Record a browser Performance trace during the same reactive interaction.
Compare scripting, style/layout, paint/compositing, and interaction latency;
use Shiny profiling separately for server time. Repeat with representative
charts/tables and on the affected device. Avoid claiming a speedup from unit
checks alone: blur and layered surfaces can still be costly to paint.

### Real Shiny integration and benchmark

With R, the package dependencies, `pkgload`, and `jsonlite` installed, run from
`inst/scripts/browser`:

```sh
RUN_SHINY_TESTS=1 npx playwright test shiny.spec.js
RUN_SHINY_TESTS=1 RUN_BENCHMARK=1 npx playwright test benchmark.spec.js
```

The fixture checks module inputs, server-driven theme updates, inserted sliders,
actual WebSocket reconnection, and plot redraw counts. It also tests live OS
preferences and independent ambient animation. CI runs both suites and uploads
`test-results/benchmark.json` with the test artifacts.

The benchmark rotates three variants across three rounds, measuring ten warmed-up
interactions per variant per round with identical deterministic data, two plots,
and a table. It reports driver-observed response latency, browser CPU/layout/paint
work, long tasks, and R plot-expression computation separately. Headless Chromium
paint events do not measure GPU compositing or predict performance on every
device. Treat these as reproducible observations, not a universal speedup claim.

### Ordinary-text accessibility audit

```sh
Rscript inst/scripts/audit-glass-contrast.R --text-aa
```

Strict mode requires 4.5:1 for ordinary text and 3:1 for large text (24px, or
18.67px bold). Hidden and disabled controls are excluded. Without this flag the
legacy 3:1 failure floor remains, with warnings for ordinary text below 4.5:1.
The audit composites computed ancestor colors; gradients, backdrop filtering,
images, and ancestor opacity require visual review. A passing report is not a
claim of full WCAG conformance. In particular, white ordinary text on the default
system-blue accent is about 4.02:1 and needs a darker accent for 4.5:1.
