context("dbDiscconect")

test_that("closes result set with warning", {
  con <- dbConnect(SQLite())
  dbSendQuery(con, "CREATE TABLE mytable (integer a)")
  
  expect_warning(dbDisconnect(con), "closing automatically")
})

test_that("connections are finalised", {
  dbs <- lapply(1:50, function(x) {
    dbConnect(SQLite(), dbname = ":memory:")
  })
  expect_equal(dbGetInfo(SQLite())$num_con, 50)

  rm(dbs); gc()
  expect_equal(dbGetInfo(SQLite())$num_con, 0)
}) 
