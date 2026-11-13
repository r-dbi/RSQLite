# A database with a table `t1` of six rows whose fifth is not valid JSON,
# so that `json(v)` fails at row 5 of a result.
# The connection is closed when `frame` exits.
local_json_error_at_5 <- function(frame = parent.frame()) {
  con <- dbConnect(SQLite(), ":memory:")
  withr::defer(dbDisconnect(con), envir = frame)
  df <- data.frame(id = 1:6, v = c("[1]", "[2]", "[3]", "[4]", "oops", "[6]"))
  dbWriteTable(con, "t1", df)
  con
}
