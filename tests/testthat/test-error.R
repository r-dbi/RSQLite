context("error")

test_that("parameters with length != 1 (#89)", {
  con <- dbConnect(SQLite())
  on.exit(dbDisconnect(con), add = TRUE)

  dbExecute(con, "CREATE TABLE records(x REAL, y REAL);")
  expect_error(
    dbExecute(
      con,
      "INSERT INTO records (x, y) VALUES (:x, :y)",
      params = list(x = 1, y = 1)
    ),
    NA)
  expect_error(
    dbExecute(
      con,
      "INSERT INTO records (x, y) VALUES (:x, :y)",
      params = list(x = 1, y = list(1,2))
    ),
    "Parameter 2 does not have length 1")
  expect_error(
    dbExecute(
      con,
      "INSERT INTO records (x, y) VALUES (:x, :y)",
      params = list(x = 1, y = NULL)
    ),
    "Parameter 2 does not have length 1")

})

test_that("multipart queries (#313)", {
  con <- dbConnect(SQLite(), ":memory:")
  on.exit(dbDisconnect(con), add = TRUE)

  expect_silent(dbExecute(con, "create table Q(x integer); \n\t"))
  expect_silent(dbExecute(con, "insert into Q values (15)"))
  expect_warning(
    dbExecute(con, "create table T(x integer); insert into T values (15);"),
    "Ignoring.*insert into T"
  )
})
