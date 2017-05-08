context("sqliteCopyDatabase")

# Specific to RSQLite
test_that("fails with bad arguments", {
  dbfile <- tempfile()
  con <- dbConnect(SQLite(), dbfile)
  on.exit(dbDisconnect(con), add = TRUE)

  badnames <- list(
    "must be" = 1:5,
    "length" = character(0),
    "is[.]na" = as.character(NA)
  )
  for (i in seq_along(badnames)) {
    expect_error(sqliteCopyDatabase(con, badnames[[i]]), names(badnames)[[i]])
  }
})

# Specific to RSQLite
test_that("can backup memory db to connection", {
  con1 <- dbConnect(SQLite(), ":memory:")
  on.exit(dbDisconnect(con1), add = TRUE)

  dbWriteTable(con1, "mtcars", mtcars)

  dbfile <- tempfile()
  con2 <- dbConnect(SQLite(), dbfile)
  on.exit(dbDisconnect(con2), add = TRUE)
  sqliteCopyDatabase(con1, con2)

  con3 <- dbConnect(SQLite(), dbfile)
  on.exit(dbDisconnect(con3), add = TRUE)

  expect_true(dbExistsTable(con3, "mtcars"))
})

# Specific to RSQLite
test_that("can backup memory db to file", {
  con1 <- dbConnect(SQLite(), ":memory:")
  on.exit(dbDisconnect(con1), add = TRUE)

  dbWriteTable(con1, "mtcars", mtcars)

  dbfile <- tempfile()
  sqliteCopyDatabase(con1, dbfile)

  con2 <- dbConnect(SQLite(), dbfile)
  on.exit(dbDisconnect(con2), add = TRUE)

  expect_true(dbExistsTable(con2, "mtcars"))
})

# Specific to RSQLite
test_that("can backup to connection", {
  con1 <- dbConnect(SQLite(), ":memory:")
  on.exit(dbDisconnect(con1), add = TRUE)

  dbWriteTable(con1, "mtcars", mtcars)

  con2 <- dbConnect(SQLite(), ":memory:")
  on.exit(dbDisconnect(con2), add = TRUE)

  sqliteCopyDatabase(con1, con2)

  expect_true(dbExistsTable(con2, "mtcars"))
})
