# Class SQLiteDriver (and methods)

SQLiteDriver objects are created by
[`SQLite()`](https://rsqlite.r-dbi.org/dev/reference/SQLite.md), and
used to select the correct method in
[`DBI::dbConnect()`](https://dbi.r-dbi.org/reference/dbConnect.html).
They are a superclass of the
[DBI::DBIDriver](https://dbi.r-dbi.org/reference/DBIDriver-class.html)
class, and used purely for dispatch. The "Usage" section lists the class
methods overridden by RSQLite. The
[`DBI::dbUnloadDriver()`](https://dbi.r-dbi.org/reference/dbDriver.html)
method is a null-op.

## Usage

``` r
# S4 method for class 'SQLiteDriver'
dbDataType(dbObj, obj, ..., extended_types = FALSE)

# S4 method for class 'SQLiteDriver'
dbGetInfo(dbObj, ...)

# S4 method for class 'SQLiteDriver'
dbIsValid(dbObj, ...)

# S4 method for class 'SQLiteDriver'
dbUnloadDriver(drv, ...)
```
