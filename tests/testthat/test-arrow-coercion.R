# One warning per chunk for values that are not of their column's type

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
  y <- coercions[[2]]$values
  expect_equal(vapply(y, `[[`, "", "class"), c("integer", "blob"))
  expect_equal(vapply(y, `[[`, "", "reason"), c("converted", "invalid_utf8"))
  expect_equal(vapply(y, `[[`, 1, "rows"), c(3, 4))
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

test_that("a data frame fetch through Arrow warns once, with the final types", {
  con <- local_arrow_con()
  dbExecute(con, "CREATE TABLE t (x)")
  dbExecute(con, "INSERT INTO t VALUES (1), ('a'), (2), ('b'), (2.5), ('c')")

  rs <- dbSendQuery(con, "SELECT x FROM t")
  # Three arrays: the column is int64 in the first two, double in the third
  w <- coercion_warnings(df <- arrow_fetch_df(rs, -1, chunk_size = 2))
  dbClearResult(rs)
  expect_equal(df$x, c(1, 0, 2, 0, 2.5, 0))
  expect_length(w, 1)
  coercions <- w[[1]]$coercions
  expect_length(coercions, 1)
  expect_equal(coercions[[1]]$type, "double")
  expect_equal(coercions[[1]]$values[[1]]$rows, c(2, 4, 6))

  # The arrays of 65536 rows of a fetch
  sql <- paste(
    "WITH RECURSIVE cnt(i) AS (SELECT 1 UNION ALL SELECT i + 1 FROM cnt WHERE i < 70000)",
    "SELECT CASE WHEN i IN (2, 70000) THEN 'x' ELSE i END AS a FROM cnt"
  )
  w <- coercion_warnings(df <- dbGetQuery(con, sql))
  expect_length(w, 1)
  expect_equal(w[[1]]$coercions[[1]]$values[[1]]$rows, c(2, 70000))

  # A stream warns per chunk, with the types fixed by the first one,
  # and for the first chunk when it fetches it for the schema
  rs <- dbSendQueryArrow(con, "SELECT x FROM t")
  on.exit(dbClearResult(rs))
  stream <- dbFetchArrow(rs, chunk_size = 2)
  w <- coercion_warnings(stream$get_schema())
  expect_length(w, 1)
  expect_equal(w[[1]]$coercions[[1]]$values[[1]]$rows, 2)
  w <- coercion_warnings(df <- as.data.frame(stream))
  expect_equal(df$x, c(1, 0, 2, 0, 2, 0))
  expect_length(w, 2)
  expect_equal(w[[1]]$coercions[[1]]$values[[1]]$rows, 4)
  expect_equal(w[[2]]$coercions[[1]]$type, "int64")
  expect_equal(vapply(w[[2]]$coercions[[1]]$values, `[[`, "", "class"), c("real", "string"))
})

test_that("values in a column of the null type are reported as dropped", {
  for (arrow in c(FALSE, TRUE)) {
    con <- local_con(arrow = arrow)
    dbExecute(con, "CREATE TABLE t (x)")
    dbExecute(con, "INSERT INTO t VALUES (NULL), (NULL), (1), ('a')")

    # The first chunk fixes the null type
    rs <- dbSendQuery(con, "SELECT x FROM t")
    expect_no_warning(chunk <- dbFetchArrowChunk(rs, chunk_size = 2))
    expect_equal(nanoarrow::infer_nanoarrow_schema(chunk)$children$x$format, "n")
    # Later chunks, and a data frame fetch through Arrow, drop the values
    if (arrow) {
      w <- coercion_warnings(rest <- dbFetch(rs))
      expect_equal(rest$x, c(NA, NA))
    } else {
      w <- coercion_warnings(rest <- dbFetchArrowChunk(rs, chunk_size = 2))
      expect_equal(rest$length, 2)
    }
    dbClearResult(rs)

    expect_length(w, 1)
    coercions <- w[[1]]$coercions[[1]]
    expect_equal(coercions$type, "null")
    expect_equal(vapply(coercions$values, `[[`, "", "class"), c("integer", "string"))
    expect_equal(vapply(coercions$values, `[[`, "", "reason"), c("null_type", "null_type"))
    expect_equal(vapply(coercions$values, `[[`, 1, "rows"), c(3, 4))
    expect_match(
      conditionMessage(w[[1]]),
      "1 integer value dropped by the null type, NA (row 3); 1 string value dropped by the null type, NA (row 4)",
      fixed = TRUE
    )
  }
})

test_that("a data frame fetch through Arrow that exits on its warning leaves the types open", {
  # The default path, then the Arrow path
  rest <- lapply(c(FALSE, TRUE), function(arrow) {
    con <- local_con(arrow = arrow)
    dbExecute(con, "CREATE TABLE t (x, y)")
    dbExecute(con, "INSERT INTO t VALUES (1, NULL), ('a', NULL), (2, 5), (3, 'z')")
    rs <- dbSendQuery(con, "SELECT * FROM t")
    # The first fetch warns about x, y has seen only NULL
    expect_equal(tryCatch(dbFetch(rs, 2), warning = function(w) "exited"), "exited")
    rest <- suppressWarnings(dbFetch(rs))
    dbClearResult(rs)
    rest
  })
  expect_identical(rest[[2]], rest[[1]])
  expect_identical(rest[[2]]$y, c(5L, 0L))
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
