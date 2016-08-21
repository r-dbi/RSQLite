context("dbClearResult")

test_that("warning on dbFetch if result set open", {
  skip("Currently failing")

  con <- dbConnect(SQLite(), ":memory:")
  on.exit(dbDisconnect(con))

  res <- dbSendQuery(con, "SELECT 1;")
  expect_false(dbHasCompleted(res))

  # No "pending rows" warning anymore
  expect_warning(dbGetQuery(con, "SELECT 1;"), "pending rows")

  dbClearResult(res)
})

test_that("accessing cleared result throws error", {
  con <- dbConnect(SQLite(), ":memory:")
  on.exit(dbDisconnect(con))

  res <- dbSendQuery(con, "SELECT 1;")
  dbClearResult(res)

  expect_error(dbFetch(res), "Expired")
  expect_error(dbGetInfo(res), "Expired")
})
