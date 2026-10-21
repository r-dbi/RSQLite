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
