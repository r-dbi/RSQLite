## Test environments

* Ubuntu 17.10 (local install), R 3.4.3
* Ubuntu 12.04 (on travis-ci), R devel, release, and oldrel
* OS X (on travis-ci), R release
* win-builder (devel and release)

## R CMD check results

OK

## Reverse dependencies

Checked all CRAN downstream dependencies on Ubuntu 16.04
with RSQLite v2.1.0. The following CRAN package had problems that were not
present with RSQLite v2.0:

- ProjectTemplate: Checks now failing due to changed wording in error message. Filed an issue: https://github.com/KentonWhite/ProjectTemplate/issues/228.
