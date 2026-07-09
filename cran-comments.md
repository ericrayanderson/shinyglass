## Test environments

* local macOS Monterey, R 4.6.1
* GitHub Actions: ubuntu (release, devel), macOS (release), windows (release)
* `R CMD check --as-cran` on the source tarball

## R CMD check results

0 errors | 0 warnings | 2 notes

## Notes

* **New submission.** First CRAN release of shinyglass.
* **HTML manual validation.** Local check skips HTML tidy when the installed
  tidy is older than CRAN's; not package-related.

## Downstream dependencies

There are currently no reverse dependencies.
