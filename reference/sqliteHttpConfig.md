# Configure experimental HTTP VFS behavior (optional)

lifecycle::badge("experimental")

Set conservative, process-wide options for the experimental HTTP/HTTPS
VFS. These values are read on first open of a remote database in the
current process.

## Usage

``` r
sqliteHttpConfig(
  cache_size_mb = NULL,
  prefetch_pages = NULL,
  fallback_full_download = NULL
)
```

## Arguments

- cache_size_mb:

  Integer megabytes for in-memory page cache. `NULL` leaves unchanged.

- prefetch_pages:

  Integer pages to prefetch ahead. `NULL` leaves unchanged.

- fallback_full_download:

  Logical; if `TRUE`, allow full-download fallback when Range is not
  available. `NULL` leaves unchanged.

## Value

A named list of previous values (in R types).

## Details

Options are stored in environment variables so they also affect C-level
code:

- `RSQLITE_HTTP_CACHE_MB`: In-memory page cache size in megabytes
  (default 4).

- `RSQLITE_HTTP_PREFETCH_PAGES`: Prefetch this many pages ahead (default
  0).

- `RSQLITE_HTTP_FALLBACK_FULLDL`: If `TRUE` (default), fall back to full
  download when the server does not support HTTP Range; if `FALSE`, open
  will fail.

## Examples

``` r
old <- sqliteHttpConfig(cache_size_mb = 8, prefetch_pages = 1, fallback_full_download = TRUE)
on.exit(do.call(sqliteHttpConfig, old), add = TRUE)
# ... connect with sqliteRemote() ...
```
