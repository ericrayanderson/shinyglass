## R CMD check results

* Platform: macOS (R 4.4.1), `R CMD check --as-cran`
* Status: 0 errors | 0 warnings | NOTES (see below)

## Downstream dependencies

This is the first CRAN release. `revdepcheck` was not run because there
are no reverse dependencies yet.

## NOTEs (and responses)

### CRAN incoming feasibility

New submission. GPL-3 + file LICENSE. Maintainer email is active.

### Tarball size

Large README/gallery figures are excluded from the source tarball via
`.Rbuildignore`. The distributed package includes one help figure.

### HTML manual validation

`glass_theme.Rd` triggers standard Rd2HTML notes (`<main>`, `<table>`
summary). No package-specific HTML issues remain after replacing Unicode
punctuation in documentation.

### README / NEWS

Checked locally. Pandoc was not available in the check environment.

## Additional checks

* `devtools::test()` passes.
* Visual regression scripts are maintainer-only (excluded from tarball).