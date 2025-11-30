# Add useful extension functions

Several extension functions are included in the RSQLite package. When
enabled via `initExtension()`, these extension functions can be used in
SQL queries. Extensions must be enabled separately for each connection.

## Usage

``` r
initExtension(db, extension = c("math", "regexp", "series", "csv", "uuid"))
```

## Arguments

- db:

  A
  [`SQLiteConnection`](https://rsqlite.r-dbi.org/reference/SQLiteConnection-class.md)
  object to load these extensions into.

- extension:

  The extension to load.

## Details

The `"math"` extension functions are written by Liam Healy and made
available through the SQLite website
(<https://www.sqlite.org/src/ext/contrib>). This package contains a
slightly modified version of the original code. See the section
"Available functions in the math extension" for details.

The `"regexp"` extension provides a regular-expression matcher for POSIX
extended regular expressions, as available through the SQLite source
code repository
(<https://sqlite.org/src/file?filename=ext/misc/regexp.c>). SQLite will
then implement the `A regexp B` operator, where `A` is the string to be
matched and `B` is the regular expression.

The `"series"` extension loads the table-valued function
`generate_series()`, as available through the SQLite source code
repository (<https://sqlite.org/src/file?filename=ext/misc/series.c>).

The `"csv"` extension loads the function `csv()` that can be used to
create virtual tables, as available through the SQLite source code
repository (<https://sqlite.org/src/file?filename=ext/misc/csv.c>).

The `"uuid"` extension loads the functions `uuid()`, `uuid_str(X)` and
`uuid_blob(X)` that can be used to create universally unique
identifiers, as available through the SQLite source code repository
(<https://sqlite.org/src/file?filename=ext/misc/uuid.c>).

## Available functions in the math extension

- Math functions:

  acos, acosh, asin, asinh, atan, atan2, atanh, atn2, ceil, cos, cosh,
  cot, coth, degrees, difference, exp, floor, log, log10, pi, power,
  radians, sign, sin, sinh, sqrt, square, tan, tanh

- String functions:

  charindex, leftstr, ltrim, padc, padl, padr, proper, replace,
  replicate, reverse, rightstr, rtrim, strfilter, trim

- Aggregate functions:

  stdev, variance, mode, median, lower_quartile, upper_quartile

## Examples

``` r
library(DBI)
db <- RSQLite::datasetsDb()

# math
RSQLite::initExtension(db)
dbGetQuery(db, "SELECT stdev(mpg) FROM mtcars")
#>   stdev(mpg)
#> 1   6.026948
sd(mtcars$mpg)
#> [1] 6.026948

# regexp
RSQLite::initExtension(db, "regexp")
dbGetQuery(db, "SELECT * FROM mtcars WHERE carb REGEXP '[12]'")
#>            row_names  mpg cyl  disp  hp drat    wt  qsec vs am gear carb
#> 1         Datsun 710 22.8   4 108.0  93 3.85 2.320 18.61  1  1    4    1
#> 2     Hornet 4 Drive 21.4   6 258.0 110 3.08 3.215 19.44  1  0    3    1
#> 3  Hornet Sportabout 18.7   8 360.0 175 3.15 3.440 17.02  0  0    3    2
#> 4            Valiant 18.1   6 225.0 105 2.76 3.460 20.22  1  0    3    1
#> 5          Merc 240D 24.4   4 146.7  62 3.69 3.190 20.00  1  0    4    2
#> 6           Merc 230 22.8   4 140.8  95 3.92 3.150 22.90  1  0    4    2
#> 7           Fiat 128 32.4   4  78.7  66 4.08 2.200 19.47  1  1    4    1
#> 8        Honda Civic 30.4   4  75.7  52 4.93 1.615 18.52  1  1    4    2
#> 9     Toyota Corolla 33.9   4  71.1  65 4.22 1.835 19.90  1  1    4    1
#> 10     Toyota Corona 21.5   4 120.1  97 3.70 2.465 20.01  1  0    3    1
#> 11  Dodge Challenger 15.5   8 318.0 150 2.76 3.520 16.87  0  0    3    2
#> 12       AMC Javelin 15.2   8 304.0 150 3.15 3.435 17.30  0  0    3    2
#> 13  Pontiac Firebird 19.2   8 400.0 175 3.08 3.845 17.05  0  0    3    2
#> 14         Fiat X1-9 27.3   4  79.0  66 4.08 1.935 18.90  1  1    4    1
#> 15     Porsche 914-2 26.0   4 120.3  91 4.43 2.140 16.70  0  1    5    2
#> 16      Lotus Europa 30.4   4  95.1 113 3.77 1.513 16.90  1  1    5    2
#> 17        Volvo 142E 21.4   4 121.0 109 4.11 2.780 18.60  1  1    4    2

# series
RSQLite::initExtension(db, "series")
dbGetQuery(db, "SELECT value FROM generate_series(0, 20, 5);")
#>   value
#> 1     0
#> 2     5
#> 3    10
#> 4    15
#> 5    20

dbDisconnect(db)

# csv
db <- dbConnect(RSQLite::SQLite())
RSQLite::initExtension(db, "csv")
# use the filename argument to mount CSV files from disk
sql <- paste0(
  "CREATE VIRTUAL TABLE tbl USING ",
  "csv(data='1,2', schema='CREATE TABLE x(a INT, b INT)')"
)
dbExecute(db, sql)
#> [1] 0
dbGetQuery(db, "SELECT * FROM tbl")
#>   a b
#> 1 1 2

# uuid
db <- dbConnect(RSQLite::SQLite())
RSQLite::initExtension(db, "uuid")
dbGetQuery(db, "SELECT uuid();")
#>                                 uuid()
#> 1 b44446b4-95b4-4ab3-af0c-e8a275a3ad53
dbDisconnect(db)
```
