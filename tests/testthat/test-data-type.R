context("Data type convertion")

sqliteDataType <- function(x) {
  dbDataType(SQLite(), x)
}

# Specific to RSQLite
test_that("integers and boolean stored as INTEGER", {
  expect_equal(sqliteDataType(1L), "INTEGER")
  expect_equal(sqliteDataType(FALSE), "INTEGER")
  expect_equal(sqliteDataType(TRUE), "INTEGER")
  expect_equal(sqliteDataType(NA), "INTEGER")
})

# Specific to RSQLite
test_that("doubles stored as REAL", {
  expect_equal(sqliteDataType(1.0), "REAL")
})

# Specific to RSQLite
test_that("character and factor stored as TEXT", {
  expect_equal(sqliteDataType("a"), "TEXT")
  expect_equal(sqliteDataType(factor(letters)), "TEXT")
  expect_equal(sqliteDataType(ordered(letters)), "TEXT")
})

# Specific to RSQLite
test_that("raw and list stored as BLOB", {
  expect_equal(sqliteDataType(list(raw(1))), "BLOB")
  expect_equal(sqliteDataType(list()), "BLOB")
  expect_equal(sqliteDataType(list(a=NULL)), "BLOB")
})

# Specific to RSQLite
test_that("dates are stored as REAL", {
  expect_equal(sqliteDataType(Sys.Date()), "REAL")
  expect_equal(sqliteDataType(Sys.time()), "REAL")
})

# Tested by DBItest
test_that("AsIs class is ignored", {
  df <- data.frame(
    a = I(1:2),
    b = I(c("x", "y")),
    c = I(list(raw(3), raw(1))),
    d = I(c(1.1, 2.2))
  )
  got <- sapply(df, sqliteDataType)
  expect_equal(got, c(a="INTEGER", b="TEXT", c="BLOB", d="REAL"))
})

test_that("unknown classes default to storage.mode()", {
  expect_equal(sqliteDataType(Sys.Date()), "REAL")
  expect_equal(sqliteDataType(Sys.time()), "REAL")

  intClass <- structure(1L, class="unknown1")
  expect_equal(sqliteDataType(intClass), "INTEGER")

  dblClass <- structure(3.14, class="unknown1")
  expect_equal(sqliteDataType(dblClass), "REAL")

  strClass <- structure("abc", class="unknown1")
  expect_equal(sqliteDataType(strClass), "TEXT")
})
