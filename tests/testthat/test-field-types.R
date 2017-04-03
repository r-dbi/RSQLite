context("field-types")

test_that("passing field.types", {
  con <- dbConnect(SQLite())
  on.exit(dbDisconnect(con))

  dbWriteTable(con, "a", data.frame(a = 1:3), field.types = c("a" = "TEXT"))
  res <- dbReadTable(con, "a")

  expect_identical(res, data.frame(a = c("1", "2", "3"), stringsAsFactors = FALSE))
})

test_that("passing field.types for some columns only", {
  con <- dbConnect(SQLite())
  on.exit(dbDisconnect(con))

  dbWriteTable(con, "a", data.frame(a = 1:3, b = 4:6), field.types = c("a" = "TEXT"))
  expect_equal(
    dbReadTable(con, "a"),
    data.frame(a = as.character(1:3), b = 4:6, stringsAsFactors = FALSE)
  )
})

test_that("passing field.types with wrong name", {
  con <- dbConnect(SQLite())
  on.exit(dbDisconnect(con))

  expect_error(
    dbWriteTable(con, "a", data.frame(a = 1:3), field.types = c("b" = "TEXT")),
    "mismatch"
  )
})

test_that("passing field.types with primary key information", {
  con <- dbConnect(SQLite())
  on.exit(dbDisconnect(con))

  dbWriteTable(con, "a", data.frame(a = 1:3), field.types = c("a" = "INTEGER PRIMARY KEY"))
  res <- dbReadTable(con, "a")

  expect_identical(res, data.frame(a = 1:3))
})

test_that("passing field.types with primary key information and non-unique values", {
  con <- dbConnect(SQLite())
  on.exit(dbDisconnect(con))

  expect_error(dbWriteTable(con, "a", data.frame(a = c(1, 2, 1)), field.types = c("a" = "INTEGER PRIMARY KEY")),
               "UNIQUE")
})
