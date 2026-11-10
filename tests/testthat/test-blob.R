test_that("adding large blob to table survives valgrind check (#192)", {
  # Requires 64-bit system
  skip_on_appveyor()

  con <- dbConnect(SQLite())
  on.exit(dbDisconnect(con), add = TRUE)

  data <- data.frame(id = 1, data = I(list(raw(1e8))))
  data$data <- unclass(data$data)
  dbWriteTable(con, "data", data)

  data$data <- blob::as_blob(data$data)
  expect_equal(
    dbReadTable(con, "data"),
    data
  )
})

test_that("can read more than standard limit (#314)", {
  # Requires 64-bit system
  skip_on_appveyor()

  # Easy on CRAN's infrastructure
  skip_on_cran()

  con <- dbConnect(SQLite())
  on.exit(dbDisconnect(con), add = TRUE)

  dbWriteTable(con, "data", data.frame(id = 1, data = blob(raw(1e9 + 1))))

  expect_equal(
    dbGetQuery(con, "SELECT length(data) AS len FROM data")$len,
    1e9 + 1
  )
})

test_that("blob class", {
  con <- dbConnect(SQLite())
  on.exit(dbDisconnect(con), add = TRUE)

  data <- data.frame(id = 1, data = blob(raw(1e3)))
  dbWriteTable(con, "data", data)
  expect_equal(
    dbReadTable(con, "data"),
    data
  )
})

test_that("a blob in a text column is read as text only if it is valid UTF-8", {
  con <- memory_db()
  on.exit(dbDisconnect(con), add = TRUE)

  dbExecute(con, "CREATE TABLE t (x)")
  dbExecute(con, "INSERT INTO t VALUES ('a'), (X'6162'), (X'00ff'), (X'ff'), (X'C3A4')")

  expect_warning(
    expect_warning(
      out <- dbGetQuery(con, "SELECT x FROM t"),
      "coercing other values of type blob"
    ),
    "2 blob values are not valid UTF-8 text, NA is returned"
  )
  expect_identical(out$x, c("a", "ab", NA, NA, "ä"))
  expect_identical(Encoding(out$x[[5]]), "UTF-8")

  # A blob in a declared TEXT column takes the same route
  dbExecute(con, "CREATE TABLE u (x TEXT)")
  dbExecute(con, "INSERT INTO u VALUES ('a'), (X'00')")
  expect_warning(
    expect_warning(
      out <- dbGetQuery(con, "SELECT x FROM u"),
      "coercing other values of type blob"
    ),
    "1 blob value is not valid UTF-8 text, NA is returned"
  )
  expect_identical(out$x, c("a", NA))
})

test_that("a blob in a text column is NA for every malformed UTF-8 form", {
  con <- memory_db()
  on.exit(dbDisconnect(con), add = TRUE)

  dbExecute(con, "CREATE TABLE t (x)")
  dbExecute(
    con,
    paste(
      "INSERT INTO t VALUES ('a'),",
      # Overlong, surrogate, beyond U+10FFFF, truncated
      "(X'C080'), (X'EDA080'), (X'F4908080'), (X'E282'),",
      # A NUL-terminated C string
      "(X'616200'),",
      # Valid counterparts: U+20AC, U+10FFFF
      "(X'E282AC'), (X'F48FBFBF')"
    )
  )

  warnings <- capture_warnings(out <- dbGetQuery(con, "SELECT x FROM t"))
  expect_identical(out$x, c("a", NA, NA, NA, NA, NA, "€", "\U0010FFFF"))
  expect_identical(
    grep("UTF-8", warnings, value = TRUE),
    "Column `x`: 5 blob values are not valid UTF-8 text, NA is returned"
  )
})

test_that("an empty blob in a text column is an empty string", {
  con <- memory_db()
  on.exit(dbDisconnect(con), add = TRUE)

  dbExecute(con, "CREATE TABLE t (x)")
  dbExecute(con, "INSERT INTO t VALUES ('a'), (X'')")

  warnings <- capture_warnings(out <- dbGetQuery(con, "SELECT x FROM t"))
  expect_identical(out$x, c("a", ""))
  expect_identical(grep("UTF-8", warnings, value = TRUE), character())
})

