# Class SQLiteResult (and methods)

SQLiteDriver objects are created by
[`dbSendQuery()`](https://dbi.r-dbi.org/reference/dbSendQuery.html) or
[`dbSendStatement()`](https://dbi.r-dbi.org/reference/dbSendStatement.html),
and encapsulate the result of an SQL statement (either `SELECT` or not).
They are a superclass of the
[DBIResult](https://dbi.r-dbi.org/reference/DBIResult-class.html) class.
The "Usage" section lists the class methods overridden by RSQLite.

## Usage

``` r
# S4 method for class 'SQLiteResult'
dbBind(res, params, ...)

# S4 method for class 'SQLiteResult'
dbClearResult(res, ...)

# S4 method for class 'SQLiteResult'
dbColumnInfo(res, ...)

# S4 method for class 'SQLiteResult'
dbFetch(res, n = -1, ..., row.names = FALSE)

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

## Value

[`dbBind()`](https://dbi.r-dbi.org/reference/dbBind.html) returns the
result object, invisibly.
[`dbClearResult()`](https://dbi.r-dbi.org/reference/dbClearResult.html)
returns `TRUE`, invisibly.
[`dbColumnInfo()`](https://dbi.r-dbi.org/reference/dbColumnInfo.html)
and [`dbFetch()`](https://dbi.r-dbi.org/reference/dbFetch.html) return a
data frame.
[`dbGetRowCount()`](https://dbi.r-dbi.org/reference/dbGetRowCount.html)
and
[`dbGetRowsAffected()`](https://dbi.r-dbi.org/reference/dbGetRowsAffected.html)
return a numeric scalar.
[`dbGetStatement()`](https://dbi.r-dbi.org/reference/dbGetStatement.html)
returns a character string.
[`dbHasCompleted()`](https://dbi.r-dbi.org/reference/dbHasCompleted.html)
and [`dbIsValid()`](https://dbi.r-dbi.org/reference/dbIsValid.html)
return a logical scalar.

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
