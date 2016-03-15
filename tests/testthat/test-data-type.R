context("Data type convertion")

# Specific to RSQLite
test_that("integers and boolean stored as INTEGER", {
  expect_equal(dbDataType(SQLite(), 1L), "INTEGER")
  expect_equal(dbDataType(SQLite(), FALSE), "INTEGER")
  expect_equal(dbDataType(SQLite(), TRUE), "INTEGER")
  expect_equal(dbDataType(SQLite(), NA), "INTEGER")
})

# Specific to RSQLite
test_that("doubles stored as REAL", {
  expect_equal(dbDataType(SQLite(), 1.0), "REAL")
})

# Specific to RSQLite
test_that("character is stored as TEXT", {
  expect_equal(dbDataType(SQLite(), "a"), "TEXT")
})

# Specific to RSQLite
test_that("raw and list stored as BLOB", {
  expect_equal(dbDataType(SQLite(), list(raw(1))), "BLOB")
  expect_equal(dbDataType(SQLite(), list()), "BLOB")
  expect_equal(dbDataType(SQLite(), list(a=NULL)), "BLOB")
})

# Specific to RSQLite
test_that("dates are stored as REAL", {
  expect_equal(dbDataType(SQLite(), Sys.Date()), "REAL")
  expect_equal(dbDataType(SQLite(), Sys.time()), "REAL")
})
