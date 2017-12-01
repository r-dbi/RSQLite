context("dbClearResult")

test_that("warning on dbFetch if result set open", {
  con <- dbConnect(SQLite(), ":memory:")
  on.exit(dbDisconnect(con))

  res <- dbSendQuery(con, "SELECT 1;")
  expect_false(dbHasCompleted(res))

  expect_warning(dbGetQuery(con, "SELECT 1;"), "pending rows")

  expect_warning(dbClearResult(res), "Expired")
})

test_that("accessing cleared result throws error", {
  con <- dbConnect(SQLite(), ":memory:")
  on.exit(dbDisconnect(con))

  res <- dbSendQuery(con, "SELECT 1;")
  dbClearResult(res)

  expect_error(dbFetch(res), "Invalid result set")
  expect_error(dbGetInfo(res), "closed")
})
