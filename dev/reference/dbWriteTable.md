# Write a local data frame or file to the database

Functions for writing data frames or delimiter-separated files to
database tables.

## Usage

``` r
# S4 method for class 'SQLiteConnection,character,character'
dbWriteTable(
  conn,
  name,
  value,
  ...,
  field.types = NULL,
  overwrite = FALSE,
  append = FALSE,
  header = TRUE,
  colClasses = NA,
  row.names = FALSE,
  nrows = 50,
  sep = ",",
  eol = "\n",
  skip = 0,
  temporary = FALSE
)

# S4 method for class 'SQLiteConnection,character,data.frame'
dbWriteTable(
  conn,
  name,
  value,
  ...,
  row.names = pkgconfig::get_config("RSQLite::row.names.table", FALSE),
  overwrite = FALSE,
  append = FALSE,
  field.types = NULL,
  temporary = FALSE
)
```

## Arguments

- conn:

  a
  [`SQLiteConnection`](https://rsqlite.r-dbi.org/dev/reference/SQLiteConnection-class.md)
  object, produced by
  [`DBI::dbConnect()`](https://dbi.r-dbi.org/reference/dbConnect.html)

- name:

  a character string specifying a table name. SQLite table names are
  *not* case sensitive, e.g., table names `ABC` and `abc` are considered
  equal.

- value:

  a data.frame (or coercible to data.frame) object or a file name
  (character). In the first case, the data.frame is written to a
  temporary file and then imported to SQLite; when `value` is a
  character, it is interpreted as a file name and its contents imported
  to SQLite.

- ...:

  Needed for compatibility with generic. Otherwise ignored.

- field.types:

  character vector of named SQL field types where the names are the
  names of new table's columns. If missing, types inferred with
  [`DBI::dbDataType()`](https://dbi.r-dbi.org/reference/dbDataType.html)).

- overwrite:

  a logical specifying whether to overwrite an existing table or not.
  Its default is `FALSE`.

- append:

  a logical specifying whether to append to an existing table in the
  DBMS. Its default is `FALSE`.

- header:

  is a logical indicating whether the first data line (but see `skip`)
  has a header or not. If missing, it value is determined following
  [`read.table()`](https://rdrr.io/r/utils/read.table.html) convention,
  namely, it is set to TRUE if and only if the first row has one fewer
  field that the number of columns.

- colClasses:

  Character vector of R type names, used to override defaults when
  imputing classes from on-disk file.

- row.names:

  A logical specifying whether the `row.names` should be output to the
  output DBMS table; if `TRUE`, an extra field whose name will be
  whatever the R identifier `"row.names"` maps to the DBMS (see
  [`DBI::make.db.names()`](https://dbi.r-dbi.org/reference/make.db.names.html)).
  If `NA` will add rows names if they are characters, otherwise will
  ignore.

- nrows:

  Number of rows to read to determine types.

- sep:

  The field separator, defaults to `','`.

- eol:

  The end-of-line delimiter, defaults to `'\n'`.

- skip:

  number of lines to skip before reading the data. Defaults to 0.

- temporary:

  a logical specifying whether the new table should be temporary. Its
  default is `FALSE`.

## Details

In a primary key column qualified with
[`AUTOINCREMENT`](https://www.sqlite.org/autoinc.html), missing values
will be assigned the next largest positive integer, while nonmissing
elements/cells retain their value. If the autoincrement column exists in
the data frame passed to the `value` argument, the `NA` elements are
overwritten. Similarly, if the key column is not present in the data
frame, all elements are automatically assigned a value.

## See also

The corresponding generic function
[`DBI::dbWriteTable()`](https://dbi.r-dbi.org/reference/dbWriteTable.html).

## Examples

``` r
con <- dbConnect(SQLite())
dbWriteTable(con, "mtcars", mtcars)
dbReadTable(con, "mtcars")
#>     mpg cyl  disp  hp drat    wt  qsec vs am gear carb
#> 1  21.0   6 160.0 110 3.90 2.620 16.46  0  1    4    4
#> 2  21.0   6 160.0 110 3.90 2.875 17.02  0  1    4    4
#> 3  22.8   4 108.0  93 3.85 2.320 18.61  1  1    4    1
#> 4  21.4   6 258.0 110 3.08 3.215 19.44  1  0    3    1
#> 5  18.7   8 360.0 175 3.15 3.440 17.02  0  0    3    2
#> 6  18.1   6 225.0 105 2.76 3.460 20.22  1  0    3    1
#> 7  14.3   8 360.0 245 3.21 3.570 15.84  0  0    3    4
#> 8  24.4   4 146.7  62 3.69 3.190 20.00  1  0    4    2
#> 9  22.8   4 140.8  95 3.92 3.150 22.90  1  0    4    2
#> 10 19.2   6 167.6 123 3.92 3.440 18.30  1  0    4    4
#> 11 17.8   6 167.6 123 3.92 3.440 18.90  1  0    4    4
#> 12 16.4   8 275.8 180 3.07 4.070 17.40  0  0    3    3
#> 13 17.3   8 275.8 180 3.07 3.730 17.60  0  0    3    3
#> 14 15.2   8 275.8 180 3.07 3.780 18.00  0  0    3    3
#> 15 10.4   8 472.0 205 2.93 5.250 17.98  0  0    3    4
#> 16 10.4   8 460.0 215 3.00 5.424 17.82  0  0    3    4
#> 17 14.7   8 440.0 230 3.23 5.345 17.42  0  0    3    4
#> 18 32.4   4  78.7  66 4.08 2.200 19.47  1  1    4    1
#> 19 30.4   4  75.7  52 4.93 1.615 18.52  1  1    4    2
#> 20 33.9   4  71.1  65 4.22 1.835 19.90  1  1    4    1
#> 21 21.5   4 120.1  97 3.70 2.465 20.01  1  0    3    1
#> 22 15.5   8 318.0 150 2.76 3.520 16.87  0  0    3    2
#> 23 15.2   8 304.0 150 3.15 3.435 17.30  0  0    3    2
#> 24 13.3   8 350.0 245 3.73 3.840 15.41  0  0    3    4
#> 25 19.2   8 400.0 175 3.08 3.845 17.05  0  0    3    2
#> 26 27.3   4  79.0  66 4.08 1.935 18.90  1  1    4    1
#> 27 26.0   4 120.3  91 4.43 2.140 16.70  0  1    5    2
#> 28 30.4   4  95.1 113 3.77 1.513 16.90  1  1    5    2
#> 29 15.8   8 351.0 264 4.22 3.170 14.50  0  1    5    4
#> 30 19.7   6 145.0 175 3.62 2.770 15.50  0  1    5    6
#> 31 15.0   8 301.0 335 3.54 3.570 14.60  0  1    5    8
#> 32 21.4   4 121.0 109 4.11 2.780 18.60  1  1    4    2

# A zero row data frame just creates a table definition.
dbWriteTable(con, "mtcars2", mtcars[0, ])
dbReadTable(con, "mtcars2")
#>  [1] mpg  cyl  disp hp   drat wt   qsec vs   am   gear carb
#> <0 rows> (or 0-length row.names)

dbDisconnect(con)
```
