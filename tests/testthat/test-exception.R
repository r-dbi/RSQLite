context("exception")

test_that("no exception upon start", {
  con <- dbConnect(SQLite())
  on.exit(dbDisconnect(con), add = TRUE)

  expect_warning(ex <- dbGetException(con), "deprecated")
  expect_equal(ex$errorNum, 0)
  expect_equal(ex$errorMsg, "OK")
})

test_that("no exception after good query", {
  memoise::forget(warning_once)
  con <- dbConnect(SQLite())
  on.exit(dbDisconnect(con), add = TRUE)

  dbGetQuery(con, "SELECT 1")

  expect_warning(ex <- dbGetException(con), "deprecated")
  expect_equal(ex$errorNum, 0)
  expect_equal(ex$errorMsg, "OK")
})

test_that("exception after bad query", {
  memoise::forget(warning_once)
  con <- dbConnect(SQLite())
  on.exit(dbDisconnect(con), add = TRUE)

  expect_error(dbExecute(con, "RAISE"))

  expect_warning(ex <- dbGetException(con), "deprecated")
  expect_equal(ex$errorNum, 0)
  expect_match(ex$errorMsg, "OK")
})

test_that("no exception after good statement sent", {
  memoise::forget(warning_once)
  con <- dbConnect(SQLite())
  on.exit(dbDisconnect(con), add = TRUE)

  rs <- dbSendQuery(con, "SELECT 1")
  expect_warning(ex <- dbGetException(con), "deprecated")
  dbClearResult(rs)

  expect_equal(ex$errorNum, 0)
  expect_equal(ex$errorMsg, "OK")
})

test_that("no exception after good statement sent and partially collected", {
  memoise::forget(warning_once)
  con <- dbConnect(SQLite())
  on.exit(dbDisconnect(con), add = TRUE)

  rs <- dbSendQuery(con, "SELECT 1 UNION SELECT 2")
  dbFetch(rs, 1)
  expect_warning(ex <- dbGetException(con), "deprecated")
  dbClearResult(rs)

  expect_equal(ex$errorNum, 0)
  expect_equal(ex$errorMsg, "OK")
})

test_that("exception after bad statement sent", {
  memoise::forget(warning_once)
  con <- dbConnect(SQLite())
  on.exit(dbDisconnect(con), add = TRUE)

  expect_error(dbSendQuery(con, "RAISE"), "syntax error")
  expect_warning(ex <- dbGetException(con), "deprecated")

  expect_equal(ex$errorNum, 0)
  expect_match(ex$errorMsg, "OK")
})
