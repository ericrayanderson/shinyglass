## Submission

This is an update from 0.2.0 (2026-08-21) to 0.3.0.

### User-facing changes

* `glass_theme(persist = TRUE)` remembers preset, intensity, accent,
  material, and scene in `localStorage`.
* `glass_page()` / `observe_glass()` one-call page with toggle, intensity
  slider, and accent wells.
* `theme_glass()`, `plotly_glass()`, `gt_theme_glass()`, and
  `glass_plot_colors()` match plots and tables to the glass pack.
* `glass_accent_input()` iOS-style color wells; named system colors.
* Wallpaper scenes (`tahoe` / `dusk` / `mesh`) and optional `wallpaper =`.
* Live `update_glass_theme()` for material, ambient motion, and scene.
* `glass_theme(ambient_motion = FALSE)`; live reduced-motion /
  reduced-transparency; forced-colors and `prefers-contrast: more`.
* Golden Gate material (90° highlight, side-edge strokes, denser
  scroll-edge chrome).
* Olympics demo: readable subtitle (no raw HTML); plot uses `theme_glass()`.

No breaking API changes from 0.2.0.

## Test environments

* GitHub Actions: ubuntu (release, devel), macOS (release), windows (release)
* `R CMD check --as-cran` (CI uses `--no-manual`; source tarball for submit)
* visual-qa: testthat + dual-theme contrast audit + Playwright runtime

## R CMD check results

**0 errors | 0 warnings | 0 notes** on local `R CMD check --as-cran`
(macOS Tahoe, R 4.6.1) and GitHub Actions (ubuntu release + devel,
macOS release, windows release). CI uses `--no-manual`; the submitted
tarball is from `R CMD build` with vignettes.

A possible incoming "days since last update" NOTE (~18 days after
0.2.0) is expected. That interval is short but the release is a real
feature set (persistence, plot helpers, accessibility, material), not
a drive-by tweak.

## Downstream dependencies

None known.

## Notes

* Large README marketing assets stay on GitHub via `.Rbuildignore`.
* Live demos: shinyglass-demo, -dashboard, -inputs, -plotly-gt, -olympics.
* Experimental Python package is not in the CRAN tarball.
