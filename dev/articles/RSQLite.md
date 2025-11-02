# RSQLite

RSQLite is the easiest way to use a database from R because the package
itself contains [SQLite](https://www.sqlite.org/index.html); no external
software is needed. This vignette will walk you through the basics of
using a SQLite database.

RSQLite is a DBI-compatible interface which means you primarily use
functions defined in the DBI package, so you should always start by
loading DBI, not RSQLite:

``` r
library(DBI)
```

## Creating a new database

To create a new SQLite database, you simply supply the filename to
[`dbConnect()`](https://dbi.r-dbi.org/reference/dbConnect.html):

``` r
mydb <- dbConnect(RSQLite::SQLite(), "my-db.sqlite")
dbDisconnect(mydb)
```

If you just need a temporary database, use either `""` (for an on-disk
database) or `":memory:"` or `"file::memory:"` (for a in-memory
database). This database will be automatically deleted when you
disconnect from it.

``` r
mydb <- dbConnect(RSQLite::SQLite(), "")
dbDisconnect(mydb)
```

## Loading data

You can easily copy an R data frame into a SQLite database with
[`dbWriteTable()`](https://dbi.r-dbi.org/reference/dbWriteTable.html):

``` r
mydb <- dbConnect(RSQLite::SQLite(), "")
dbWriteTable(mydb, "mtcars", mtcars)
dbWriteTable(mydb, "iris", iris)
dbListTables(mydb)
#> [1] "iris"   "mtcars"
```

## Queries

Issue a query with
[`dbGetQuery()`](https://dbi.r-dbi.org/reference/dbGetQuery.html):

``` r
dbGetQuery(mydb, 'SELECT * FROM mtcars LIMIT 5')
#>    mpg cyl disp  hp drat    wt  qsec vs am gear carb
#> 1 21.0   6  160 110 3.90 2.620 16.46  0  1    4    4
#> 2 21.0   6  160 110 3.90 2.875 17.02  0  1    4    4
#> 3 22.8   4  108  93 3.85 2.320 18.61  1  1    4    1
#> 4 21.4   6  258 110 3.08 3.215 19.44  1  0    3    1
#> 5 18.7   8  360 175 3.15 3.440 17.02  0  0    3    2
```

Not all R variable names are valid SQL variable names, so you may need
to escape them with `"`:

``` r
dbGetQuery(mydb, 'SELECT * FROM iris WHERE "Sepal.Length" < 4.6')
#>   Sepal.Length Sepal.Width Petal.Length Petal.Width Species
#> 1          4.4         2.9          1.4         0.2  setosa
#> 2          4.3         3.0          1.1         0.1  setosa
#> 3          4.4         3.0          1.3         0.2  setosa
#> 4          4.5         2.3          1.3         0.3  setosa
#> 5          4.4         3.2          1.3         0.2  setosa
```

If you need to insert the value from a user into a query, don’t use
[`paste()`](https://rdrr.io/r/base/paste.html)! That makes it easy for a
malicious attacker to insert SQL that might damage your database or
reveal sensitive information. Instead, use a parameterised query:

``` r
dbGetQuery(mydb, 'SELECT * FROM iris WHERE "Sepal.Length" < :x',
  params = list(x = 4.6))
#>   Sepal.Length Sepal.Width Petal.Length Petal.Width Species
#> 1          4.4         2.9          1.4         0.2  setosa
#> 2          4.3         3.0          1.1         0.1  setosa
#> 3          4.4         3.0          1.3         0.2  setosa
#> 4          4.5         2.3          1.3         0.3  setosa
#> 5          4.4         3.2          1.3         0.2  setosa
```

This is a little more typing, but much much safer.

## Batched queries

If you run a query and the results don’t fit in memory, you can use
[`dbSendQuery()`](https://dbi.r-dbi.org/reference/dbSendQuery.html),
[`dbFetch()`](https://dbi.r-dbi.org/reference/dbFetch.html) and
`dbClearResults()` to retrieve the results in batches. By default
[`dbFetch()`](https://dbi.r-dbi.org/reference/dbFetch.html) will
retrieve all available rows: use `n` to set the maximum number of rows
to return.

``` r
rs <- dbSendQuery(mydb, 'SELECT * FROM mtcars')
while (!dbHasCompleted(rs)) {
  df <- dbFetch(rs, n = 10)
  print(nrow(df))
}
#> [1] 10
#> [1] 10
#> [1] 10
#> [1] 2
dbClearResult(rs)
```

## Multiple parameterised queries

You can use the same approach to run the same parameterised query with
different parameters. Call
[`dbBind()`](https://dbi.r-dbi.org/reference/dbBind.html) to set the
parameters:

``` r
rs <- dbSendQuery(mydb, 'SELECT * FROM iris WHERE "Sepal.Length" < :x')
dbBind(rs, params = list(x = 4.5))
nrow(dbFetch(rs))
#> [1] 4
dbBind(rs, params = list(x = 4))
nrow(dbFetch(rs))
#> [1] 0
dbClearResult(rs)
```

You can also pass multiple parameters in one call to
[`dbBind()`](https://dbi.r-dbi.org/reference/dbBind.html):

``` r
rs <- dbSendQuery(mydb, 'SELECT * FROM iris WHERE "Sepal.Length" = :x')
dbBind(rs, params = list(x = seq(4, 4.4, by = 0.1)))
nrow(dbFetch(rs))
#> [1] 4
dbClearResult(rs)
```

## Statements

DBI has new functions
[`dbSendStatement()`](https://dbi.r-dbi.org/reference/dbSendStatement.html)
and [`dbExecute()`](https://dbi.r-dbi.org/reference/dbExecute.html),
which are the counterparts of
[`dbSendQuery()`](https://dbi.r-dbi.org/reference/dbSendQuery.html) and
[`dbGetQuery()`](https://dbi.r-dbi.org/reference/dbGetQuery.html) for
SQL statements that do not return a tabular result, such as inserting
records into a table, updating a table, or setting engine parameters. It
is good practice, although currently not enforced, to use the new
functions when you don’t expect a result.

``` r
dbExecute(mydb, 'DELETE FROM iris WHERE "Sepal.Length" < 4')
#> [1] 0
rs <- dbSendStatement(mydb, 'DELETE FROM iris WHERE "Sepal.Length" < :x')
dbBind(rs, params = list(x = 4.5))
dbGetRowsAffected(rs)
#> [1] 4
dbClearResult(rs)
```
