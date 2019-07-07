context("encoding")

test_that("write tables whose colnames or contents are BIG5 encoded (#277)", {
  skip_on_os("linux")
  skip_on_os("mac")
  skip_on_os("solaris")
  .loc <- Sys.getlocale("LC_COLLATE")
  Sys.setlocale(locale = "cht")
  con <- dbConnect(SQLite())
  on.exit({
    Sys.setlocale(locale = .loc)
    dbDisconnect(con)
  })

  big5_string <- rawToChar(as.raw(c(0xa4, 0xa4, 0xa4, 0xe5)))
  df <- structure(
    list(V1 = 1:3),
    class = "data.frame",
    row.names = 1:3)
  colnames(df) <- big5_string
  dbWriteTable(con, "a", df)
  res <- dbReadTable(con, "a")
  expect_identical(res, df)

  df <- structure(
    list(V1 = 1:3, V2 = rep(big5_string, 3)),
    class = "data.frame",
    row.names = 1:3)
  colnames(df) <- paste(big5_string, 1:2, sep = "")
  dbWriteTable(con, "b", df)
  res <- dbReadTable(con, "b")
  expect_identical(res, df)
})

test_that("write tables whose colnames and contents are UTF-8 encoded (#277)", {
  .loc <- Sys.getlocale("LC_COLLATE")
  if (.Platform$OS.type == "windows") {
    Sys.setlocale(locale = "cht")
  } else {
    Sys.setlocale(locale = "zh_TW.UTF-8")
  }
  con <- dbConnect(SQLite())
  on.exit({
    Sys.setlocale(locale = .loc)
    dbDisconnect(con)
  })

  utf8_string <- rawToChar(as.raw(c(0xe4, 0xb8, 0xad, 0xe6, 0x96, 0x87)))
  Encoding(utf8_string) <- "UTF-8"
  df <- structure(
    list(V1 = 1:3),
    class = "data.frame",
    row.names = 1:3)
  colnames(df) <- utf8_string
  dbWriteTable(con, "a", df)
  res <- dbReadTable(con, "a")
  expect_identical(res, df)

  df <- structure(
    list(V1 = 1:3, V2 = rep(utf8_string, 3)),
    class = "data.frame",
    row.names = 1:3)
  colnames(df) <- paste(utf8_string, 1:2, sep = "")
  dbWriteTable(con, "b", df)
  res <- dbReadTable(con, "b")
  expect_identical(res, df)
})

test_that("list the field of tables whose colnames are BIG5 encoded (#277)", {
  skip_on_os("linux")
  skip_on_os("mac")
  skip_on_os("solaris")
  .loc <- Sys.getlocale("LC_COLLATE")
  if (.Platform$OS.type == "windows") {
    Sys.setlocale(locale = "cht")
  } else {
    Sys.setlocale(locale = "zh_TW.UTF-8")
  }
  con <- dbConnect(SQLite())
  on.exit({
    Sys.setlocale(locale = .loc)
    dbDisconnect(con)
  })

  big5_string <- rawToChar(as.raw(c(0xa4, 0xa4, 0xa4, 0xe5)))
  df <- structure(
    list(V1 = 1:3),
    class = "data.frame",
    row.names = c(NA, -3L))
  colnames(df) <- big5_string
  dbWriteTable(con, "a", df)
  expect_identical(dbListFields(con, "a"), colnames(df))
  df <- structure(
    list(V1 = 1:3, V2 = rep(big5_string, 3)),
    class = "data.frame",
    row.names = 1:3)
  colnames(df) <- paste(big5_string, 1:2, sep = "")
  dbWriteTable(con, "b", df)
  expect_identical(dbListFields(con, "b"), colnames(df))

})

test_that("list the field of tables whose colnames are UTF-8 encoded (#277)", {
  .loc <- Sys.getlocale("LC_COLLATE")
  if (.Platform$OS.type == "windows") {
    Sys.setlocale(locale = "cht")
  } else {
    Sys.setlocale(locale = "zh_TW.UTF-8")
  }
  con <- dbConnect(SQLite())
  on.exit({
    Sys.setlocale(locale = .loc)
    dbDisconnect(con)
  })

  utf8_string <- rawToChar(as.raw(c(0xe4, 0xb8, 0xad, 0xe6, 0x96, 0x87)))
  Encoding(utf8_string) <- "UTF-8"
  df <- structure(
    list(V1 = 1:3),
    class = "data.frame",
    row.names = c(NA, -3L))
  colnames(df) <- utf8_string
  dbWriteTable(con, "a", df)
  expect_identical(dbListFields(con, "a"), colnames(df))
  df <- structure(
    list(V1 = 1:3, V2 = rep(utf8_string, 3)),
    class = "data.frame",
    row.names = 1:3)
  colnames(df) <- paste(utf8_string, 1:2, sep = "")
  dbWriteTable(con, "b", df)
  expect_identical(dbListFields(con, "b"), colnames(df))

})

test_that("append tables whose colnames are UTF-8 encoded (#277)", {
  .loc <- Sys.getlocale("LC_COLLATE")
  if (.Platform$OS.type == "windows") {
    Sys.setlocale(locale = "cht")
  } else {
    Sys.setlocale(locale = "zh_TW.UTF-8")
  }
  con <- dbConnect(SQLite())
  on.exit({
    Sys.setlocale(locale = .loc)
    dbDisconnect(con)
  })

  df <- structure(
    list(V1 = 1:3),
    class = "data.frame",
    row.names = c(NA, -3L))
  utf8_string <- rawToChar(as.raw(c(0xe4, 0xb8, 0xad, 0xe6, 0x96, 0x87)))
  Encoding(utf8_string) <- "UTF-8"
  colnames(df) <- utf8_string
  dbWriteTable(con, "a", df)
  expect_error(dbWriteTable(con, "a", df, append = TRUE), NA)

  df <- structure(
    list(V1 = 1:3, V2 = rep(utf8_string, 3)),
    class = "data.frame",
    row.names = 1:3)
  colnames(df) <- paste(utf8_string, 1:2, sep = "")
  dbWriteTable(con, "b", df)
  expect_error(dbWriteTable(con, "b", df, append = TRUE), NA)
})
