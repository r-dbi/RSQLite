context("sqliteCopyDatabase")

# Specific to RSQLite
test_that("fails with bad arguments", {
  dbfile <- tempfile()
  con <- dbConnect(SQLite(), dbfile)

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
  dbWriteTable(con1, "mtcars", mtcars)

  dbfile <- tempfile()
  sqliteCopyDatabase(con1, dbConnect(SQLite(), dbfile))

  con2 <- dbConnect(SQLite(), dbfile)
  expect_true(dbExistsTable(con2, "mtcars"))
})

# Specific to RSQLite
test_that("can backup memory db to file", {
  con1 <- dbConnect(SQLite(), ":memory:")
  dbWriteTable(con1, "mtcars", mtcars)

  dbfile <- tempfile()
  sqliteCopyDatabase(con1, dbfile)

  con2 <- dbConnect(SQLite(), dbfile)
  expect_true(dbExistsTable(con2, "mtcars"))
})

# Specific to RSQLite
test_that("can backup to connection", {
  con1 <- dbConnect(SQLite(), ":memory:")
  dbWriteTable(con1, "mtcars", mtcars)

  con2 <- dbConnect(SQLite(), ":memory:")
  sqliteCopyDatabase(con1, con2)

  expect_true(dbExistsTable(con2, "mtcars"))
})
