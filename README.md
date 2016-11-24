
<!-- README.md is generated from README.Rmd. Please edit that file -->
RSQLite
=======

[![Build Status](https://travis-ci.org/rstats-db/RSQLite.png?branch=master)](https://travis-ci.org/rstats-db/RSQLite) [![AppVeyor Build Status](https://ci.appveyor.com/api/projects/status/github/rstats-db/RSQLite?branch=master&svg=true)](https://ci.appveyor.com/project/rstats-db/RSQLite) [![Coverage Status](https://img.shields.io/codecov/c/github/rstats-db/RSQLite/master.svg)](https://codecov.io/github/rstats-db/RSQLite?branch=master)

Embeds the SQLite database engine in R, providing a DBI-compliant interface. [SQLite](http://www.sqlite.org) is a public-domain, single-user, very light-weight database engine that implements a decent subset of the SQL 92 standard, including the core table creation, updating, insertion, and selection operations, plus transaction management.

You can install the latest released version from CRAN with:

``` r
install.packages("RSQLite")
```

Or install the latest development version from GitHub with:

``` r
# install.packages("devtools")
devtools::install_github("rstats-db/RSQLite")
```

To install from GitHub, you'll need a [development environment](http://www.rstudio.com/ide/docs/packages/prerequisites).

Basic usage
-----------

``` r
library(DBI)
# Create an ephemeral in-memory RSQLite database
con <- dbConnect(RSQLite::SQLite(), ":memory:")

dbListTables(con)
```

    ## character(0)

``` r
dbWriteTable(con, "mtcars", mtcars)
```

    ## [1] TRUE

``` r
dbListTables(con)
```

    ## [1] "mtcars"

``` r
dbListFields(con, "mtcars")
```

    ##  [1] "row_names" "mpg"       "cyl"       "disp"      "hp"       
    ##  [6] "drat"      "wt"        "qsec"      "vs"        "am"       
    ## [11] "gear"      "carb"

``` r
dbReadTable(con, "mtcars")
```

    ##                      mpg cyl  disp  hp drat    wt  qsec vs am gear carb
    ## Mazda RX4           21.0   6 160.0 110 3.90 2.620 16.46  0  1    4    4
    ## Mazda RX4 Wag       21.0   6 160.0 110 3.90 2.875 17.02  0  1    4    4
    ## Datsun 710          22.8   4 108.0  93 3.85 2.320 18.61  1  1    4    1
    ## Hornet 4 Drive      21.4   6 258.0 110 3.08 3.215 19.44  1  0    3    1
    ## Hornet Sportabout   18.7   8 360.0 175 3.15 3.440 17.02  0  0    3    2
    ## Valiant             18.1   6 225.0 105 2.76 3.460 20.22  1  0    3    1
    ## Duster 360          14.3   8 360.0 245 3.21 3.570 15.84  0  0    3    4
    ## Merc 240D           24.4   4 146.7  62 3.69 3.190 20.00  1  0    4    2
    ## Merc 230            22.8   4 140.8  95 3.92 3.150 22.90  1  0    4    2
    ##  [ reached getOption("max.print") -- omitted 23 rows ]

``` r
# You can fetch all results:
res <- dbSendQuery(con, "SELECT * FROM mtcars WHERE cyl = 4")
dbFetch(res)
```

    ##                 mpg cyl  disp  hp drat    wt  qsec vs am gear carb
    ## Datsun 710     22.8   4 108.0  93 3.85 2.320 18.61  1  1    4    1
    ## Merc 240D      24.4   4 146.7  62 3.69 3.190 20.00  1  0    4    2
    ## Merc 230       22.8   4 140.8  95 3.92 3.150 22.90  1  0    4    2
    ## Fiat 128       32.4   4  78.7  66 4.08 2.200 19.47  1  1    4    1
    ## Honda Civic    30.4   4  75.7  52 4.93 1.615 18.52  1  1    4    2
    ## Toyota Corolla 33.9   4  71.1  65 4.22 1.835 19.90  1  1    4    1
    ## Toyota Corona  21.5   4 120.1  97 3.70 2.465 20.01  1  0    3    1
    ## Fiat X1-9      27.3   4  79.0  66 4.08 1.935 18.90  1  1    4    1
    ## Porsche 914-2  26.0   4 120.3  91 4.43 2.140 16.70  0  1    5    2
    ##  [ reached getOption("max.print") -- omitted 2 rows ]

``` r
dbClearResult(res)
```

    ## [1] TRUE

``` r
# Or a chunk at a time
res <- dbSendQuery(con, "SELECT * FROM mtcars WHERE cyl = 4")
while(!dbHasCompleted(res)){
  chunk <- dbFetch(res, n = 5)
  print(nrow(chunk))
}
```

    ## [1] 5
    ## [1] 5
    ## [1] 1

``` r
# Clear the result
dbClearResult(res)
```

    ## [1] TRUE

``` r
# Disconnect from the database
dbDisconnect(con)
```

    ## [1] TRUE

Acknowledgements
----------------

Many thanks to Doug Bates, Seth Falcon, Detlef Groth, Ronggui Huang, Kurt Hornik, Uwe Ligges, Charles Loboz, Duncan Murdoch, and Brian D. Ripley for comments, suggestions, bug reports, and/or patches.
