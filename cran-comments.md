## Submission

This is an update from 0.4.0 to 0.5.0.

This branch prepares the candidate only. Do not submit to CRAN, and do
not merge, until the maintainer asks.

Incoming pretest notes from the 0.3.0 upload (quoted software names in
DESCRIPTION; README URIs that pointed at `.Rbuildignore`'d `python/` and
`inst/scripts/` paths) stay fixed. Those README links are GitHub URLs.
'ggplot2', 'plotly', 'gt', and 'DT' are single-quoted in Description.

### User-facing changes

* iOS 27 defaults: intensity `0.5` (was `0.45`), darker edges, static
  specular bands, Chromium squircle refraction, morphing selection,
  press springs, tab-bar minimize, and monochrome clear-glass icons.
  `vignette("migrating")` shows how to approximate the 0.4.0 look.
* `material = "clear"` is deprecated. Omitted `intensity` still maps to
  `0.12` and warns.
* Accessibility overrides (reduced transparency, increased contrast,
  forced colors) win over inline `--glass-*` values.
* First-class shinyreact components (`glass_page_react()`,
  `useGlassTheme()`, `GlassIntensitySlider`) and a compatibility
  fixture for common widgets.
* Harbor notes, a shinychat demo, joins the five-app set with basics,
  dashboard, inputs, and Olympics. It is not on shinyapps.io yet, so
  the README and pkgdown link the source and the article, not a hosted
  URL. plotly + gt stays a local example.
* shinychat `page_chat()` / `chat_ui()` and bslib `offcanvas()` use the
  glass material.

`floating_sidebar` stays off unless the app opts in. Layout, inputs,
and click targets are unchanged.

## Test environments

* GitHub Actions: ubuntu (release, devel, oldrel), macOS (R 4.5),
  windows (R 4.5)
* `R CMD check --as-cran` (CI uses `--no-manual`; local run recorded
  below)
* `urlchecker::url_check()` and `spelling::spell_check_package()` on
  the ubuntu release cell. Spelling fails the job when the word list
  is short.
* visual-qa: testthat + dual-theme contrast audit (including Harbor
  notes) + Playwright runtime (compatibility, shinychat, offcanvas)

This matrix is the feasible stand-in for win-builder and rhub. Windows
and macOS stay on R 4.5 because pak cannot install R 4.6 dependencies
there (zstd macOS binaries for knitr and xfun; no Windows pak binary
index for 4.6). This candidate was not submitted to win-builder or
rhub.

Known CI notes (not package defects):

* macOS `release` (R 4.6) CRAN binaries for `knitr` and `xfun` are
  zstd-compressed `.tgz` files. `pak` stable cannot extract those
  ("unknown archive type"). The R-CMD-check macOS cell uses R 4.5,
  whose binaries are still gzip. Ubuntu release, devel, and oldrel
  stay on current R for those channels. Windows stays on R 4.5 for
  the pak index.
* `urlchecker::url_check()` can flake on transient HTTP; CI retries.

## R CMD check results

Local results are filled in after `R CMD check --as-cran` on this
candidate. GitHub Actions runs on the pull request.

## Downstream dependencies

None known. `revdepcheck` is not required unless reverse depends
appear on CRAN before upload.

## Notes

* Large README marketing assets stay on GitHub via `.Rbuildignore`,
  including the Harbor notes screenshots and the intensity GIF.
* Live demos: shinyglass-demo, -dashboard, -inputs, -olympics.
  shinyglass-chat is the Harbor notes app name and is not deployed yet.
  plotly-gt remains a local example.
* Experimental Python package is not in the CRAN tarball (version
  tracks 0.5.0; not a PyPI release).
* Release checklist: `inst/scripts/CRAN-RELEASE.md` (devtools-only; not
  in the tarball).
