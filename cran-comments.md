## Resubmission

This is a resubmission of 0.1.1. The previous submission was not accepted
because README.md used relative file URIs (`python/`, `python/README.md`) that
point outside the CRAN tarball (the `python/` tree is in `.Rbuildignore`).
Those links are now absolute GitHub URLs.

## Submission

This is a patch update from 0.1.0 to 0.1.1.

* Fix bslib sidebar / page_sidebar layout under the glass theme so content is
  not buried under the floating sidebar or incorrectly full-width stacked.
* Fix nested layout_sidebar double-float gutter.
* Improve AdminLTE (shinydashboard / bs4Dash) glass overlay for header,
  sidebar, and value/info boxes.

## Test environments

* local Linux, R 4.5.x
* GitHub Actions: ubuntu (release, devel), macOS (release), windows (release)
* R CMD check --as-cran on the source tarball

## R CMD check results

0 errors | 0 warnings | 1 note

* NOTE: Days since last update: 5 (expected for a patch shortly after 0.1.0).

## Downstream dependencies

None.
