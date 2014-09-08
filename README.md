# RSQLite

[![Build Status](https://travis-ci.org/rstats-db/RSQLite.png?branch=master)](https://travis-ci.org/rstats-db/RSQLite)

RSQLite embeds the SQLite database engine in R, providing a DBI-compliant interface. [SQLite](http://www.sqlite.org) is a public-domain, single-user, very light-weight database engine that implements a decent subset of the SQL 92 standard, including the core table creation, updating, insertion, and selection operations, plus transaction management.

You can install the latest released version from CRAN with:

```r
install.packages("RSQLite")
```

or install the latest development version from github with:

```r
library(devtools)
install_github("RSQLite", "rstats-db")
```

To install from github, you'll need a [development environment](http://www.rstudio.com/ide/docs/packages/prerequisites)).

## Acknowledgements

Many thanks to Doug Bates, Seth Falcon, Detlef Groth, Ronggui Huang,
Kurt Hornik, Uwe Ligges, Charles Loboz, Duncan Murdoch, and Brian
D. Ripley for comments, suggestions, bug reports, and/or patches.

## Update version of SQLite

1. Download latest [amalgamation](http://sqlite.org/download.html)
2. Unzip and copy `.c` and `.h` files into `src/sqlite`. Exclude `shell.c`. 
   Currently we track three files: `sqlite3.c`, `sqlite3.h`, and `sqlite3ext.h`.
3. Update `DESCRIPTION` for included version of SQLite
4. Update `NEWS`
5. Build and check

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
