## Submission

This is an update from 0.1.1 to 0.2.0.

### User-facing changes

* Runtime light/dark/auto theme switching without page reload (dual CSS
  variable packs on `[data-glass-preset]`).
* `update_glass_theme()` for preset, tint, and live primary accent.
* `glass_theme_toggle()` / `observe_glass_theme_toggle()` helpers.
* Active-on-accent contrast fix (white checks/knobs on brand primary).
* DT/selectize glass chrome fixes; plotly/gt/AdminLTE overlay CSS.
* Navbar brand ink matches glass body color; plotly axis titles not clipped.
* Reduced-motion support; softer plot frames; demo fixes.

### Breaking (documented in NEWS + vignette)

* Dark mode no longer uses Bootswatch `darkly`; it uses the glass dark CSS pack.
* Prefer CSS `--glass-*` variables over Sass-only `$glass-*` overrides.

## Test environments

* local macOS, R 4.6.x
* GitHub Actions: ubuntu (release, devel), macOS (release), windows (release)
* R CMD check --as-cran on the source tarball
* visual-qa workflow: testthat + dual-theme contrast audit

## R CMD check results

0 errors | 0 warnings | 1 note

* checking CRAN incoming feasibility: Note only
  Days since last update: 6

This is expected for a follow-up release within two weeks of 0.1.1.
There are no other notes.

## Downstream dependencies

None known.
