context("dbDiscconect")

test_that("closes result set with warning", {
  con <- dbConnect(SQLite())
  dbSendQuery(con, "CREATE TABLE mytable (integer a)")
  
  expect_warning(dbDisconnect(con), "closing automatically")
})