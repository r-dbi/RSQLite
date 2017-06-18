## Test environments
* Ubuntu 17.04 (local install), R 3.4.0
* Ubuntu 12.04 (on travis-ci), R devel, release, and oldrel
* OS X (on travis-ci), R release
* win-builder (devel and release)

## R CMD check results

0 errors | 0 warnings | 1 note

* Installed size: This package comes with a bundled RSQLite library.

## Reverse dependencies

Checked all 138 CRAN and BioConductor reverse dependencies on Ubuntu 16.04
with RSQLite v2.0. The following CRAN packages had problems that were not
present with RSQLite 1.1-2:

- liteq: resolved on GitHub, https://github.com/gaborcsardi/liteq/pull/13
- sf and sqldf: resolved on GitHub, cannot replicate the check problems I'm seeing with the CRAN version

An e-mail has been sent on April 29 to the downstream maintainers to alert them of the update (which is delayed by three weeks) and of the problems I found.
