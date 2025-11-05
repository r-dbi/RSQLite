# Copy a SQLite database

Copies a database connection to a file or to another database
connection. It can be used to save an in-memory database (created using
`dbname = ":memory:"` or `dbname = "file::memory:"`) to a file or to
create an in-memory database a copy of another database.

## Usage

``` r
sqliteCopyDatabase(from, to)
```

## Arguments

- from:

  A `SQLiteConnection` object. The main database in `from` will be
  copied to `to`.

- to:

  A `SQLiteConnection` object pointing to an empty database.

## References

<https://www.sqlite.org/backup.html>

## Author

Seth Falcon

## Examples

``` r
library(DBI)
# Copy the built in databaseDb() to an in-memory database
con <- dbConnect(RSQLite::SQLite(), ":memory:")
dbListTables(con)
#> character(0)

db <- RSQLite::datasetsDb()
RSQLite::sqliteCopyDatabase(db, con)
dbDisconnect(db)
dbListTables(con)
#>  [1] "BOD"              "CO2"              "ChickWeight"      "DNase"           
#>  [5] "Formaldehyde"     "Indometh"         "InsectSprays"     "LifeCycleSavings"
#>  [9] "Loblolly"         "Orange"           "OrchardSprays"    "PlantGrowth"     
#> [13] "Puromycin"        "Theoph"           "ToothGrowth"      "USArrests"       
#> [17] "USJudgeRatings"   "airquality"       "anscombe"         "attenu"          
#> [21] "attitude"         "cars"             "chickwts"         "esoph"           
#> [25] "faithful"         "freeny"           "infert"           "iris"            
#> [29] "longley"          "morley"           "mtcars"           "npk"             
#> [33] "pressure"         "quakes"           "randu"            "rock"            
#> [37] "sleep"            "stackloss"        "swiss"            "trees"           
#> [41] "warpbreaks"       "women"           

dbDisconnect(con)
```
