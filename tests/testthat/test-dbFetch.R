context("dbFetch")

test_that("fetch with no arguments gets all rows", {
  con <- dbConnect(SQLite())
  
  df <- data.frame(x = 1:1000)
  dbWriteTable(con, "test", df)
  
  rs <- dbSendQuery(con, "SELECT * FROM test")
  expect_equal(nrow(dbFetch(rs)), 1000)
})

test_that("fetch progressively pulls in rows", {
  con <- dbConnect(SQLite())
  
  df <- data.frame(x = 1:25)
  dbWriteTable(con, "test", df)
  
  rs <- dbSendQuery(con, "SELECT * FROM test")
  expect_equal(nrow(dbFetch(rs, 10)), 10)
  expect_equal(nrow(dbFetch(rs, 10)), 10)
  expect_equal(nrow(dbFetch(rs, 10)), 5)
})