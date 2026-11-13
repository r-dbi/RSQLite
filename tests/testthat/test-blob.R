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

test_that("empty blobs", {
  con <- dbConnect(SQLite())
  on.exit(dbDisconnect(con), add = TRUE)

  expect_equal(
    dbGetQuery(con, "SELECT X'' AS x, zeroblob(0) AS y, X'0102' AS z"),
    data.frame(x = blob(raw()), y = blob(raw()), z = blob(as.raw(1:2)))
  )

  data <- data.frame(id = 1:2, data = blob(raw(), raw(3)))
  dbWriteTable(con, "data", data)
  expect_equal(dbReadTable(con, "data"), data)
})
