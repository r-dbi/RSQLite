library(RSQLite)
con <- dbConnect(SQLite())

# this is written as a temporary table
dbWriteTable(con, "BOD", BOD, row.names = FALSE, temporary = TRUE)
dbGetQuery(con, "select * from sqlite_master")
dbGetQuery(con, "select * from sqlite_temp_master")
dbRemoveTable(con, "BOD")

# this is written as an ordinary table
dbWriteTable(con, "BOD2", BOD, row.names = FALSE)
dbGetQuery(con, "select * from sqlite_master")
dbGetQuery(con, "select * from sqlite_temp_master")

