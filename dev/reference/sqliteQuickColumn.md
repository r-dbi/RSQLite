# Return an entire column from a SQLite database

A shortcut for
[`dbReadTable`](https://dbi.r-dbi.org/reference/dbReadTable.html)`(con, table, select.cols = column, row.names = FALSE)[[1]]`,
kept for compatibility reasons.

## Usage

``` r
sqliteQuickColumn(con, table, column)
```
