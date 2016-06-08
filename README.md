# RSQLite

[![Build Status](https://travis-ci.org/rstats-db/RSQLite.png?branch=master)](https://travis-ci.org/rstats-db/RSQLite) [![AppVeyor Build Status](https://ci.appveyor.com/api/projects/status/github/rstats-db/RSQLite?branch=master&svg=true)](https://ci.appveyor.com/project/rstats-db/RSQLite) [![Coverage Status](https://img.shields.io/codecov/c/github/rstats-db/RSQLite/master.svg)](https://codecov.io/github/rstats-db/RSQLite?branch=master)


RSQLite embeds the SQLite database engine in R, providing a DBI-compliant interface. [SQLite](http://www.sqlite.org) is a public-domain, single-user, very light-weight database engine that implements a decent subset of the SQL 92 standard, including the core table creation, updating, insertion, and selection operations, plus transaction management.

You can install the latest released version from CRAN with:

```R
install.packages("RSQLite")
```

Or install the latest development version from github with:

```R
# install.packages("devtools")
devtools::install_github("RcppCore/Rcpp")
devtools::install_github("rstats-db/DBI")
devtools::install_github("rstats-db/RSQLite")
```

To install from github, you'll need a [development environment](http://www.rstudio.com/ide/docs/packages/prerequisites).

## Basic usage

```R
library(DBI)
# Create an ephemeral in-memory RSQLite database
con <- dbConnect(RSQLite::SQLite(), "file::memory:")

dbListTables(con)
dbWriteTable(con, "mtcars", mtcars)
dbListTables(con)

dbListFields(con, "mtcars")
dbReadTable(con, "mtcars")

# You can fetch all results:
res <- dbSendQuery(con, "SELECT * FROM mtcars WHERE cyl = 4")
dbFetch(res)
dbClearResult(res)

# Or a chunk at a time
res <- dbSendQuery(con, "SELECT * FROM mtcars WHERE cyl = 4")
while(!dbHasCompleted(res)){
  chunk <- dbFetch(res, n = 5)
  print(nrow(chunk))
}
# Clear the result
dbClearResult(res)

# Disconnect from the database
dbDisconnect(con)
```

## Acknowledgements

Many thanks to Doug Bates, Seth Falcon, Detlef Groth, Ronggui Huang, Kurt Hornik, Uwe Ligges, Charles Loboz, Duncan Murdoch, and Brian D. Ripley for comments, suggestions, bug reports, and/or patches.

## Update version of SQLite

1.  Download latest SQLite source by running `src-raw/upgrade.R`

1.  Update `DESCRIPTION` for included version of SQLite

1.  Update `NEWS`

Ideally this should happen right *after* each CRAN release, so that a new SQLite version is tested for some time before it's released to CRAN.

## Update datasets database

RSQLite includes one SQLite database (accessible from `datasetsDb()` that contains all data frames in the datasets package. This is the code that created it.

```R
tables <- unique(data(package = "datasets")$results[, 3])
tables <- tables[!grepl("(", tables, fixed = TRUE)]

con <- dbConnect(SQLite(), "inst/db/datasets.sqlite")
for(table in tables) {
  df <- getExportedValue("datasets", table)
  if (!is.data.frame(df)) next
  
  message("Creating table: ", table)
  dbWriteTable(con, table, as.data.frame(df), overwrite = TRUE)
}
```
