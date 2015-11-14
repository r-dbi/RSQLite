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

test_that("logical converted to int", {
  con <- dbConnect(SQLite())
  
  local <- data.frame(x = 1:3, y = c(NA, TRUE, FALSE))
  dbWriteTable(con, "t1", local)
  remote <- dbReadTable(con, "t1")
  
  expect_equal(remote$y, as.integer(local$y))
})

test_that("can roundtrip special field names", {
  con <- dbConnect(SQLite())

  local <- data.frame(x = 1:3, select = 1:3, `  ` = 1:3, check.names = FALSE)
  dbWriteTable(con, "torture", local)
  remote <- dbReadTable(con, "torture", check.names = FALSE)
  
  expect_equal(local, remote)
})
