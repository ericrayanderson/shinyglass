## Resubmission

This is a resubmission. In this version I have:

* Formatted software and package names in Title and Description with single
  quotes ('shiny', 'bslib', 'Bootstrap') and removed quotes around function
  names (glass_theme(), fluidPage(), navbarPage()).
* Replaced \dontrun{} with if (interactive()) {} in examples.

## Test environments

* local macOS Monterey, R 4.6.1
* GitHub Actions: ubuntu (release, devel), macOS (release), windows (release)
* R CMD check --as-cran on the source tarball

## R CMD check results

0 errors | 0 warnings | 1 note

## Notes

* First CRAN release of shinyglass (resubmission).

## Downstream dependencies

None.
