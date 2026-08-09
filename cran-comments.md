## Submission

This is an update from 0.1.1 to 0.2.0.

### User-facing changes

* Runtime light/dark/auto theme switching without page reload (dual CSS
  variable packs on `[data-glass-preset]`).
* `update_glass_theme()` for preset, tint, and live primary accent.
* `glass_theme_toggle()` helper buttons.
* Active-on-accent contrast fix (white checks/knobs on primary blue).
* Reduced-motion support; softer plot frames; demo fixes.

### Breaking (documented in NEWS + vignette)

* Dark mode no longer uses Bootswatch `darkly`; it uses the glass dark CSS pack.
* Prefer CSS `--glass-*` variables over Sass-only `$glass-*` overrides.

## Test environments

* local Linux, R 4.5.x
* GitHub Actions: ubuntu (release, devel), macOS (release), windows (release)
* R CMD check --as-cran on the source tarball

## R CMD check results

0 errors | 0 warnings | 0 notes

## Downstream dependencies

None known.