test_that("a blob in a text column is checked in every chunk", {
  con <- memory_db()
  on.exit(dbDisconnect(con), add = TRUE)

  dbExecute(con, "CREATE TABLE t (x)")
  dbExecute(
    con,
    "INSERT INTO t VALUES ('a'), (X'6162'), (X'ff'), (X'C3A4'), (X'00')"
  )

  res <- dbSendQuery(con, "SELECT x FROM t")
  warnings_1 <- capture_warnings(out_1 <- dbFetch(res, 2))
  # A chunk that holds only blobs
  warnings_2 <- capture_warnings(out_2 <- dbFetch(res, 2))
  warnings_3 <- capture_warnings(out_3 <- dbFetch(res, 2))
  dbClearResult(res)

  expect_identical(out_1$x, c("a", "ab"))
  expect_identical(out_2$x, c(NA, "ä"))
  expect_identical(out_3$x, NA_character_)
  expect_identical(grep("UTF-8", warnings_1, value = TRUE), character())
  expect_identical(
    grep("UTF-8", warnings_2, value = TRUE),
    "Column `x`: 1 blob value is not valid UTF-8 text, NA is returned"
  )
  expect_identical(
    grep("UTF-8", warnings_3, value = TRUE),
    "Column `x`: 1 blob value is not valid UTF-8 text, NA is returned"
  )
})

test_that("a peek between chunks leaves a blob in a text column a blob", {
  con <- memory_db()
  on.exit(dbDisconnect(con), add = TRUE)

  dbExecute(con, "CREATE TABLE t (x)")
  dbExecute(con, "INSERT INTO t VALUES ('a'), (X'00ff'), (X'6162')")

  # dbFetch(n = 0) and dbColumnInfo() read the next row without returning it
  fetch_around <- function(peek) {
    res <- dbSendQuery(con, "SELECT x FROM t")
    on.exit(dbClearResult(res))

    expect_identical(dbFetch(res, 1)$x, "a")
    peek_warnings <- capture_warnings(peek(res))
    warnings <- capture_warnings(out <- dbFetch(res))
    expect_identical(out$x, c(NA, "ab"))
    # Reported once, by the fetch that returns the value
    expect_identical(grep("UTF-8", peek_warnings, value = TRUE), character())
    expect_identical(
      grep("UTF-8", warnings, value = TRUE),
      "Column `x`: 1 blob value is not valid UTF-8 text, NA is returned"
    )
  }

  fetch_around(function(res) dbFetch(res, 0))
  fetch_around(dbColumnInfo)
})

test_that("a blob in a text column is not transcoded in a UTF-16 database", {
  con <- memory_db()
  on.exit(dbDisconnect(con), add = TRUE)

  dbExecute(con, "PRAGMA encoding = 'UTF-16le'")
  dbExecute(con, "CREATE TABLE t (x)")
  dbExecute(
    con,
    "INSERT INTO t VALUES ('a'), (X'6162'), (X'C3A4'), (X'61'), (X'00D8'), (X'00ff')"
  )
  expect_identical(dbGetQuery(con, "PRAGMA encoding")$encoding, "UTF-16le")

  warnings <- capture_warnings(out <- dbGetQuery(con, "SELECT x FROM t"))
  expect_identical(out$x, c("a", "ab", "ä", "a", NA, NA))
  expect_identical(
    grep("UTF-8", warnings, value = TRUE),
    "Column `x`: 2 blob values are not valid UTF-8 text, NA is returned"
  )
})

test_that("a column name is not a format string in a warning", {
  con <- memory_db()
  on.exit(dbDisconnect(con), add = TRUE)

  dbExecute(con, "CREATE TABLE t (x)")
  dbExecute(con, "INSERT INTO t VALUES ('a'), (X'ff')")

  warnings <- capture_warnings(
    dbGetQuery(con, 'SELECT x AS "x%s%d" FROM t')
  )
  expect_identical(
    warnings,
    c(
      "Column `x%s%d`: 1 blob value is not valid UTF-8 text, NA is returned",
      "Column `x%s%d`: mixed type, first seen values of type string, coercing other values of type blob"
    )
  )
})
