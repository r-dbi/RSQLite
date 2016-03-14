context("dbClearResult")

test_that("accessing cleared result throws error", {
  con <- dbConnect(SQLite(), ":memory:")
  on.exit(dbDisconnect(con))
  
  res <- dbSendQuery(con, "SELECT 1;")
  dbClearResult(res)
  
  expect_error(dbFetch(res), "not valid")
})
