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
