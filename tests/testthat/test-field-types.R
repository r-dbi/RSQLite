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
    "not found"
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

test_that("combining numeric types and NA to integer64 (#291)", {
  con <- dbConnect(SQLite())
  on.exit(dbDisconnect(con))

  x1 <- data.frame(a = c(1L, NA))
  x2 <- data.frame(a = c(2, NA))
  x3 <- data.frame(a = bit64::as.integer64(1e10))

  dbWriteTable(con, "a", x1)
  dbWriteTable(con, "a", x2, append = TRUE)
  dbWriteTable(con, "a", x3, append = TRUE)

  expect_identical(dbReadTable(con, "a")$a, bit64::as.integer64(c(1, NA, 2, NA, 1e10)))
})

test_that("combining numeric types and NA to numeric (#291)", {
  con <- dbConnect(SQLite())
  on.exit(dbDisconnect(con))

  x1 <- data.frame(a = c(1L, NA))
  x2 <- data.frame(a = c(1.5, NA))

  dbWriteTable(con, "a", x1)
  dbWriteTable(con, "a", x2, append = TRUE)

  expect_identical(dbReadTable(con, "a")$a, c(1, NA, 1.5, NA))
})
