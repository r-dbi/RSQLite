context("dbSendQuery")

test_that("simple position binding works", {
  con <- dbConnect(SQLite(), ":memory:")
  dbWriteTable(con, "t1", data.frame(x = 1, y = 2))

  dbSendQuery(con, "INSERT INTO t1 VALUES (?, ?)", list(2, 1))
  
  expect_equal(dbReadTable(con, "t1")$x, c(1, 2)) 
})

test_that("simple named binding works", {
  con <- dbConnect(SQLite(), ":memory:")
  dbWriteTable(con, "t1", data.frame(x = 1, y = 2))
  
  dbSendQuery(con, "INSERT INTO t1 VALUES ($x, $y)", list(y = 1, x = 2))
  expect_equal(dbReadTable(con, "t1")$x, c(1, 2)) 
  
  dbSendQuery(con, "INSERT INTO t1 VALUES (:x, :y)", list(y = 3, x = 4))
  expect_equal(dbReadTable(con, "t1")$x, c(1, 2, 4)) 
})

test_that("bound params must match query params", {
  con <- datasetsDb()
  rs <- dbSendQuery(con, "SELECT * FROM mtcars WHERE cyl = $x")
  
  expect_error(dbBind(rs, list()), "1 params; 0 supplied") 
  expect_error(dbBind(rs, list(y = 1)), "No parameter")
  expect_error(dbBind(rs, list(quote(a))), "type symbol")
})

test_that("special charaters work", {
  angstrom <- enc2utf8("å")
  con <- dbConnect(RSQLite::SQLite())
  
  dbGetQuery(con, "CREATE TABLE test1 (x CHARACTER)")
  dbGetQuery(con, "INSERT INTO test1 VALUES ('å')")
  
  expect_equal(dbGetQuery(con, "SELECT * FROM test1")$x, angstrom)
  expect_equal(dbGetQuery(con, "SELECT * FROM test1 WHERE x = 'å'")$x,
    angstrom)
})