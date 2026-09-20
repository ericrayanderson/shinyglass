## Submission

This is an update from 0.3.0 (2026-09-09) to 0.4.0.

Incoming pretest notes from the first 0.3.0 upload (quoted software
names in DESCRIPTION; README URIs that pointed at `.Rbuildignore`'d
`python/` and `inst/scripts/` paths) stay fixed. Those README links
are GitHub URLs; 'ggplot2', 'plotly', 'gt', and 'DT' are single-quoted
in Description.

### User-facing changes

* `plot_surface` is the content-surface story for ggplot / plotly /
  gt / DT (`glass_theme(plot_surface = )`, `theme_glass(surface = )`,
  `dt_options_glass()`).
* Deeper bslib Liquid Glass (navbar, navsets, cards, sidebars,
  accordion, tooltips, modals) plus focus rings and stacking.
* Scene pack: `aurora`, `harbor`, `grove` (plus existing tahoe / dusk /
  mesh); washed user wallpapers with a documented contrast floor.
* Flatten mode for print / chromote / PDF / static capture.
* Public `--glass-*` tokens via `glass_css_tokens()` /
  `glass_add_tokens()`.
* Narrow (≤480px) layout CSS for core demos; overflow and table
  containment at laptop widths.
* Closer iOS 27 material (darker edges, brighter specular, scroll-edge
  toolbar). Overlay menus portal out of glass cards.

No breaking API changes from 0.3.0. `glass_theme()` gains optional
`flatten` and `tokens` arguments with defaults that preserve the
current look.

## Test environments

* GitHub Actions: ubuntu (release, devel), macOS (R 4.5), windows (release)
* `R CMD check --as-cran` (CI uses `--no-manual`; source tarball for submit)
* visual-qa: testthat + dual-theme contrast audit + Playwright runtime
  (including 480px overflow checks)

Known CI notes (not package defects):

* macOS `release` (R 4.6) CRAN binaries for `knitr` and `xfun` are
  zstd-compressed `.tgz` files. `pak` stable cannot extract those
  ("unknown archive type"). The R-CMD-check macOS cell uses R 4.5,
  whose binaries are still gzip. Ubuntu release + devel and Windows
  stay on current R.
* `urlchecker::url_check()` can flake on transient HTTP; CI retries.

## R CMD check results

<!-- CI / local --as-cran will fill this in. -->

**0 errors | 0 warnings | 0 notes** expected on the 0.4.0 tarball aside
from a possible incoming "days since last update" NOTE (~11 days after
0.3.0). That interval is short but 0.4.0 is a real feature set (plot
surfaces, bslib depth, scenes, flatten, tokens, mobile QA), not a
drive-by tweak.

Local: _pending_
GitHub Actions: _pending_

## Downstream dependencies

None known. `revdepcheck` is not required unless reverse depends
appear on CRAN before upload.

## Notes

* Large README marketing assets stay on GitHub via `.Rbuildignore`.
* Live demos: shinyglass-demo, -dashboard, -inputs, -plotly-gt, -olympics.
* Experimental Python package is not in the CRAN tarball (version
  tracks 0.4.0; not a PyPI release).
* Release checklist: `inst/scripts/CRAN-RELEASE.md` (devtools-only; not
  in the tarball).
* This branch prepares the candidate only. Do not submit to CRAN until
  the maintainer asks.
