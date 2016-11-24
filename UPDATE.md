# Update version of SQLite

1.  Download latest SQLite source by running `src-raw/upgrade.R`

1.  Update `DESCRIPTION` for included version of SQLite

1.  Update `NEWS`

Ideally this should happen right *after* each CRAN release, so that a new SQLite version is tested for some time before it's released to CRAN.

# Update datasets database

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
