## Test environments
* Ubuntu 16.10 (local install), R 3.3.2
* Ubuntu 12.04 (on travis-ci), R devel, release, and oldrel
* OS X (on travis-ci), R release
* win-builder (devel and release)

## R CMD check results

0 errors | 0 warnings | 1 note

* Installed size: This package comes with a bundled RSQLite library.

* Fixed compatibility issue with sqldf package, releasing minor update.

* I've noticed the ASAN errors with gcc-7, will resolve with the next regular
  release.

## Reverse dependencies

Checked all 120 CRAN and BioConductor reverse dependencies on Ubuntu 16.04
with RSQLite v1.1-2. No regressions found, virtually identical output from R CMD check
for all packages I could install.

See https://github.com/rstats-db/RSQLite/blob/r-1.1-2/revdep/README.md for check results and https://github.com/rstats-db/RSQLite/blob/r-1.1-2/revdep/problems.md
for results for packages with problems only.
