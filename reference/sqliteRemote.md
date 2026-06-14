# Convenience helper for opening remote SQLite databases over HTTP/HTTPS

lifecycle::badge("experimental")

Constructs a URI filename and sets the appropriate VFS and immutable
flags. Requires the optional http extension to be available; see
[`sqliteHasHttpVFS()`](https://rsqlite.r-dbi.org/reference/sqliteHasHttpVFS.md).

## Usage

``` r
sqliteRemote(url, immutable = TRUE, ...)
```

## Arguments

- url:

  Remote HTTP/HTTPS URL to a SQLite database file.

- immutable:

  Logical, append `immutable=1` to the URI.

- ...:

  Passed through to
  [`DBI::dbConnect()`](https://dbi.r-dbi.org/reference/dbConnect.html).

## Value

A
[SQLiteConnection](https://rsqlite.r-dbi.org/reference/SQLiteConnection-class.md)
object.

## Examples

``` r
if (FALSE) {
if (sqliteHasHttpVFS()) {
  con <- sqliteRemote("https://example.org/db.sqlite")
  dbGetQuery(con, "SELECT name FROM sqlite_master WHERE type='table'")
  dbDisconnect(con)
}
}
```
