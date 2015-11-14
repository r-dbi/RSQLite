context("dbSendQuery")

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

test_that("can round trip raw vector", {
  con <- dbConnect(RSQLite::SQLite())
  
  dbGetQuery(con, "CREATE TABLE test1 (x BLOB)")
  rs <- dbSendQuery(con, "INSERT INTO test1 VALUES (:x)")
  dbBind(rs, list(x = list(serialize("abc", NULL))))
  
  x <- dbGetQuery(con, "SELECT * FROM test1")
  expect_equal(unserialize(x$x[[1]]), "abc")
})