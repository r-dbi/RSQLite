context("encoding")

test_that("write a table whose colnames is BIG5 encoded", {
  con <- dbConnect(SQLite())
  on.exit(dbDisconnect(con))

  df <- structure(
    list(V1 = 1:3),
    class = "data.frame",
    row.names = c(NA, -3L))
  . <- rawToChar(as.raw(c(0xa4, 0xa4, 0xa4, 0xe5)))
  Encoding(.) <- "BIG5"
  colnames(df) <- .
  dbWriteTable(con, "a", df)
  res <- dbReadTable(con, "a")

  expect_identical(res, df, stringsAsFactors = FALSE)
})

test_that("write a table whose colnames is UTF-8 encoded", {
  con <- dbConnect(SQLite())
  on.exit(dbDisconnect(con))

  df <- structure(
    list(V1 = 1:3),
    class = "data.frame",
    row.names = c(NA, -3L))
  . <- rawToChar(as.raw(c(0xe4, 0xb8, 0xad, 0xe6, 0x96, 0x87)))
  Encoding(.) <- "UTF-8"
  colnames(df) <- .
  dbWriteTable(con, "a", df)
  res <- dbReadTable(con, "a")
  expect_identical(res, df, stringsAsFactors = FALSE)
})

test_that("list the field of a table whose colnames is UTF-8 encoded", {
  con <- dbConnect(SQLite())
  on.exit(dbDisconnect(con))

  df <- structure(
    list(V1 = 1:3),
    class = "data.frame",
    row.names = c(NA, -3L))
  . <- rawToChar(as.raw(c(0xe4, 0xb8, 0xad, 0xe6, 0x96, 0x87)))
  Encoding(.) <- "UTF-8"
  colnames(df) <- .
  dbWriteTable(con, "a", df)
  expect_identical(dbListFields(con, "a"), colnames(df))
})

test_that("append a table whose colnames is UTF-8 encoded", {
  con <- dbConnect(SQLite())
  on.exit(dbDisconnect(con))

  df <- structure(
    list(V1 = 1:3),
    class = "data.frame",
    row.names = c(NA, -3L))
  . <- rawToChar(as.raw(c(0xe4, 0xb8, 0xad, 0xe6, 0x96, 0x87)))
  Encoding(.) <- "UTF-8"
  colnames(df) <- .
  dbWriteTable(con, "a", df)
  dbWriteTable(con, "a", df, append = TRUE)
})


