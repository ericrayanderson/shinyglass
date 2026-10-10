# shinyglass CRAN release checklist (0.5.0 candidate)

Do **not** submit to CRAN until the maintainer explicitly asks.
This file is excluded from the tarball (`.Rbuildignore`).

`DESCRIPTION` `Version` is **0.5.0** on the release-candidate branch.
Do not file a submission from a development (`.9000`) tree.

## This candidate (done on the 0.5.0 bump)

- [x] `Version: 0.5.0` in DESCRIPTION (no Date field; follow existing style).
- [x] NEWS.md finalized under a **0.5.0** heading with Breaking changes,
      New features, and Bug fixes (development notes since 0.4.0 folded in).
- [x] `cran-comments.md` refreshed for this upload.
- [x] `vignette("migrating")` covers the visual and API changes, the
      0.4.0 approximation, and `material = "clear"`.
- [x] pkgdown reference lists every export (`tests/testthat/test-pkgdown-reference.R`
      checks this when `_pkgdown.yml` is present).
- [x] Python `pyproject.toml` / `_version.py` track 0.5.0 (not in tarball).
- [x] README install instructions mention CRAN 0.5.0; GitHub is secondary.
      Harbor notes is the flagship and links to the hosted app. The
      archived plotly-gt URL is not linked.
- [x] DESCRIPTION Title / Description CRAN-clean (quoted software names).
- [x] Examples are cheap or `interactive()`-guarded.
- [x] Confirm Python / `inst/scripts` / large README figures stay in `.Rbuildignore`.

## Before upload (maintainer)

- [ ] `R CMD check --as-cran` clean (0 errors / 0 warnings). Notes documented
      in `cran-comments.md` (CI uses `--no-manual`; submit the full tarball).
- [ ] `devtools::spell_check()` / `spelling::spell_check_package()`,
      against `inst/WORDLIST`. CI fails the ubuntu release job when words are missing.
- [ ] `urlchecker::url_check()` on DESCRIPTION, README, vignettes.
- [ ] Examples run (`R CMD check` examples).
- [ ] Vignettes build (`theming`, `migrating`, `compatibility`, `shinyreact`,
      `shinychat`, `playground`).
- [ ] `devtools::test()` and visual-qa workflow green, including the Harbor
      notes contrast pass.
- [ ] R-CMD-check: ubuntu (release + devel + oldrel) + windows (R 4.5) +
      macOS (R 4.5) green. That is the feasible win-builder / rhub stand-in.
      Do not email a win-builder or rhub submission from this branch.
      macOS and Windows stay on R 4.5 because R 4.6 CRAN binaries are zstd
      (macOS) and pak has no Windows 4.6 index.
- [ ] Reverse dependencies: `revdepcheck::revdep_check()` if any appear
      on CRAN. None known at the time of this candidate.
- [ ] Rebuild man pages / pkgdown if roxygen source changed after the bump.

## Submit (maintainer only)

- [ ] `devtools::release()` or upload via the CRAN portal.
- [ ] Do **not** file a submission from this agent / automation run.

## After accept

- [ ] GitHub release + pkgdown.
- [ ] Redeploy shinyapps demos if CSS/JS changed. Harbor notes is
      already at `shinyglass-chat`. Leave the archived plotly-gt app
      offline.
- [ ] Record the upload in `CRAN-SUBMISSION` (devtools writes this).
