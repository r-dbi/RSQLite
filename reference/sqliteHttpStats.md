# Experimental HTTP VFS statistics

Returns counters collected for HTTP VFS operations in the current
process. These values are best-effort and may currently report zeros
until global aggregation is implemented.

## Usage

``` r
sqliteHttpStats()
```

## Value

A list with elements `bytes_fetched`, `range_requests`, `full_download`.

## Details

Statistics are maintained per R process and reset when the process
terminates. Values:

- `bytes_fetched`: Total bytes transferred via HTTP GET/Range requests.

- `range_requests`: Count of HTTP Range requests performed.

- `full_download`: Logical flag; `TRUE` if a fallback full download
  occurred for any open in this process.

If the HTTP VFS was not compiled in, all zeros (and `FALSE`) are
returned.

## See also

[`sqliteHttpConfig()`](https://rsqlite.r-dbi.org/reference/sqliteHttpConfig.md),
[`sqliteRemote()`](https://rsqlite.r-dbi.org/reference/sqliteRemote.md),
[`sqliteHasHttpVFS()`](https://rsqlite.r-dbi.org/reference/sqliteHasHttpVFS.md)

## Examples

``` r
if (sqliteHasHttpVFS()) {
  # Hypothetical remote DB (replace with a real URL for actual use):
  # old <- sqliteHttpConfig(cache_size_mb = 8, prefetch_pages = 1)
  # on.exit(do.call(sqliteHttpConfig, old), add = TRUE)
  # con <- sqliteRemote("https://example.org/db.sqlite")
  # dbGetQuery(con, "SELECT name FROM sqlite_master WHERE type='table'")
  stats <- sqliteHttpStats()
  str(stats)
}
#> List of 3
#>  $ bytes_fetched : int 0
#>  $ range_requests: int 0
#>  $ full_download : logi FALSE
```
