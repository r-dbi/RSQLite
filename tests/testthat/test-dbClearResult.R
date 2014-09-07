context("dbClearResult")

test_that("warning on dbFetch if result set open", {
  con <- dbConnect(SQLite(), ":memory:")
  on.exit(dbDisconnect(con))
  
  res <- dbSendQuery(con, "SELECT 1;")
  expect_false(dbHasCompleted(res))
  
  expect_warning(dbGetQuery(con, "SELECT 1;"), "pending rows")
})

test_that("accessing cleared result throws error", {
  con <- dbConnect(SQLite(), ":memory:")
  on.exit(dbDisconnect(con))
  
  res <- dbSendQuery(con, "SELECT 1;")
  dbClearResult(res)
  
  expect_error(dbFetch(res), "Expired")
  expect_error(dbGetInfo(res), "Expired")  
})
