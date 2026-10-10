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
  dashboard, inputs, and Olympics. The hosted app is
  https://ericrayanderson.shinyapps.io/shinyglass-chat/ . plotly + gt
  stays a local example. Its hosted copy is archived, and that URL is
  not linked.
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

Local (Ubuntu 24.04, R 4.6.1, `R CMD check --as-cran`):
**0 errors | 0 warnings | 1 NOTE**

The NOTE is CRAN incoming feasibility. GitHub returned 503 for the
README link to `inst/scripts/VISUAL-QA.md`. That file is on `main`.
`urlchecker::url_check()` reported every URL correct, and a second
fetch of the sibling deploy-doc link returned 200. The 503 is a
transient host response, not a broken link. Examples, tests, and
vignettes (including `migrating`) were OK. The PDF manual built.

`spelling::spell_check_package()`: no spelling errors.

Local contrast audit (`--apps=demo,dashboard,inputs,plotly_gt,chrome,chat`,
light and dark): **FAIL 0 | WARN 26 | PASS 295 | SKIP 396**. Harbor
notes passed on the header, sidebar, composer, user message, thinking
panel, citation, tool card, and the open sources offcanvas, in both
presets. Warnings are the known white-on-`#007AFF` band (about 4.02:1),
which stays under the 4.5 text threshold and above the 3:1 audit floor.

GitHub Actions on this pull request (ubuntu release, devel, and oldrel;
macOS R 4.5; Windows R 4.5; visual-qa including the contrast audit and
Harbor notes; pkgdown; Python): success on the candidate commit. A
follow-up commit that records these notes re-runs the same workflows.

## Downstream dependencies

None known. `revdepcheck` is not required unless reverse depends
appear on CRAN before upload.

## Notes

* Large README marketing assets stay on GitHub via `.Rbuildignore`,
  including the Harbor notes screenshots and the intensity GIF.
* Live demos: shinyglass-chat, -demo, -dashboard, -inputs, -olympics.
  plotly-gt remains a local example. Its hosted copy is archived.
* Experimental Python package is not in the CRAN tarball (version
  tracks 0.5.0; not a PyPI release).
* Release checklist: `inst/scripts/CRAN-RELEASE.md` (devtools-only; not
  in the tarball).
