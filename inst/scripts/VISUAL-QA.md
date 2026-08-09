# shinyglass visual QA

Catch theme regressions where Bootstrap / DT / selectize paint the **visible**
node and glass styles only hit a wrapper (or dark-mode packs miss a surface).

## Automated audit (do this first)

From the package root:

```r
# full matrix (demo + dashboard + inputs × light + dark)
Rscript inst/scripts/audit-glass-contrast.R

# dark-only dashboard (fast DT pagination check)
Rscript inst/scripts/audit-glass-contrast.R --apps=dashboard --presets=dark

# write machine-readable report
Rscript inst/scripts/audit-glass-contrast.R --json=/tmp/glass-audit.json
```

Exit code **1** on any `FAIL`. Warnings (contrast between 3:1 and 4.5:1) do not
fail the run.

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

## Dual-theme matrix (minimum before release)

| App | light | dark | Interaction |
|-----|:-----:|:----:|-------------|
| `demo-app` | ✓ | ✓ | Theme toggle Light → Dark → Auto |
| `inputs-gallery` | ✓ | ✓ | Open selectize dropdown; move slider |
| `bslib-dashboard` | ✓ | ✓ | DT page **2**; confirm page **1** active chip |
| `plotly-gt-demo` | ✓ | ✓ | Modebar icons readable; gt header/rows (if plotly+gt installed) |
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
3. [ ] Spot-check inputs-gallery selectize open + slider chip  
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
- tabs, dropdown menus, modals, notifications  
- value boxes / `.bg-*` solid fills  
- sidebar open vs collapsed gutters  
- reactable / leaflet / shinyWidgets / bs4Dash when touching those demos  
