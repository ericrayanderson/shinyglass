## Submission

This is an update from 0.1.1 to 0.2.0.

### User-facing changes

* Runtime light/dark/auto theme switching without page reload (dual CSS
  variable packs on `[data-glass-preset]`).
* `update_glass_theme()` for preset, tint, primary accent, and intensity.
* `glass_theme_toggle()` / `observe_glass_theme_toggle()` helpers.
* iOS 27 Liquid Glass intensity: `glass_intensity_slider()`,
  `observe_glass_intensity()`, and `glass_theme(intensity = 0–1)`.
* Client-first theme controls: `glass_theme_toggle()`, `glass_preset_input()`,
  dual-channel `update_glass_theme()` delivery for reliable runtime switching.
* Active-on-accent contrast fix (white checks/knobs on brand primary).
* DT/selectize glass chrome fixes; plotly/gt/AdminLTE overlay CSS.
* Overlay chrome: datepicker, notifications, accordion, tooltip/popover,
  `.btn-close`, file Browse (dark pack no longer relies on Bootswatch darkly).
* Navbar brand ink matches glass body color; plotly axis titles not clipped.
* Reduced-motion support; softer plot frames; demo fixes.
* Liquid Glass material fidelity (layered surfaces, chrome vs content,
  `material = "regular"|"clear"`, updated blur/radius defaults).
* Dark-mode nav tab contrast (WCAG UI 3:1 on glass).

### Breaking (documented in NEWS + vignette)

* Dark mode no longer uses Bootswatch `darkly`; it uses the glass dark CSS pack.
* Prefer CSS `--glass-*` variables over Sass-only `$glass-*` overrides.

## Test environments

* local macOS, R 4.6.x
* GitHub Actions: ubuntu (release, devel), macOS (release), windows (release)
* R CMD check --as-cran on the source tarball
* visual-qa workflow: testthat + dual-theme contrast audit

## R CMD check results

Local `R CMD check shinyglass_0.2.0.tar.gz --as-cran` (2026-08-11):

**0 errors | 0 warnings | 0 notes**

Also clean: `urlchecker::url_check()`, `spelling::spell_check_package()`,
`devtools::test()` (125 tests). Overlay chrome contrast audit
(datepicker, notifications, accordion, tooltip/popover, `showModal()`,
`page_navbar`) is 0 FAIL on light+dark.

If CRAN's incoming check later reports a "days since last update" note
for a short interval after 0.1.1, that is expected and harmless.
Re-run check on a fresh tarball immediately before submit.

## Downstream dependencies

None known.

## Notes for this submission window

* CRAN submissions were closed ~2026-08-05 through ~2026-08-19 (team vacation).
* Large README marketing assets (intensity GIFs/PNGs, dashboard screenshots,
  etc.) are excluded via `.Rbuildignore` and stay on GitHub only.
* Live demos: shinyglass-demo, -dashboard, -inputs, -plotly-gt, -olympics
  (free-tier 5-app limit; dedicated intensity app not deployed).
