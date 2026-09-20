## Submission

This is a **draft** for a future 0.4.0 CRAN candidate. The package version
on this branch remains **0.3.0.9000** (development). Do not submit this
tarball to CRAN until the maintainer bumps Version and asks for a release.

0.3.0 is on CRAN (update from 0.2.0, 2026-08-21). Incoming pretest notes
from that upload (quoted software names; README URIs that pointed at
`.Rbuildignore`'d paths) stay fixed.

### User-facing changes prepared for 0.4.0

* `plot_surface` is the content-surface story for ggplot / plotly / gt / DT.
* Deeper bslib Liquid Glass (navbar, navsets, cards, sidebars, accordion,
  tooltips, modals) plus focus rings and stacking.
* Scene pack: `aurora`, `harbor`, `grove` (plus existing tahoe / dusk / mesh);
  washed user wallpapers with a documented contrast floor.
* Flatten mode for print / chromote / PDF / static capture.
* Public `--glass-*` tokens via `glass_css_tokens()` / `glass_add_tokens()`.
* Narrow (≤480px) layout CSS for core demos.
* Python experimental package (not in the CRAN tarball) closer to R parity.

No breaking API changes from 0.3.0 are intended. `glass_theme()` gains
optional `flatten` and `tokens` arguments with defaults that preserve the
current look.

## Test environments

* GitHub Actions: ubuntu (release, devel), macOS (release), windows (release)
* `R CMD check --as-cran` (CI uses `--no-manual`; source tarball for submit)
* visual-qa: testthat + dual-theme contrast audit + Playwright runtime
  (including 480px overflow checks)

## R CMD check results

Record 0 errors / 0 warnings / notes here after a local `--as-cran` run on
the eventual 0.4.0 tarball. This draft is from the 0.3.0.9000 development
tree.

## Downstream dependencies

None known.

## Notes

* Large README marketing assets stay on GitHub via `.Rbuildignore`.
* Live demos: shinyglass-demo, -dashboard, -inputs, -plotly-gt, -olympics.
* Experimental Python package is not in the CRAN tarball.
* Release checklist: `inst/scripts/CRAN-RELEASE.md` (devtools-only; not
  in the tarball).
