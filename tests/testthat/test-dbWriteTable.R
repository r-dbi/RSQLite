context("dbWriteTable")

# Not generic enough for DBItest
test_that("throws error if constraint violated", {
  con <- dbConnect(SQLite())

  x <- data.frame(col1 = 1:10, col2 = letters[1:10])

  dbWriteTable(con, "t1", x)
  dbGetQuery(con, "CREATE UNIQUE INDEX t1_c1_c2_idx ON t1(col1, col2)")
  expect_error(dbWriteTable(con, "t1", x, append = TRUE),
    "UNIQUE constraint failed")
})

# Test requires that two result sets can be open at the same time, which is
# undesired (see DBItest "stale_result_warning")
test_that("modifications retrieved by open result set", {
  con <- dbConnect(SQLite(), tempfile())

  x <- data.frame(col1 = 1:10, col2 = letters[1:10])
  dbWriteTable(con, "t1", x)

  res <- dbSendQuery(con, "SELECT * FROM t1")
  dbWriteTable(con, "t1", x, append = TRUE)
  expect_equal(nrow(dbFetch(res)), 20)
  dbClearResult(res)
})
