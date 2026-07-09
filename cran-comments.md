## Test environments

* local macOS Monterey, R 4.6.1
* `R CMD check --as-cran` on the source tarball

## R CMD check results

0 errors | 0 warnings | notes (see below)

## Notes

* **New submission.** First CRAN release of shinyglass.
* **HTML manual validation.** Local check skips HTML tidy validation when the installed tidy is too old; not package-related.
* **README / NEWS.** Screenshots are loaded from the GitHub repository so the source tarball stays small. Pandoc is recommended when checking README locally.

## Downstream dependencies

There are currently no reverse dependencies.
