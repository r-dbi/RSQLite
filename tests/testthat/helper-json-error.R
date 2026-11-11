# A database with a table `t1` whose third row is not valid JSON,
# so that `json(v)` fails in the middle of a result
json_error_setup <- function() {
  con <- dbConnect(SQLite(), ":memory:")
  df <- data.frame(id = 1:4, v = c("[1]", "[2]", "oops", "[4]"))
  dbWriteTable(con, "t1", df)
  con
}
