context("dbSendQuery")

test_that("can't change schema with pending rows", {
  con <- dbConnect(SQLite())
  on.exit(dbDisconnect(con))
  
  df <- data.frame(a = letters, b = LETTERS, c = 1:26, stringsAsFactors = FALSE)
  dbWriteTable(con, "t1", df)
  
  rs <- dbSendQuery(con, "SELECT * FROM t1")
  row1 <- fetch(rs, n = 1)
  expect_equal(row1, df[1, ])
  
  expect_error(dbSendQuery(con, "CREATE TABLE t2 (x text, y integer)"), 
    "pending rows")
})
