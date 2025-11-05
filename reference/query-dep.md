# Deprecated querying tools

These functions have been deprecated. Please switch to using
[`DBI::dbSendQuery()`](https://dbi.r-dbi.org/reference/dbSendQuery.html)/[`DBI::dbGetQuery()`](https://dbi.r-dbi.org/reference/dbGetQuery.html)
with the `params` argument or with calling
[`DBI::dbBind()`](https://dbi.r-dbi.org/reference/dbBind.html) instead.

## Usage

``` r
dbGetPreparedQuery(conn, statement, bind.data, ...)

# S4 method for class 'SQLiteConnection,character,data.frame'
dbGetPreparedQuery(conn, statement, bind.data, ...)

dbSendPreparedQuery(conn, statement, bind.data, ...)

# S4 method for class 'SQLiteConnection,character,data.frame'
dbSendPreparedQuery(conn, statement, bind.data, ...)
```

## Arguments

- conn:

  A `DBIConnection` object.

- statement:

  A SQL string

- bind.data:

  A data frame of data to be bound.

- ...:

  Other arguments used by methods
