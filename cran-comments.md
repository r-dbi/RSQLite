## Test environments
* Ubuntu 16.10 (local install), R 3.3.2
* Ubuntu 12.04 (on travis-ci), R devel, release, and oldrel
* OS X (on travis-ci), R release
* win-builder (devel and release)

## R CMD check results

0 errors | 0 warnings | 2 note

* Severe bug makes immediate release necessary. (Added test that is triggered
  by the now fixed bug.)

* Installed size: This package comes with a bundled RSQLite library.


## Reverse dependencies

Checked all 117 CRAN and BioConductor reverse dependencies on Ubuntu 16.04
with RSQLite v1.1. No new checks made with RSQLite v1.1-1, because it only
differs by adding protection in one place in C++ code.

A few CRAN packages show errors in this version but succeed with RSQLite v1.0.0:

- ecd (0.8.2) imports RSQLite <= 1.0.0, contacted maintainer several times,
  last time on Oct 20

- poplite (0.99.16), errors fixed in development version:
  https://github.com/dbottomly/poplite/issues/2

- tigreBrowserWriter (0.1.2), contacted maintainer on Nov 17, no response so far.
  The code is using a prepared SQL query with more parameters than the query expects.
  RSQLite is now intentially stricter about such errors, and I believe that a
  downstream fix will be beneficial for the tigreBrowserWriter package.

I couldn't check RQDA and vmsbase, they consistently fail checks with both
versions of RSQLite on my system but succeed checks on CRAN.

All other packages are consistent in their checking behavior for both RSQLite 1.0.0
and 1.1.

See https://github.com/rstats-db/RSQLite/blob/r-1.1/revdep/README.md for check results and https://github.com/rstats-db/RSQLite/blob/r-1.1/revdep/problems.md
for results for packages with problems only.
