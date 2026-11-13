# A database with a table `t1` of five rows,
# for the tests of `dbGetPreparedQuery()` with one row per bound select
bind_select_setup <- function() {
  con <- dbConnect(SQLite())

  df <- data.frame(
    id = letters[1:5],
    x = 1:5,
    y = c(1L, 1L, 2L, 2L, 3L),
    stringsAsFactors = FALSE
  )

  dbWriteTable(con, "t1", df, row.names = FALSE)
  con
}
