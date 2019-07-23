## Reverse dependencies

- readwritesqlite: failure expected, author has been notified and already has prepared a fix. <https://github.com/poissonconsulting/readwritesqlite/issues/9>

Checked almost all CRAN and Bioconductor downstream dependencies on Ubuntu 18.04
with RSQLite v2.1.1.

## Release description

Minor release for compatibility with blob 1.2.0.

## Test environments

* Ubuntu 18.04 (local install), R 3.6.0
* Ubuntu 16.04 (on travis-ci), R devel, release, and oldrel
* OS X (on travis-ci), R release
* win-builder (devel)

## R CMD check results

OK
