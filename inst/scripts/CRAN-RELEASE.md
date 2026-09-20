# shinyglass CRAN release checklist (0.4.0 candidate)

Do **not** submit to CRAN until the maintainer explicitly asks.
Keep `DESCRIPTION` `Version` at a `0.3.0.9000`-style **dev** version until
the bump commit.

## Before the version bump

- [ ] `R CMD check --as-cran` clean (0 errors / 0 warnings). Notes documented.
- [ ] `devtools::spell_check()` / `spelling::spell_check_package()` — `inst/WORDLIST`.
- [ ] `urlchecker::url_check()` on DESCRIPTION, README, vignettes.
- [ ] Examples run (`R CMD check` examples). Interactive-only chunks stay wrapped.
- [ ] Vignettes build (`theming`, `compatibility`, `playground`).
- [ ] `devtools::test()` and visual-qa workflow green (note known Playwright flakes).
- [ ] R-CMD-check: ubuntu + windows green. macOS may flake in
      `setup-r-dependencies` (`pak` “unknown archive type” on a binary
      tarball — seen on `main` for knitr). Workflow retries once.
- [ ] NEWS.md finalized under a **0.4.0** heading (move items off 0.3.0.9000).
- [ ] `cran-comments.md` refreshed for this upload.
- [ ] Reverse dependencies: `revdepcheck::revdep_check()` if any appear on CRAN.
      None known at the time of this draft.
- [ ] Confirm Python / `inst/scripts` / large README figures stay in `.Rbuildignore`.

## Version bump (maintainer only)

- [ ] `Version: 0.4.0` in DESCRIPTION (and Date if used).
- [ ] Rebuild man pages / pkgdown.
- [ ] `R CMD build` then `R CMD check --as-cran` on the tarball.

## Submit (maintainer only)

- [ ] `devtools::release()` or upload via the CRAN portal.
- [ ] Do **not** file a submission from this development branch.

## After accept

- [ ] GitHub release + pkgdown.
- [ ] Redeploy shinyapps demos if CSS/JS changed.
