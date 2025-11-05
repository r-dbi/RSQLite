# Make R/S-Plus identifiers into legal SQL identifiers

Deprecated. Please use
[`DBI::dbQuoteIdentifier()`](https://dbi.r-dbi.org/reference/dbQuoteIdentifier.html)
instead.

## Usage

``` r
# S4 method for class 'SQLiteConnection'
SQLKeywords(dbObj, ...)

# S4 method for class 'SQLiteConnection,character'
isSQLKeyword(
  dbObj,
  name,
  keywords = .SQL92Keywords,
  case = c("lower", "upper", "any")[3],
  ...
)

# S4 method for class 'SQLiteConnection,character'
make.db.names(
  dbObj,
  snames,
  keywords = .SQL92Keywords,
  unique = TRUE,
  allow.keywords = TRUE,
  ...
)
```
