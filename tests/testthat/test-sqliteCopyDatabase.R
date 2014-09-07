context("sqliteCopyDatabase")

test_that("fails with bad arguments", {
  dbfile <- tempfile()
  con <- dbConnect(SQLite(), dbfile)

  badnames <- list(
    1:5,
    character(0),
    as.character(NA),
    ""
  )
  for (badname in badnames) {
    expect_error(sqliteCopyDatabase(con, badname), "must be")
  }
})

test_that("can backup memory db to disk", {
  con1 <- dbConnect(SQLite(), ":memory:")
  dbWriteTable(con1, "mtcars", mtcars)
  
  dbfile <- tempfile()
  sqliteCopyDatabase(con1, dbfile)
  
  con2 <- dbConnect(SQLite(), dbfile)
  expect_true(dbExistsTable(con2, "mtcars"))
})

test_that("can backup to connection", {
  con1 <- dbConnect(SQLite(), ":memory:")
  dbWriteTable(con1, "mtcars", mtcars)
  
  con2 <- dbConnect(SQLite(), ":memory:")
  sqliteCopyDatabase(con1, con2)
  
  expect_true(dbExistsTable(con2, "mtcars"))  
})
