# Ecosystem compatibility

shinyglass is a **theme layer**, not a universal skin. It targets
Bootstrap 5 / bslib surfaces first, then overlays denser dashboard
stacks where practical.

## Support matrix (as of 0.2)

| Stack | Status | Notes |
|----|----|----|
| `fluidPage` / `navbarPage` | Supported | Drop-in `theme = glass_theme()` |
| bslib `page_navbar` / `nav_menu` | Supported | See `chrome-kitchen-sink.R` |
| bslib `page_sidebar` / `layout_sidebar` | Supported | Floating glass sidebar; nested layouts stay in-flow (0.1.1+) |
| bslib cards, value boxes, navsets, accordion | Supported | Tooltip / popover / toast use the glass menu surface |
| DT | Supported | Visible `.page-link` chips (not li-only) |
| reactable | Supported | Avoids double-framing the html-output |
| **gt** | Supported | Table / heading / stripe / summary chrome |
| leaflet | Supported | Map container transparency |
| **plotly** | Good | Glass frame + modebar; set `paper_bgcolor` transparent in R for best dark |
| shinyWidgets (common inputs) | Good | Slider tooltips / noUiSlider chips |
| shinydashboard / **bs4Dash** / **shinydashboardPlus** | Overlay | Glass header/sidebar/boxes/controlbar/dropdowns; layout stays AdminLTE |
| teal | Good | Use `options(teal.bs_theme = glass_theme())` |
| **waiter** / shinybusy / loaders | Good | Blurred overlays, not solid white scrims |
| **shinyalert** / SweetAlert2 | Good | Popup uses glass menu surface |
| rhandsontable | Partial | Frame + cell ink; core grid still third-party |
| echarts4r / highcharter / apex | Partial | Host wrapper glass; chart internals set in R |
| Bootstrap 3-only apps | Limited | Theme is BS5 via bslib |

## Layout contract

- Open bslib sidebars **reserve** space in main so content is not buried
  under the floating chrome.
- Nested `layout_sidebar()` does **not** double-float.
- AdminLTE left sidebars keep fixed AdminLTE geometry; glass is visual
  overlay only.

## Examples

``` r

# overlays: datepicker, notifications, showModal, accordion, navbar menu
shiny::runApp(system.file("examples", "chrome-kitchen-sink.R", package = "shinyglass"))

# plotly + gt (+ waiter if installed)
shiny::runApp(system.file("examples", "plotly-gt-demo.R", package = "shinyglass"))

# denser AdminLTE (requires shinydashboardPlus)
shiny::runApp(system.file("examples", "shinydashboardPlus-glass-demo.R", package = "shinyglass"))
```

Dual-theme contrast audit (optional ecosystem apps skip if packages
missing):

``` r
Rscript inst/scripts/audit-glass-contrast.R --apps=demo,dashboard,inputs,plotly_gt,chrome
```

## Tips

- Prefer bslib page functions when you can — glass was designed around
  them.
- For plotly dark mode, pass transparent `paper_bgcolor` /
  `plot_bgcolor` in [`layout()`](https://rdrr.io/r/graphics/layout.html)
  (see `plotly-gt-demo.R`); CSS handles the modebar.
- For dark mode in dense AdminLTE apps, re-check value/info box contrast
  after switching preset at runtime.
- `preset = "auto"` is ideal for demos; pin `"light"` or `"dark"` for
  screenshots and tests.
