# A string marked as UTF-8 from its bytes in hex, which may be invalid UTF-8
utf8_hex <- function(x) {
  out <- rawToChar(as.raw(strtoi(strsplit(x, " ")[[1]], 16L)))
  Encoding(out) <- "UTF-8"
  out
}

local_check_con <- function(
  check_utf8 = TRUE,
  encoding = NULL,
  .env = parent.frame()
) {
  con <- dbConnect(SQLite(), check_utf8 = check_utf8)
  withr::defer(dbDisconnect(con), envir = .env)
  if (!is.null(encoding)) {
    dbExecute(con, paste0("PRAGMA encoding = '", encoding, "'"))
  }
  con
}

# A table `t` with one untyped column `x`, so that values keep their type
create_check_table <- function(con, values) {
  dbExecute(con, "CREATE TABLE t (x)")
  rows <- paste0("(", values, ")", collapse = ", ")
  dbExecute(con, paste("INSERT INTO t VALUES", rows))
}

# The value of `expr` and the messages of the warnings it raises
with_warnings <- function(expr) {
  messages <- character()
  value <- withCallingHandlers(
    expr,
    warning = function(w) {
      messages <<- c(messages, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
  list(value = value, warnings = messages)
}

# Only the warnings of check_utf8, not the one about mixed types
utf8_warnings <- function(out) {
  grep("UTF-8", out$warnings, value = TRUE)
}

invalid_message <- function(n, name = "x") {
  if (n == 1) {
    what <- "1 value is not valid UTF-8 or contains a NUL byte"
  } else {
    what <- paste(n, "values are not valid UTF-8 or contain NUL bytes")
  }
  paste0("Column `", name, "`: ", what, ", NA is returned")
}

# check_utf8 = FALSE ----------------------------------------------------------

test_that("check_utf8 is FALSE by default", {
  withr::local_options(RSQLite.check_utf8 = NULL)
  con <- dbConnect(SQLite())
  on.exit(dbDisconnect(con), add = TRUE)

  expect_false(con@check_utf8)
})

test_that("check_utf8 = FALSE reads a blob in a text column as text", {
  con <- local_check_con(check_utf8 = FALSE)
  create_check_table(
    con,
    c("'a'", "X'00ff'", "X'6162'", "X'610062'", "X'61ff'")
  )

  out <- with_warnings(dbGetQuery(con, "SELECT x FROM t"))
  x <- out$value$x
  expect_identical(x[1:4], c("a", "", "ab", "a"))
  expect_identical(charToRaw(x[[5]]), as.raw(c(0x61, 0xff)))
  expect_identical(Encoding(x[[5]]), "UTF-8")
  expect_identical(utf8_warnings(out), character())
  expect_match(out$warnings, "mixed type")
})

test_that("check_utf8 = FALSE cuts text at a NUL byte", {
  con <- local_check_con(check_utf8 = FALSE)

  out <- with_warnings(
    dbGetQuery(con, "SELECT CAST(X'610062' AS TEXT) AS x")
  )
  expect_identical(out$value$x, "a")
  expect_identical(out$warnings, character())
})

test_that("check_utf8 = FALSE returns text that is not valid UTF-8", {
  con <- local_check_con(check_utf8 = FALSE)

  out <- with_warnings(dbGetQuery(con, "SELECT CAST(X'61ff' AS TEXT) AS x"))
  x <- out$value$x
  expect_identical(charToRaw(x), as.raw(c(0x61, 0xff)))
  expect_identical(Encoding(x), "UTF-8")
  expect_false(validUTF8(x))
  expect_identical(out$warnings, character())
})

# check_utf8 = TRUE -----------------------------------------------------------

test_that("the RSQLite.check_utf8 option sets the default", {
  withr::local_options(RSQLite.check_utf8 = TRUE)
  con <- dbConnect(SQLite())
  on.exit(dbDisconnect(con), add = TRUE)
  con_false <- dbConnect(SQLite(), check_utf8 = FALSE)
  on.exit(dbDisconnect(con_false), add = TRUE)

  expect_true(con@check_utf8)
  sql <- "SELECT CAST(X'61ff' AS TEXT) AS x"
  out <- with_warnings(dbGetQuery(con, sql))
  expect_identical(out$value$x, NA_character_)
  expect_identical(out$warnings, invalid_message(1))

  expect_false(con_false@check_utf8)
  expect_identical(
    charToRaw(dbGetQuery(con_false, sql)$x),
    as.raw(c(0x61, 0xff))
  )
})

test_that("check_utf8 = TRUE turns invalid text into NA, with a warning", {
  con <- local_check_con()
  dbExecute(con, "CREATE TABLE t (x, y)")
  dbExecute(
    con,
    paste(
      "INSERT INTO t VALUES",
      "('a', 'a'),",
      "(CAST(X'ff' AS TEXT), 'b'),",
      "(CAST(X'c0af' AS TEXT), CAST(X'eda080' AS TEXT)),",
      "(CAST(X'c3a4' AS TEXT), CAST(X'61e282' AS TEXT))"
    )
  )

  out <- with_warnings(dbGetQuery(con, "SELECT x, y FROM t"))
  expect_identical(out$value$x, c("a", NA, NA, utf8_hex("c3 a4")))
  expect_identical(out$value$y, c("a", "b", NA, NA))
  expect_identical(
    out$warnings,
    c(invalid_message(2, "x"), invalid_message(2, "y"))
  )
})

test_that("check_utf8 = TRUE turns text with a NUL byte into NA", {
  con <- local_check_con()

  out <- with_warnings(
    dbGetQuery(con, "SELECT CAST(X'610062' AS TEXT) AS x")
  )
  expect_identical(out$value$x, NA_character_)
  expect_identical(out$warnings, invalid_message(1))
})

test_that("check_utf8 = TRUE turns invalid blobs in a text column into NA", {
  con <- local_check_con()
  create_check_table(
    con,
    c(
      "'a'",
      "X'00ff'",
      "X'ff'",
      "X'c0af'",
      "X'eda080'",
      "X'f4908080'",
      "X'e282'",
      "X'610062'",
      "zeroblob(2)"
    )
  )

  out <- with_warnings(dbGetQuery(con, "SELECT x FROM t"))
  expect_identical(out$value$x, c("a", rep(NA, 8)))
  expect_identical(utf8_warnings(out), invalid_message(8))
  expect_match(out$warnings, "mixed type", all = FALSE)
})

test_that("check_utf8 = TRUE reads valid blobs in a text column in full", {
  con <- local_check_con()
  create_check_table(
    con,
    c("'a'", "X'6162'", "X'c3a4'", "X'e282ac'", "X'f09f9880'", "X'f48fbfbf'")
  )

  out <- with_warnings(dbGetQuery(con, "SELECT x FROM t"))
  expect_identical(
    out$value$x,
    c(
      "a",
      "ab",
      utf8_hex("c3 a4"),
      utf8_hex("e2 82 ac"),
      utf8_hex("f0 9f 98 80"),
      utf8_hex("f4 8f bf bf")
    )
  )
  expect_identical(Encoding(out$value$x[[3]]), "UTF-8")
  expect_identical(utf8_warnings(out), character())
})

test_that("check_utf8 = TRUE reads a blob by its length", {
  skip_if_not_installed("blob")
  con <- local_check_con()

  # A bound blob, unlike a value read from a table, is not followed by NUL bytes
  out <- with_warnings(
    dbGetQuery(
      con,
      "SELECT CASE WHEN column1 = 1 THEN 'a' ELSE ? END AS x FROM (VALUES (1), (2))",
      params = list(blob::blob(charToRaw("abcdefgh")))
    )
  )
  expect_identical(out$value$x, c("a", "abcdefgh"))
  expect_identical(utf8_warnings(out), character())
})

test_that("check_utf8 = TRUE reads empty text and blobs as empty strings", {
  con <- local_check_con()
  create_check_table(con, c("'a'", "''", "X''", "zeroblob(0)"))

  out <- with_warnings(dbGetQuery(con, "SELECT x FROM t"))
  expect_identical(out$value$x, c("a", "", "", ""))
  expect_identical(utf8_warnings(out), character())
})

test_that("check_utf8 = TRUE leaves numbers in a text column alone", {
  con <- local_check_con()
  create_check_table(con, c("'a'", "1", "2.5", "12345678901"))

  out <- with_warnings(dbGetQuery(con, "SELECT x FROM t"))
  expect_identical(out$value$x, c("a", "1", "2.5", "12345678901"))
  expect_identical(utf8_warnings(out), character())
})

test_that("check_utf8 = TRUE leaves a blob column alone", {
  con <- local_check_con()
  create_check_table(con, c("X'ff'", "X'00'"))

  out <- with_warnings(dbGetQuery(con, "SELECT x FROM t"))
  expect_identical(
    out$value$x,
    blob::blob(as.raw(0xff), as.raw(0x00))
  )
  expect_identical(out$warnings, character())
})

test_that("check_utf8 = TRUE warns in the chunk that holds the invalid values", {
  con <- local_check_con()
  create_check_table(
    con,
    c("'a'", "'b'", "X'ff'", "CAST(X'61ff' AS TEXT)", "'c'", "X'6162'")
  )

  res <- dbSendQuery(con, "SELECT x FROM t")
  withr::defer(dbClearResult(res))

  out <- with_warnings(dbFetch(res, 2))
  expect_identical(out$value$x, c("a", "b"))
  expect_identical(out$warnings, character())

  out <- with_warnings(dbFetch(res, 2))
  expect_identical(out$value$x, c(NA_character_, NA_character_))
  expect_identical(utf8_warnings(out), invalid_message(2))

  out <- with_warnings(dbFetch(res))
  expect_identical(out$value$x, c("c", "ab"))
  expect_identical(utf8_warnings(out), character())
})

test_that("check_utf8 = TRUE is not affected by a peek between chunks", {
  con <- local_check_con()
  create_check_table(
    con,
    c("'a'", "X'00ff'", "X'6162'", "CAST(X'ff' AS TEXT)")
  )

  res <- dbSendQuery(con, "SELECT x FROM t")
  withr::defer(dbClearResult(res))

  expect_identical(dbFetch(res, 1)$x, "a")

  # The peeks read the next row but do not return it, so they do not warn
  out <- with_warnings(dbColumnInfo(res))
  expect_identical(utf8_warnings(out), character())
  out <- with_warnings(dbFetch(res, 0))
  expect_identical(nrow(out$value), 0L)
  expect_identical(utf8_warnings(out), character())

  out <- with_warnings(dbFetch(res))
  expect_identical(out$value$x, c(NA, "ab", NA))
  expect_identical(utf8_warnings(out), invalid_message(2))
})

test_that("check_utf8 = TRUE reads blobs as bytes in a UTF-16 database", {
  for (encoding in c("UTF-16le", "UTF-16be")) {
    con <- local_check_con(encoding = encoding)
    dbExecute(con, "CREATE TABLE t (x)")
    dbExecute(
      con,
      paste(
        "INSERT INTO t VALUES ('a'), (?), (X'6162'), (X'c3a4'), (X'61'),",
        "(X'00ff'), (X'0061'), (X'6100')"
      ),
      params = list(utf8_hex("c3 a4 e2 82 ac"))
    )
    expected <- c(
      "a",
      utf8_hex("c3 a4 e2 82 ac"),
      "ab",
      utf8_hex("c3 a4"),
      "a",
      NA,
      NA,
      NA
    )

    out <- with_warnings(dbGetQuery(con, "SELECT x FROM t"))
    expect_identical(out$value$x, expected, info = encoding)
    expect_identical(utf8_warnings(out), invalid_message(3), info = encoding)

    # Also after a peek at the first blob
    res <- dbSendQuery(con, "SELECT x FROM t")
    expect_identical(dbFetch(res, 2)$x, expected[1:2], info = encoding)
    suppressWarnings(dbColumnInfo(res))
    out <- with_warnings(dbFetch(res))
    dbClearResult(res)
    expect_identical(out$value$x, expected[-1:-2], info = encoding)
    expect_identical(utf8_warnings(out), invalid_message(3), info = encoding)
  }
})

test_that("check_utf8 = TRUE prints a column name with % as is", {
  con <- local_check_con()

  out <- with_warnings(
    dbGetQuery(con, "SELECT CAST(X'ff' AS TEXT) AS [x%s%d]")
  )
  expect_identical(out$value[["x%s%d"]], NA_character_)
  expect_identical(out$warnings, invalid_message(1, "x%s%d"))
})

test_that("check_utf8 = TRUE agrees with base R on random blobs and text", {
  withr::local_seed(20261111)
  ascii <- as.raw(c(0x00, 0x20:0x7e))
  high <- as.raw(c(0x80:0xbf, 0xc2, 0xc3, 0xe2, 0xed, 0xf0, 0xf4, 0xff))
  bytes <- c(ascii, high)
  prob <- c(1, rep(30, 95), rep(2, 64), 5, 5, 5, 2, 3, 2, 1)
  values <- lapply(
    sample(0:20, 1000, replace = TRUE),
    function(n) sample(bytes, n, replace = TRUE, prob = prob)
  )
  valid <- vapply(
    values,
    function(x) !any(x == as.raw(0)) && validUTF8(rawToChar(x)),
    logical(1)
  )
  expected <- rep(NA_character_, length(values))
  expected[valid] <- vapply(values[valid], rawToChar, character(1))
  Encoding(expected) <- "UTF-8"

  con <- local_check_con()
  dbExecute(con, "CREATE TABLE t (i INTEGER, x)")
  dbExecute(con, "INSERT INTO t VALUES (0, 'a')")
  dbExecute(
    con,
    "INSERT INTO t VALUES (?, ?)",
    params = list(seq_along(values), blob::as_blob(values))
  )
  # The same bytes as text
  dbExecute(
    con,
    "INSERT INTO t SELECT i + 10000, CAST(x AS TEXT) FROM t WHERE i > 0"
  )

  out <- with_warnings(dbGetQuery(con, "SELECT x FROM t ORDER BY i"))
  expect_true(any(valid))
  expect_false(all(valid))
  expect_identical(out$value$x, c("a", expected, expected))
  expect_identical(utf8_warnings(out), invalid_message(2 * sum(!valid)))
})
