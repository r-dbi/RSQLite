# One warning per chunk for values that are not of their column's type

coercion_warnings <- function(expr) {
  out <- list()
  withCallingHandlers(
    expr,
    RSQLite_warning_coercion = function(w) {
      out[[length(out) + 1]] <<- w
      invokeRestart("muffleWarning")
    }
  )
  out
}

test_that("coercions are reported once per chunk with row numbers", {
  con <- local_con()
  dbExecute(con, "CREATE TABLE t (x, y)")
  dbExecute(con, "INSERT INTO t VALUES (1, 'a'), (2.5, 'b'), ('three', 3), (4, X'ff'), (5, 'e')")

  w <- coercion_warnings(df <- as.data.frame(dbGetQueryArrow(con, "SELECT * FROM t")))
  expect_length(w, 1)
  expect_s3_class(w[[1]], "RSQLite_warning_coercion")
  expect_equal(df$x, c(1, 2.5, 0, 4, 5))
  expect_equal(df$y, c("a", "b", "3", NA, "e"))

  coercions <- w[[1]]$coercions
  expect_equal(vapply(coercions, `[[`, "", "column"), c("x", "y"))
  expect_equal(vapply(coercions, `[[`, "", "type"), c("double", "utf8"))
  x <- coercions[[1]]$values
  expect_equal(x[[1]]$class, "string")
  expect_equal(x[[1]]$reason, "converted")
  expect_equal(x[[1]]$count, 1)
  expect_equal(x[[1]]$rows, 3)
  expect_null(x[[1]]$last)
  # The integer 3 is rendered as text silently
  y <- coercions[[2]]$values
  expect_equal(vapply(y, `[[`, "", "class"), "blob")
  expect_equal(vapply(y, `[[`, "", "reason"), "invalid_utf8")
  expect_equal(vapply(y, `[[`, 1, "rows"), 4)
})

test_that("the warning message lists columns and rows", {
  con <- local_con()
  dbExecute(con, "CREATE TABLE t (x, y)")
  dbExecute(con, "INSERT INTO t VALUES (1, 'a'), (2.5, 'b'), ('three', 3), (4, X'ff'), (5, 'e')")

  expect_snapshot({
    df <- as.data.frame(dbGetQueryArrow(con, "SELECT * FROM t"))
  })
})

test_that("row numbers count from the first row of the result", {
  con <- local_con()
  dbExecute(con, "CREATE TABLE t (x)")
  dbExecute(con, "INSERT INTO t VALUES (1), (2), ('a'), (4), ('b'), (6)")

  rs <- dbSendQueryArrow(con, "SELECT x FROM t")
  on.exit(dbClearResult(rs))
  expect_no_warning(dbFetchArrowChunk(rs, chunk_size = 2))
  w <- coercion_warnings(chunk <- dbFetchArrowChunk(rs, chunk_size = 2))
  expect_equal(w[[1]]$coercions[[1]]$values[[1]]$rows, 3)
  w <- coercion_warnings(chunk <- dbFetchArrowChunk(rs, chunk_size = 2))
  expect_equal(w[[1]]$coercions[[1]]$values[[1]]$rows, 5)
  expect_no_warning(dbFetchArrowChunk(rs, chunk_size = 2))
})

test_that("long lists of rows are truncated", {
  con <- local_con()
  dbExecute(con, "CREATE TABLE t (x)")
  dbExecute(con, "INSERT INTO t VALUES (0)")
  dbExecute(con, "WITH RECURSIVE s(i) AS (SELECT 1 UNION ALL SELECT i + 1 FROM s WHERE i < 30) INSERT INTO t SELECT 'x' FROM s")

  withr::local_options(cli.unicode = FALSE)
  w <- coercion_warnings(df <- as.data.frame(dbGetQueryArrow(con, "SELECT x FROM t")))
  values <- w[[1]]$coercions[[1]]$values[[1]]
  expect_equal(values$count, 30)
  expect_equal(values$rows, 2:21)
  expect_equal(values$last, c(30, 31))
  expect_match(
    conditionMessage(w[[1]]),
    "30 string values converted \\(rows 2, 3, 4, .*, 18, 19, \\.\\.\\., 30, and 31\\)"
  )
})

test_that("a blob in a text column is text only if it is valid UTF-8", {
  con <- local_con()
  dbExecute(con, "CREATE TABLE t (x)")
  dbExecute(con, "INSERT INTO t VALUES ('a'), (X'6162'), (X'00ff'), (X'C3A4')")

  w <- coercion_warnings(df <- as.data.frame(dbGetQueryArrow(con, "SELECT x FROM t")))
  expect_equal(df$x, c("a", "ab", NA, "ä"))
  values <- w[[1]]$coercions[[1]]$values
  expect_equal(vapply(values, `[[`, "", "reason"), c("converted", "invalid_utf8"))
  expect_equal(values[[1]]$rows, c(2, 4))
  expect_equal(values[[2]]$rows, 3)
})

test_that("unparsable dates and times are dropped and reported once", {
  con <- dbConnect(SQLite(), extended_types = TRUE)
  on.exit(dbDisconnect(con))
  dbExecute(con, "CREATE TABLE t (d DATE, tm TIME, ts TIMESTAMP)")
  dbExecute(con, "INSERT INTO t VALUES ('2020-01-01', '01:02:03', '2020-01-01 01:02:03')")
  dbExecute(con, "INSERT INTO t VALUES ('nope', 'nope', 'nope'), ('nope', X'00', 18263)")

  w <- coercion_warnings(df <- as.data.frame(dbGetQueryArrow(con, "SELECT * FROM t")))
  expect_length(w, 1)
  expect_equal(df$d, as.Date(c("2020-01-01", NA, NA)))
  expect_equal(df$tm, hms::as_hms(c("01:02:03", NA, NA)))
  expect_equal(is.na(df$ts), c(FALSE, TRUE, FALSE))
  coercions <- w[[1]]$coercions
  expect_equal(vapply(coercions, `[[`, "", "column"), c("d", "tm", "ts"))
  expect_equal(coercions[[1]]$values[[1]]$reason, "unparsable")
  expect_equal(coercions[[1]]$values[[1]]$rows, c(2, 3))
  expect_equal(vapply(coercions[[2]]$values, `[[`, "", "class"), c("string", "blob"))
})

test_that("no warning without mixed types", {
  con <- local_con()
  expect_no_warning(as.data.frame(dbGetQueryArrow(con, "SELECT 1 AS a UNION ALL SELECT 2")))
})
