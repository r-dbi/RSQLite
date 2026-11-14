# Class SQLiteConnection (and methods)

SQLiteConnection objects are created by passing
[`SQLite()`](https://rsqlite.r-dbi.org/dev/reference/SQLite.md) as first
argument to
[`DBI::dbConnect()`](https://dbi.r-dbi.org/reference/dbConnect.html).
They are a superclass of the
[DBIConnection](https://dbi.r-dbi.org/reference/DBIConnection-class.html)
class. The "Usage" section lists the class methods overridden by
RSQLite.

## Usage

``` r
# S3 method for class 'SQLiteConnection'
format(x, ...)

# S4 method for class 'SQLiteConnection'
dbAppendTable(conn, name, value, ..., row.names = NULL)

# S4 method for class 'SQLiteConnection'
dbDataType(dbObj, obj, ...)

# S4 method for class 'SQLiteConnection,Id'
dbExistsTable(conn, name, ...)

# S4 method for class 'SQLiteConnection,character'
dbExistsTable(conn, name, ...)

# S4 method for class 'SQLiteConnection'
dbGetException(conn, ...)

# S4 method for class 'SQLiteConnection'
dbGetInfo(dbObj, ...)

# S4 method for class 'SQLiteConnection'
dbIsValid(dbObj, ...)

# S4 method for class 'SQLiteConnection'
dbListObjects(conn, prefix = NULL, ...)

# S4 method for class 'SQLiteConnection'
dbListTables(conn, ...)

# S4 method for class 'SQLiteConnection,SQL'
dbQuoteIdentifier(conn, x, ...)

# S4 method for class 'SQLiteConnection,character'
dbQuoteIdentifier(conn, x, ...)

# S4 method for class 'SQLiteConnection,character'
dbRemoveTable(conn, name, ..., temporary = FALSE, fail_if_missing = TRUE)

# S4 method for class 'SQLiteConnection,character'
dbSendQuery(conn, statement, params = NULL, ...)

# S4 method for class 'SQLiteConnection,SQL'
dbUnquoteIdentifier(conn, x, ...)

# S4 method for class 'SQLiteConnection'
show(object)

# S4 method for class 'SQLiteConnection'
sqlData(con, value, row.names = FALSE, ...)
```

## Arguments

- temporary:

  If `TRUE`, only temporary tables are considered.

- fail_if_missing:

  If `FALSE`,
  [`dbRemoveTable()`](https://dbi.r-dbi.org/reference/dbRemoveTable.html)
  succeeds if the table doesn't exist.

## Value

[`format()`](https://rdrr.io/r/base/format.html) returns a character
string.
[`dbAppendTable()`](https://dbi.r-dbi.org/reference/dbAppendTable.html)
returns the number of rows appended.
[`dbDataType()`](https://dbi.r-dbi.org/reference/dbDataType.html)
returns a character vector of SQL data types.
[`dbExistsTable()`](https://dbi.r-dbi.org/reference/dbExistsTable.html)
and [`dbIsValid()`](https://dbi.r-dbi.org/reference/dbIsValid.html)
return a logical scalar.
[`dbGetException()`](https://dbi.r-dbi.org/reference/dbGetException.html)
returns a list with elements `errorNum` and `errorMsg`.
[`dbGetInfo()`](https://dbi.r-dbi.org/reference/dbGetInfo.html) returns
a named list.
[`dbListObjects()`](https://dbi.r-dbi.org/reference/dbListObjects.html)
returns a data frame with columns `table` and `is_prefix`.
[`dbListTables()`](https://dbi.r-dbi.org/reference/dbListTables.html)
returns a character vector.
[`dbQuoteIdentifier()`](https://dbi.r-dbi.org/reference/dbQuoteIdentifier.html)
returns an [SQL](https://dbi.r-dbi.org/reference/SQL.html) object.
[`dbRemoveTable()`](https://dbi.r-dbi.org/reference/dbRemoveTable.html)
returns `TRUE`, invisibly.
[`dbSendQuery()`](https://dbi.r-dbi.org/reference/dbSendQuery.html)
returns an object of class
[SQLiteResult](https://rsqlite.r-dbi.org/dev/reference/SQLiteResult-class.md).
[`dbUnquoteIdentifier()`](https://dbi.r-dbi.org/reference/dbUnquoteIdentifier.html)
returns a list of [Id](https://dbi.r-dbi.org/reference/Id.html) objects.
[`show()`](https://rdrr.io/r/methods/show.html) is called for its side
effect of printing and returns `NULL`.
[`sqlData()`](https://dbi.r-dbi.org/reference/sqlData.html) returns a
data frame with character columns quoted as SQL strings.

## See also

The corresponding generic functions
[`DBI::dbSendQuery()`](https://dbi.r-dbi.org/reference/dbSendQuery.html),
[`DBI::dbGetQuery()`](https://dbi.r-dbi.org/reference/dbGetQuery.html),
[`DBI::dbSendStatement()`](https://dbi.r-dbi.org/reference/dbSendStatement.html),
[`DBI::dbExecute()`](https://dbi.r-dbi.org/reference/dbExecute.html),
[`DBI::dbExistsTable()`](https://dbi.r-dbi.org/reference/dbExistsTable.html),
[`DBI::dbListTables()`](https://dbi.r-dbi.org/reference/dbListTables.html),
[`DBI::dbListFields()`](https://dbi.r-dbi.org/reference/dbListFields.html),
[`DBI::dbRemoveTable()`](https://dbi.r-dbi.org/reference/dbRemoveTable.html),
and [`DBI::sqlData()`](https://dbi.r-dbi.org/reference/sqlData.html).
