# Requesting R types for result columns with `ptype`

test_that("ptype requires a connection with arrow = TRUE", {
  con <- local_con()
  expect_error(
    dbGetQuery(con, "SELECT 1 AS a", ptype = list(a = integer())),
    "`ptype` requires a connection with `arrow = TRUE`",
    fixed = TRUE
  )
  expect_equal(dbGetQuery(con, "SELECT 1 AS a", ptype = NULL), data.frame(a = 1L))
})

test_that("ptype fixes the types of the named columns", {
  con <- local_arrow_con()
  dbExecute(con, "CREATE TABLE t (id, big, txt, ts, d, tm)")
  dbExecute(con, "INSERT INTO t VALUES
    (1, 1, 'a', '2024-01-01 12:00:00', '2024-01-01', '12:34:56'),
    (2, 1099511627776, 'b', '2024-06-01 00:00:00', '2024-02-02', '00:00:01'),
    (3, 3, 'c', NULL, NULL, NULL)")

  # Decided from the values
  df <- dbGetQuery(con, "SELECT * FROM t")
  expect_type(df$id, "integer")
  expect_s3_class(df$big, "integer64")
  expect_type(df$txt, "character")
  expect_type(df$ts, "character")

  # Requested
  ptype <- list(
    id = bit64::integer64(), big = numeric(), txt = factor(),
    ts = as.POSIXct(character(), tz = "Europe/Zurich"), d = as.Date(character()), tm = hms::hms()
  )
  df <- dbGetQuery(con, "SELECT * FROM t", ptype = ptype)
  expect_equal(df$id, bit64::as.integer64(1:3))
  expect_equal(df$big, c(1, 2^40, 3))
  expect_equal(df$txt, factor(c("a", "b", "c")))
  ts <- as.POSIXct(c("2024-01-01 12:00:00", "2024-06-01 00:00:00", NA), tz = "UTC")
  attr(ts, "tzone") <- "Europe/Zurich"
  expect_equal(df$ts, ts)
  expect_equal(format(df$ts[1]), "2024-01-01 13:00:00")
  expect_equal(df$d, as.Date(c("2024-01-01", "2024-02-02", NA)))
  expect_equal(df$tm, hms::as_hms(c("12:34:56", "00:00:01", NA)))

  # The other columns are decided from the values
  df <- dbGetQuery(con, "SELECT * FROM t", ptype = list(txt = factor(levels = c("a", "b"))))
  expect_type(df$id, "integer")
  expect_s3_class(df$big, "integer64")
  expect_equal(df$txt, factor(c("a", "b", NA), levels = c("a", "b")))

  # An integer prototype narrows to int32: values outside the range become NA
  expect_warning(
    df <- dbGetQuery(con, "SELECT big FROM t", ptype = list(big = integer())),
    class = "RSQLite_warning_coercion"
  )
  expect_equal(df$big, c(1L, NA, 3L))

  # Text prototypes render numbers, and blob prototypes read blobs
  expect_equal(dbGetQuery(con, "SELECT id FROM t", ptype = list(id = character()))$id, c("1", "2", "3"))
  dbExecute(con, "CREATE TABLE b (x)")
  dbExecute(con, "INSERT INTO b VALUES (X'0102'), (NULL)")
  expect_equal(
    dbGetQuery(con, "SELECT x FROM b", ptype = list(x = blob::blob()))$x,
    blob::blob(as.raw(c(1, 2)), NULL)
  )
})

test_that("ptype accepts a data frame, and the values are ignored", {
  con <- local_arrow_con()
  dbExecute(con, "CREATE TABLE t (id, ts)")
  dbExecute(con, "INSERT INTO t VALUES (1, '2024-01-01 12:00:00'), (2, 1717200000)")

  expected <- data.frame(id = c(1, 2), ts = as.POSIXct(c("2024-01-01 12:00:00", "2024-06-01 00:00:00"), tz = "UTC"))
  ptype <- list(id = numeric(), ts = as.POSIXct(character(), tz = "UTC"))
  expect_equal(dbGetQuery(con, "SELECT * FROM t", ptype = ptype), expected)
  expect_equal(dbGetQuery(con, "SELECT * FROM t", ptype = as.data.frame(ptype)), expected)
  expect_equal(dbGetQuery(con, "SELECT * FROM t", ptype = expected[2, ]), expected)
  # Entries may come in any order, and POSIXlt stands for POSIXct
  expect_equal(
    dbGetQuery(con, "SELECT * FROM t", ptype = list(ts = as.POSIXlt(character(), tz = "UTC"), id = numeric())),
    expected
  )
})

test_that("ptype entries are matched by name, exactly", {
  con <- local_arrow_con()
  expect_error(dbGetQuery(con, "SELECT 1 AS abc", ptype = list(ab = integer())), "not in the result: `ab`", fixed = TRUE)
  expect_error(dbGetQuery(con, "SELECT 1 AS a", ptype = list(A = integer())), "not in the result: `A`", fixed = TRUE)
  expect_error(dbGetQuery(con, "SELECT 1 AS a, 2 AS a", ptype = list(a = integer())), "more than once: `a`", fixed = TRUE)
  expect_error(dbGetQuery(con, "SELECT 1 AS a", ptype = list(integer())), "must be named")
  expect_error(dbGetQuery(con, "SELECT 1 AS a", ptype = data.frame()), "must be named")
  expect_error(
    dbGetQuery(con, "SELECT 1 AS a", ptype = list(a = integer(), a = numeric())),
    "Duplicate column names in `ptype`: `a`",
    fixed = TRUE
  )

  # A failed request leaves no open result behind
  expect_error(dbSendQuery(con, "SELECT 1 AS a", ptype = list(b = integer())))
  expect_no_warning(dbGetQuery(con, "SELECT 1 AS a"))
})

test_that("ptype must hold vectors that SQLite values can be read into", {
  con <- local_arrow_con()
  expect_error(dbGetQuery(con, "SELECT 1 AS a", ptype = "a"), "must be a data frame or a named list of vectors")
  expect_error(
    dbGetQuery(con, "SELECT 1 AS a", ptype = nanoarrow::na_struct(list(a = nanoarrow::na_int32()))),
    "must be a data frame or a named list of vectors"
  )
  expect_error(dbGetQuery(con, "SELECT 1 AS a", ptype = list(a = data.frame(b = 1))), "vectors, not data frames")
  expect_error(dbGetQuery(con, "SELECT 1 AS a", ptype = list(a = raw())), "`blob::blob()`", fixed = TRUE)
  expect_error(
    dbGetQuery(con, "SELECT 1 AS a", ptype = list(a = as.difftime(1, units = "secs"))),
    "Can't fill a column of Arrow type duration('us') (column `a`)",
    fixed = TRUE
  )
})

test_that("ptype holds across chunks, bindings, and empty results", {
  con <- local_arrow_con()
  dbExecute(con, "CREATE TABLE t (x)")
  dbExecute(con, "INSERT INTO t VALUES (NULL), (NULL), (1.5)")

  rs <- dbSendQuery(con, "SELECT x FROM t", ptype = list(x = numeric()))
  expect_equal(dbFetch(rs, 1), data.frame(x = NA_real_))
  expect_equal(dbFetch(rs, 1), data.frame(x = NA_real_))
  expect_equal(dbFetch(rs, 1), data.frame(x = 1.5))
  expect_equal(dbFetch(rs, 1), data.frame(x = numeric()))
  dbClearResult(rs)

  rs <- dbSendQuery(con, "SELECT x FROM t WHERE x = ?", ptype = list(x = bit64::integer64()))
  dbBind(rs, list(1.5))
  expect_warning(df <- dbFetch(rs), class = "RSQLite_warning_coercion")
  expect_equal(df$x, bit64::as.integer64(1))
  dbBind(rs, list(2))
  expect_equal(dbFetch(rs), data.frame(x = bit64::integer64()))
  dbClearResult(rs)

  expect_equal(
    dbGetQuery(con, "SELECT x FROM t WHERE 0", ptype = list(x = factor(levels = "a"))),
    data.frame(x = factor(levels = "a"))
  )
})

test_that("values of other storage classes are converted to the prototype", {
  con <- local_arrow_con()
  dbExecute(con, "CREATE TABLE t (x)")
  dbExecute(con, "INSERT INTO t VALUES ('1'), (2), (2.5)")

  # Decided from the values: the text in the first row makes a text column
  expect_equal(dbGetQuery(con, "SELECT x FROM t")$x, c("1", "2", "2.5"))

  expect_warning(
    df <- dbGetQuery(con, "SELECT x FROM t", ptype = list(x = integer())),
    class = "RSQLite_warning_coercion"
  )
  expect_equal(df$x, c(1L, 2L, 2L))
  expect_warning(
    df <- dbGetQuery(con, "SELECT x FROM t", ptype = list(x = numeric())),
    class = "RSQLite_warning_coercion"
  )
  expect_equal(df$x, c(1, 2, 2.5))
})

test_that("bigint applies only to the columns without a prototype", {
  con <- local_arrow_con(bigint = "numeric")
  dbExecute(con, "CREATE TABLE t (a, b)")
  dbExecute(con, "INSERT INTO t VALUES (1099511627776, 1099511627776)")
  df <- dbGetQuery(con, "SELECT * FROM t", ptype = list(a = bit64::integer64()))
  expect_equal(df$a, bit64::as.integer64(2^40))
  expect_equal(df$b, 2^40)
})

test_that("dbReadTable() passes ptype on", {
  con <- local_arrow_con()
  dbWriteTable(con, "t", data.frame(a = 1:2, b = c("x", "y")))
  expect_equal(
    dbReadTable(con, "t", ptype = list(a = numeric(), b = factor())),
    data.frame(a = c(1, 2), b = factor(c("x", "y")))
  )
})
