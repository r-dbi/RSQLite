# Class SQLiteResult (and methods)

SQLiteDriver objects are created by
[`DBI::dbSendQuery()`](https://dbi.r-dbi.org/reference/dbSendQuery.html)
or
[`DBI::dbSendStatement()`](https://dbi.r-dbi.org/reference/dbSendStatement.html),
and encapsulate the result of an SQL statement (either `SELECT` or not).
They are a superclass of the
[DBI::DBIResult](https://dbi.r-dbi.org/reference/DBIResult-class.html)
class. The "Usage" section lists the class methods overridden by
RSQLite.

## Usage

``` r
# S4 method for class 'SQLiteResult'
dbBind(res, params, ...)

# S4 method for class 'SQLiteResult'
dbClearResult(res, ...)

# S4 method for class 'SQLiteResult'
dbColumnInfo(res, ...)

# S4 method for class 'SQLiteResult'
dbFetch(
  res,
  n = -1,
  ...,
  row.names = pkgconfig::get_config("RSQLite::row.names.query", FALSE)
)

# S4 method for class 'SQLiteResult'
dbGetRowCount(res, ...)

# S4 method for class 'SQLiteResult'
dbGetRowsAffected(res, ...)

# S4 method for class 'SQLiteResult'
dbGetStatement(res, ...)

# S4 method for class 'SQLiteResult'
dbHasCompleted(res, ...)

# S4 method for class 'SQLiteResult'
dbIsValid(dbObj, ...)
```

## See also

The corresponding generic functions
[`DBI::dbFetch()`](https://dbi.r-dbi.org/reference/dbFetch.html),
[`DBI::dbClearResult()`](https://dbi.r-dbi.org/reference/dbClearResult.html),
and [`DBI::dbBind()`](https://dbi.r-dbi.org/reference/dbBind.html),
[`DBI::dbColumnInfo()`](https://dbi.r-dbi.org/reference/dbColumnInfo.html),
[`DBI::dbGetRowsAffected()`](https://dbi.r-dbi.org/reference/dbGetRowsAffected.html),
[`DBI::dbGetRowCount()`](https://dbi.r-dbi.org/reference/dbGetRowCount.html),
[`DBI::dbHasCompleted()`](https://dbi.r-dbi.org/reference/dbHasCompleted.html),
and
[`DBI::dbGetStatement()`](https://dbi.r-dbi.org/reference/dbGetStatement.html).
