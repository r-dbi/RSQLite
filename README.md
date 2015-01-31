# RSQLite

[![Build Status](https://travis-ci.org/rstats-db/RSQLite.png?branch=master)](https://travis-ci.org/rstats-db/RSQLite)

RSQLite embeds the SQLite database engine in R, providing a DBI-compliant interface. [SQLite](http://www.sqlite.org) is a public-domain, single-user, very light-weight database engine that implements a decent subset of the SQL 92 standard, including the core table creation, updating, insertion, and selection operations, plus transaction management.

You can install the latest released version from CRAN with:

```R
install.packages("RSQLite")
```

Or install the latest development version from github with:

```R
# install.packages("devtools")
devtools::install_github("rstats-db/DBI")
devtools::install_github("rstats-db/SQL")
devtools::install_github("rstats-db/RSQLite")
```

To install from github, you'll need a [development environment](http://www.rstudio.com/ide/docs/packages/prerequisites).

## Basic usage

```R
library(DBI)
# Create an ephemeral in-memory RSQLite database
con <- dbConnect(RSQLite::SQLite(), ":memory:")

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

1.  Download latest SQLite source

    ```R
    latest <- "http://www.sqlite.org/2015/sqlite-amalgamation-3080802.zip"
    tmp <- tempfile()
    download.file(latest, tmp)
    unzip(tmp, exdir = "src/", junkpaths = TRUE)
    unlink("src/shell.c")
    ```
1.  Update `DESCRIPTION` for included version of SQLite

1.  Update `NEWS`

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
