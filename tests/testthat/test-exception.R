context("exception")

test_that("no exception upon start", {
  con <- dbConnect(SQLite())
  on.exit(dbDisconnect(con), add = TRUE)
  
  ex <- dbGetException(con)
  expect_equal(ex$errorNum, 0)
  expect_equal(ex$errorMsg, "OK")
})

test_that("no exception after good query", {
  con <- dbConnect(SQLite())
  on.exit(dbDisconnect(con), add = TRUE)
  
  dbGetQuery(con, "SELECT 1")
  
  ex <- dbGetException(con)
  expect_equal(ex$errorNum, 0)
  expect_equal(ex$errorMsg, "OK")
})

test_that("exception after bad query", {
  con <- dbConnect(SQLite())
  on.exit(dbDisconnect(con), add = TRUE)
  
  expect_error(dbGetQuery(con, "RAISE"))
  
  ex <- dbGetException(con)
  expect_equal(ex$errorNum, 1)
  expect_match(ex$errorMsg, "syntax error")
})

test_that("no exception after good statement sent", {
  con <- dbConnect(SQLite())
  on.exit(dbDisconnect(con), add = TRUE)
  
  rs <- dbSendQuery(con, "SELECT 1")
  ex <- dbGetException(con)
  dbClearResult(rs)
  
  expect_equal(ex$errorNum, 0)
  expect_equal(ex$errorMsg, "OK")
})

test_that("no exception after good statement sent and partially collected", {
  con <- dbConnect(SQLite())
  on.exit(dbDisconnect(con), add = TRUE)
  
  rs <- dbSendQuery(con, "SELECT 1 UNION SELECT 2")
  dbFetch(rs, 1)
  ex <- dbGetException(con)
  dbClearResult(rs)
  
  expect_equal(ex$errorNum, 0)
  expect_equal(ex$errorMsg, "OK")
})

test_that("exception after bad statement sent", {
  con <- dbConnect(SQLite())
  on.exit(dbDisconnect(con), add = TRUE)
  
  expect_error(dbSendQuery(con, "RAISE"), "syntax error")
  ex <- dbGetException(con)
  
  expect_equal(ex$errorNum, 1)
  expect_match(ex$errorMsg, "syntax error")
})
