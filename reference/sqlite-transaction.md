# SQLite transaction management

By default, SQLite is in auto-commit mode.
[`dbBegin()`](https://dbi.r-dbi.org/reference/transactions.html) starts
a SQLite transaction and turns auto-commit off.
[`dbCommit()`](https://dbi.r-dbi.org/reference/transactions.html) and
[`dbRollback()`](https://dbi.r-dbi.org/reference/transactions.html)
commit and rollback the transaction, respectively and turn auto-commit
on.
[`DBI::dbWithTransaction()`](https://dbi.r-dbi.org/reference/dbWithTransaction.html)
is a convenient wrapper that makes sure that
[`dbCommit()`](https://dbi.r-dbi.org/reference/transactions.html) or
[`dbRollback()`](https://dbi.r-dbi.org/reference/transactions.html) is
called. A helper function `sqliteIsTransacting()` is available to check
the current transaction status of the connection.

## Usage

``` r
# S4 method for class 'SQLiteConnection'
dbBegin(conn, .name = NULL, ..., name = NULL)

# S4 method for class 'SQLiteConnection'
dbCommit(conn, .name = NULL, ..., name = NULL)

# S4 method for class 'SQLiteConnection'
dbRollback(conn, .name = NULL, ..., name = NULL)

sqliteIsTransacting(conn)
```

## Arguments

- conn:

  a
  [`SQLiteConnection`](https://rsqlite.r-dbi.org/reference/SQLiteConnection-class.md)
  object, produced by
  [`DBI::dbConnect()`](https://dbi.r-dbi.org/reference/dbConnect.html)

- .name:

  For backward compatibility, do not use.

- ...:

  Needed for compatibility with generic. Otherwise ignored.

- name:

  Supply a name to use a named savepoint. This allows you to nest
  multiple transaction

## See also

The corresponding generic functions
[`DBI::dbBegin()`](https://dbi.r-dbi.org/reference/transactions.html),
[`DBI::dbCommit()`](https://dbi.r-dbi.org/reference/transactions.html),
and
[`DBI::dbRollback()`](https://dbi.r-dbi.org/reference/transactions.html).

## Examples

``` r
library(DBI)
con <- dbConnect(SQLite(), ":memory:")
dbWriteTable(con, "arrests", datasets::USArrests)
dbGetQuery(con, "select count(*) from arrests")
#>   count(*)
#> 1       50

dbBegin(con)
rs <- dbSendStatement(con, "DELETE from arrests WHERE Murder > 1")
dbGetRowsAffected(rs)
#> [1] 49
dbClearResult(rs)

dbGetQuery(con, "select count(*) from arrests")
#>   count(*)
#> 1        1

dbRollback(con)
dbGetQuery(con, "select count(*) from arrests")[1, ]
#> [1] 50

dbBegin(con)
rs <- dbSendStatement(con, "DELETE FROM arrests WHERE Murder > 5")
dbClearResult(rs)
dbCommit(con)
dbGetQuery(con, "SELECT count(*) FROM arrests")[1, ]
#> [1] 16

# Named savepoints can be nested --------------------------------------------
dbBegin(con, name = "a")
dbBegin(con, name = "b")
sqliteIsTransacting(con)
#> [1] TRUE
dbRollback(con, name = "b")
dbCommit(con, name = "a")

dbDisconnect(con)
```
