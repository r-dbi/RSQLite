# Was HTTP VFS compiled into this build?

Returns TRUE if the experimental HTTP/HTTPS virtual file system was
compiled in (libcurl detected at build time), FALSE otherwise. This is a
compile-time indicator; even if TRUE the VFS might still fail to
register at runtime on unusual platforms, in which case
[`sqliteHasHttpVFS()`](https://rsqlite.r-dbi.org/reference/sqliteHasHttpVFS.md)
is the definitive runtime capability probe.

## Usage

``` r
sqliteHttpVfsCompiled()
```

## Value

A logical scalar.

## Details

[`sqliteHasHttpVFS()`](https://rsqlite.r-dbi.org/reference/sqliteHasHttpVFS.md)
performs a lazy registration attempt when the VFS is compiled in but not
yet registered. If the HTTP VFS was not compiled in, calls to
[`sqliteRemote()`](https://rsqlite.r-dbi.org/reference/sqliteRemote.md)
will error.

## Examples

``` r
sqliteHttpVfsCompiled()
#> [1] TRUE
```
