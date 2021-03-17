library(RSQLite)

con <- DBI::dbConnect(SQLite(), dbname = "${1:File name}")

## Adding a table to the empty database
# DBI::dbWriteTable(con, "iris", iris)

## Disconnecting...
# DBI::dbDisconnect(con)
