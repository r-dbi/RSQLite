
<!-- README.md is generated from README.Rmd. Please edit that file -->

# RSQLite

<!-- badges: start -->

[![Lifecycle:
stable](https://img.shields.io/badge/lifecycle-stable-brightgreen.svg)](https://lifecycle.r-lib.org/articles/stages.html)
[![rcc](https://github.com/r-dbi/RSQLite/workflows/rcc/badge.svg)](https://github.com/r-dbi/RSQLite/actions)
[![Coverage
Status](https://codecov.io/gh/r-dbi/RSQLite/branch/main/graph/badge.svg)](https://app.codecov.io/github/r-dbi/RSQLite?branch=main)
[![CRAN
status](https://www.r-pkg.org/badges/version/RSQLite)](https://cran.r-project.org/package=RSQLite)
[![CII Best
Practices](https://bestpractices.coreinfrastructure.org/projects/3234/badge)](https://bestpractices.coreinfrastructure.org/projects/3234)
<!-- badges: end -->

Embeds the SQLite database engine in R, providing a DBI-compliant
interface. [SQLite](https://www.sqlite.org/index.html) is a
public-domain, single-user, very light-weight database engine that
implements a decent subset of the SQL 92 standard, including the core
table creation, updating, insertion, and selection operations, plus
transaction management.

You can install the latest released version from CRAN with:

``` r
install.packages("RSQLite")
```

Or install the latest development version from GitHub with:

``` r
# install.packages("devtools")
devtools::install_github("r-dbi/RSQLite")
```

## Experimental: HTTP/HTTPS VFS

RSQLite can optionally be built with an experimental HTTP virtual file
system (VFS) that allows opening remote (read-only, immutable) SQLite
database files directly via URI filenames.

When enabled (libcurl detected at build time), the HTTP VFS fetches
database pages on demand using HTTP Range requests and stores them in a
small in-memory LRU cache. Only needed pages are transferred; an
optional prefetch can read a few pages ahead. If the server does not
advertise Range support (`Accept-Ranges: bytes`), you can choose between
a one-time full download fallback or failing the open.

Related projects with more advanced capabilities (different environments
/ languages):

- C/C++ SQLite extension: `sqlite_web_vfs`
  (<https://github.com/mlin/sqlite_web_vfs>) – performs adaptive range
  GET requests, read-ahead, optional helper `.dbi` sidecar file, logging
  & tuning controls.
- Rust crate: `sqlite-vfs-http` – provides an HTTP VFS in Rust (see
  crates.io) with asynchronous networking (not bundled here).
- JavaScript/WASM: `sqlite-wasm-http`
  (<https://www.npmjs.com/package/sqlite-wasm-http>) – supports HTTP
  range requests in browser/Node environments, optional shared cache via
  `SharedArrayBuffer`, worker pool APIs.

RSQLite’s bundled HTTP VFS purpose is narrow: simple, synchronous,
read-only access to immutable databases over HTTP/HTTPS in environments
where libcurl is available at build time. For large databases or
high-latency workloads consider the above specialized projects or
downloading the database locally first.

Configuration (process-wide, via environment variables or helper):

- `sqlite_http_config(cache_size_mb = ..., prefetch_pages = ..., fallback_full_download = ...)`
  adjusts settings and returns previous values.
- Env vars: `RSQLITE_HTTP_CACHE_MB` (default `4` MB),
  `RSQLITE_HTTP_PREFETCH_PAGES` (default `0`),
  `RSQLITE_HTTP_FALLBACK_FULLDL` (`1` or `0`).

Introspection:

- Compile-time presence: `RSQLite:::sqlite_httpvfs_compiled()` returns
  `TRUE` iff the package was built with libcurl (and thus defined
  `RSQLITE_ENABLE_HTTPVFS`). This is an internal diagnostic helper.
- Runtime capability: `sqliteHasHttpVFS()` returns TRUE on supported
  builds; it performs a lazy registration attempt if not already
  registered.
- Statistics: `sqliteHttpStats()` returns a list: `bytes_fetched`,
  `range_requests`, `full_download` (TRUE if any connection fell back to
  full download).

Limitations (current scope):

- Read-only, assumes immutability (use `immutable=1` URI parameter)
- Cache is in-memory only; no persistence across processes
- Minimal prefetch and no advanced concurrency optimizations

``` r
library(DBI)
library(RSQLite)
if (sqliteHasHttpVFS()) {
  # Adjust config (optional)
  # old <- sqlite_http_config(cache_size_mb = 8, prefetch_pages = 1, fallback_full_download = TRUE)
  # on.exit(do.call(sqlite_http_config, old), add = TRUE)

  # Open remote immutable database (example URL must point to a real SQLite file)
  # con <- sqlite_remote("https://example.org/db.sqlite")
  # dbGetQuery(con, "SELECT name FROM sqlite_master WHERE type='table'")
  # print(sqliteHttpStats())
  # dbDisconnect(con)
}
```

Notes: \* Requires build-time libcurl detection (configured
automatically when available). Eager registration only runs when
compiled with `RSQLITE_ENABLE_HTTPVFS`; otherwise capability checks
return FALSE immediately. \* Uses HTTP Range when supported; fallback
full download is configurable. \* Statistics are best-effort and reset
per process. \* Write operations are not supported. \* API and behavior
are experimental and may change; validate memory usage before deploying.

### Advanced build flags

For advanced users building from source:

- Set `RSQLITE_SILENCE_WARNINGS=1` in the environment before
  installation to apply conservative warning-suppression flags to
  certain third-party/vendor code paths. This is optional and off by
  default.
- On platforms with libcurl available, the configure step defines
  `RSQLITE_ENABLE_HTTPVFS` and wires the necessary
  `CURL_CFLAGS`/`CURL_LIBS` automatically; otherwise the HTTP VFS is
  omitted cleanly.

Discussions associated with DBI and related database packages take place
on [R-SIG-DB](https://stat.ethz.ch/mailman/listinfo/r-sig-db). The
website [Databases using R](https://db.rstudio.com/) describes the tools
and best practices in this ecosystem.

## Basic usage

``` r
library(DBI)
# Create an ephemeral in-memory RSQLite database
con <- dbConnect(RSQLite::SQLite(), ":memory:")

dbListTables(con)
```

    ## character(0)

``` r
dbWriteTable(con, "mtcars", mtcars)
dbListTables(con)
```

    ## [1] "mtcars"

``` r
dbListFields(con, "mtcars")
```

    ##  [1] "mpg"  "cyl"  "disp" "hp"   "drat" "wt"   "qsec" "vs"   "am"   "gear"
    ## [11] "carb"

``` r
dbReadTable(con, "mtcars")
```

    ##     mpg cyl  disp  hp drat    wt  qsec vs am gear carb
    ## 1  21.0   6 160.0 110 3.90 2.620 16.46  0  1    4    4
    ## 2  21.0   6 160.0 110 3.90 2.875 17.02  0  1    4    4
    ## 3  22.8   4 108.0  93 3.85 2.320 18.61  1  1    4    1
    ## 4  21.4   6 258.0 110 3.08 3.215 19.44  1  0    3    1
    ## 5  18.7   8 360.0 175 3.15 3.440 17.02  0  0    3    2
    ## 6  18.1   6 225.0 105 2.76 3.460 20.22  1  0    3    1
    ## 7  14.3   8 360.0 245 3.21 3.570 15.84  0  0    3    4
    ## 8  24.4   4 146.7  62 3.69 3.190 20.00  1  0    4    2
    ## 9  22.8   4 140.8  95 3.92 3.150 22.90  1  0    4    2
    ## 10 19.2   6 167.6 123 3.92 3.440 18.30  1  0    4    4
    ## 11 17.8   6 167.6 123 3.92 3.440 18.90  1  0    4    4
    ## 12 16.4   8 275.8 180 3.07 4.070 17.40  0  0    3    3
    ## 13 17.3   8 275.8 180 3.07 3.730 17.60  0  0    3    3
    ## 14 15.2   8 275.8 180 3.07 3.780 18.00  0  0    3    3
    ## 15 10.4   8 472.0 205 2.93 5.250 17.98  0  0    3    4
    ## 16 10.4   8 460.0 215 3.00 5.424 17.82  0  0    3    4
    ## 17 14.7   8 440.0 230 3.23 5.345 17.42  0  0    3    4
    ## 18 32.4   4  78.7  66 4.08 2.200 19.47  1  1    4    1
    ## 19 30.4   4  75.7  52 4.93 1.615 18.52  1  1    4    2
    ## 20 33.9   4  71.1  65 4.22 1.835 19.90  1  1    4    1
    ## 21 21.5   4 120.1  97 3.70 2.465 20.01  1  0    3    1
    ## 22 15.5   8 318.0 150 2.76 3.520 16.87  0  0    3    2
    ## 23 15.2   8 304.0 150 3.15 3.435 17.30  0  0    3    2
    ## 24 13.3   8 350.0 245 3.73 3.840 15.41  0  0    3    4
    ## 25 19.2   8 400.0 175 3.08 3.845 17.05  0  0    3    2
    ## 26 27.3   4  79.0  66 4.08 1.935 18.90  1  1    4    1
    ## 27 26.0   4 120.3  91 4.43 2.140 16.70  0  1    5    2
    ## 28 30.4   4  95.1 113 3.77 1.513 16.90  1  1    5    2
    ## 29 15.8   8 351.0 264 4.22 3.170 14.50  0  1    5    4
    ## 30 19.7   6 145.0 175 3.62 2.770 15.50  0  1    5    6
    ## 31 15.0   8 301.0 335 3.54 3.570 14.60  0  1    5    8
    ## 32 21.4   4 121.0 109 4.11 2.780 18.60  1  1    4    2

``` r
# You can fetch all results:
res <- dbSendQuery(con, "SELECT * FROM mtcars WHERE cyl = 4")
dbFetch(res)
```

    ##     mpg cyl  disp  hp drat    wt  qsec vs am gear carb
    ## 1  22.8   4 108.0  93 3.85 2.320 18.61  1  1    4    1
    ## 2  24.4   4 146.7  62 3.69 3.190 20.00  1  0    4    2
    ## 3  22.8   4 140.8  95 3.92 3.150 22.90  1  0    4    2
    ## 4  32.4   4  78.7  66 4.08 2.200 19.47  1  1    4    1
    ## 5  30.4   4  75.7  52 4.93 1.615 18.52  1  1    4    2
    ## 6  33.9   4  71.1  65 4.22 1.835 19.90  1  1    4    1
    ## 7  21.5   4 120.1  97 3.70 2.465 20.01  1  0    3    1
    ## 8  27.3   4  79.0  66 4.08 1.935 18.90  1  1    4    1
    ## 9  26.0   4 120.3  91 4.43 2.140 16.70  0  1    5    2
    ## 10 30.4   4  95.1 113 3.77 1.513 16.90  1  1    5    2
    ## 11 21.4   4 121.0 109 4.11 2.780 18.60  1  1    4    2

``` r
dbClearResult(res)

# Or a chunk at a time
res <- dbSendQuery(con, "SELECT * FROM mtcars WHERE cyl = 4")
while (!dbHasCompleted(res)) {
  chunk <- dbFetch(res, n = 5)
  print(nrow(chunk))
}
```

    ## [1] 5
    ## [1] 5
    ## [1] 1

``` r
# Clear the result
dbClearResult(res)

# Disconnect from the database
dbDisconnect(con)
```

## Acknowledgements

Many thanks to Doug Bates, Seth Falcon, Detlef Groth, Ronggui Huang,
Kurt Hornik, Uwe Ligges, Charles Loboz, Duncan Murdoch, and Brian D.
Ripley for comments, suggestions, bug reports, and/or patches.

------------------------------------------------------------------------

Please note that the ‘RSQLite’ project is released with a [Contributor
Code of Conduct](https://rsqlite.r-dbi.org/code_of_conduct). By
contributing to this project, you agree to abide by its terms.
