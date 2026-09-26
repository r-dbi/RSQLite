test_that("row.names defaults to FALSE", {
  con <- memory_db()
  on.exit(dbDisconnect(con))

  x <- data.frame(a = 1:2, row.names = c("x", "y"))
  dbWriteTable(con, "t1", x, row.names = TRUE)

  expect_named(dbGetQuery(con, "SELECT * FROM t1"), c("row_names", "a"))
  expect_named(dbReadTable(con, "t1"), c("row_names", "a"))
  expect_named(sqlData(con, x), "a")

  dbWriteTable(con, "t2", x)
  expect_equal(dbListFields(con, "t2"), "a")
})

test_that("row.names default for queries via pkgconfig is deprecated but honored", {
  skip_if_not_installed("pkgconfig")
  memoise::forget(warning_once)

  con <- memory_db()
  on.exit(dbDisconnect(con))

  x <- data.frame(a = 1:2, row.names = c("x", "y"))
  dbWriteTable(con, "t1", x, row.names = TRUE)

  pkgconfig::set_config("RSQLite::row.names.query" = NA)
  on.exit(pkgconfig::set_config("RSQLite::row.names.query" = NULL), add = TRUE)

  expect_warning(out <- dbGetQuery(con, "SELECT * FROM t1"), "deprecated")
  expect_named(out, "a")
  expect_equal(rownames(out), c("x", "y"))

  memoise::forget(warning_once)
  expect_warning(out <- sqlData(con, x), "deprecated")
  expect_named(out, c("row_names", "a"))

  memoise::forget(warning_once)
  expect_no_warning(out <- dbGetQuery(con, "SELECT * FROM t1", row.names = FALSE))
  expect_named(out, c("row_names", "a"))
})

test_that("row.names default for tables via pkgconfig is deprecated but honored", {
  skip_if_not_installed("pkgconfig")
  memoise::forget(warning_once)

  con <- memory_db()
  on.exit(dbDisconnect(con))

  pkgconfig::set_config("RSQLite::row.names.table" = TRUE)
  on.exit(pkgconfig::set_config("RSQLite::row.names.table" = NULL), add = TRUE)

  x <- data.frame(a = 1:2, row.names = c("x", "y"))
  expect_warning(dbWriteTable(con, "t1", x), "deprecated")
  expect_equal(dbListFields(con, "t1"), c("row_names", "a"))

  # Warns only once per session
  expect_no_warning(out <- dbReadTable(con, "t1"))
  expect_named(out, "a")
  expect_equal(rownames(out), c("x", "y"))
})
