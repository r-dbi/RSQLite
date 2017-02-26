context("readonly")

test_that("read-only databases forbid writes", {
  con <- dbConnect(SQLite(), ":memory:", flags = SQLITE_RO)
  expect_error(
    dbWriteTable(con, "mtcars", mtcars),
    "attempt to write a readonly database",
    fixed = TRUE
  )
})
