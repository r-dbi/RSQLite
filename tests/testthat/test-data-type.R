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

test_that("AsIs class is ignored", {
  df <- data.frame(
    a = I(1:2),
    b = I(c("x", "y")),
    c = I(list(raw(3), raw(1))),
    d = I(c(1.1, 2.2))
  )
  got <- sapply(df, dbDataType, dbObj = SQLite())
  expect_equal(got, c(a="INTEGER", b="TEXT", c="BLOB", d="REAL"))
})

test_that("unknown cloasses default to typeof()", {
  expect_equal(dbDataType(SQLite(), Sys.Date()), "REAL")
  expect_equal(dbDataType(SQLite(), Sys.time()), "REAL")
  
  intClass <- structure(1L, class="unknown1")
  expect_equal(dbDataType(SQLite(), intClass), "INTEGER")
  
  dblClass <- structure(3.14, class="unknown1")
  expect_equal(dbDataType(SQLite(), dblClass), "REAL")
  
  strClass <- structure("abc", class="unknown1")
  expect_equal(dbDataType(SQLite(), strClass), "TEXT")
})
