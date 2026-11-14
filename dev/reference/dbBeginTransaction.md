# Generic for creating a new transaction

See method documentation for details.

## Usage

``` r
dbBeginTransaction(conn, ...)
```

## Arguments

- conn:

  A `DBIConnection` object.

- ...:

  Other arguments used by methods

## Value

The value returned by
[`dbBegin()`](https://dbi.r-dbi.org/reference/transactions.html).
