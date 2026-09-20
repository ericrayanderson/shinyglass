# shinyglass CRAN release checklist (0.4.0 candidate)

Do **not** submit to CRAN until the maintainer explicitly asks.
This file is excluded from the tarball (`.Rbuildignore`).

`DESCRIPTION` `Version` is **0.4.0** on the release-candidate branch.
Do not file a submission from a development (`.9000`) tree.

## This candidate (done on the 0.4.0 bump)

- [x] `Version: 0.4.0` in DESCRIPTION (no Date field; follow existing style).
- [x] NEWS.md finalized under a **0.4.0** heading (0.3.0.9000 folded in).
- [x] `cran-comments.md` refreshed for this upload.
- [x] Python `pyproject.toml` / `_version.py` track 0.4.0 (not in tarball).
- [x] README install instructions mention CRAN 0.4.0; GitHub is secondary.
- [x] DESCRIPTION Title / Description CRAN-clean (quoted software names).
- [x] Examples are cheap or `interactive()`-guarded.
- [x] Confirm Python / `inst/scripts` / large README figures stay in `.Rbuildignore`.

## Before upload (maintainer)

- [ ] `R CMD check --as-cran` clean (0 errors / 0 warnings). Notes documented
      in `cran-comments.md` (CI uses `--no-manual`; submit the full tarball).
- [ ] `devtools::spell_check()` / `spelling::spell_check_package()` —
      `inst/WORDLIST`.
- [ ] `urlchecker::url_check()` on DESCRIPTION, README, vignettes.
- [ ] Examples run (`R CMD check` examples).
- [ ] Vignettes build (`theming`, `compatibility`, `playground`).
- [ ] `devtools::test()` and visual-qa workflow green (note known
      Playwright / URL-check flakes).
- [ ] R-CMD-check: ubuntu (release + devel) + windows + macOS green.
      macOS CI is pinned to R 4.5 because R 4.6 CRAN `knitr`/`xfun`
      binaries are zstd and `pak` stable cannot extract them.
- [ ] Reverse dependencies: `revdepcheck::revdep_check()` if any appear
      on CRAN. None known at the time of this candidate.
- [ ] Rebuild man pages / pkgdown if roxygen source changed after the bump.

## Submit (maintainer only)

- [ ] `devtools::release()` or upload via the CRAN portal.
- [ ] Do **not** file a submission from this agent / automation run.

## After accept

- [ ] GitHub release + pkgdown.
- [ ] Redeploy shinyapps demos if CSS/JS changed.
- [ ] Record the upload in `CRAN-SUBMISSION` (devtools writes this).
