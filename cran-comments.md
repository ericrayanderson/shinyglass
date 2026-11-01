## Submission

This is an update from 0.5.0 to 0.6.0.

New in this version: the specular highlight can follow the mouse on desktop,
a navbar that shrinks into a pill while scrolling, "clear" and "tinted"
glass styles, a single `motion` switch, and glass styling for progress bars
and range inputs. NEWS.md lists every change.

The package now bundles Inter (SIL Open Font License 1.1) as a local
variable font, latin subset, about 100 KB, in `inst/fonts/inter/`. It is
served with the app so no outside font server is contacted. The license is
in `inst/fonts/inter/OFL.txt`, `inst/COPYRIGHTS` describes the file, and the
copyright holder is listed in Authors@R.

## Test environments

* local: Debian 13, R 4.5.3
* GitHub Actions: Windows (R 4.5), macOS (R 4.5), Ubuntu (devel, release, oldrel)
* win-builder: R-devel and R-release

## R CMD check results

0 errors | 0 warnings | 0 notes

## Reverse dependencies

None on CRAN.
