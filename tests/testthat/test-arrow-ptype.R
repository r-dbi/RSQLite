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

test_that("the columns without a prototype are typed like the default path", {
  con <- local_arrow_con()
  con_default <- local_con()
  for (cc in list(con, con_default)) {
    dbExecute(cc, "CREATE TABLE t (x, y INTEGER, z)")
    dbExecute(cc, "INSERT INTO t VALUES (NULL, NULL, 1), (1, 2.5, 2), ('a', 3, 3)")
  }

  for (ns in list(c(0, -1), c(1, -1), c(1, 1, 1, 1), c(2, -1))) {
    rs <- dbSendQuery(con, "SELECT * FROM t", ptype = list(z = bit64::integer64()))
    rs_default <- dbSendQuery(con_default, "SELECT x, y FROM t")
    for (n in ns) {
      df <- suppressWarnings(dbFetch(rs, n))
      expect_equal(df[c("x", "y")], suppressWarnings(dbFetch(rs_default, n)), info = paste(ns, collapse = ", "))
      expect_s3_class(df$z, "integer64")
    }
    dbClearResult(rs)
    dbClearResult(rs_default)
  }
})

test_that("ptype columns keep their types in every fetch", {
  con <- local_arrow_con()
  dbExecute(con, "CREATE TABLE t (a, b, c)")
  dbExecute(con, "INSERT INTO t VALUES (NULL, NULL, NULL), (1, 2.5, 'x'), (2, 3, NULL)")
  ptype <- list(a = bit64::integer64(), b = integer(), c = factor(levels = "x"))

  rs <- dbSendQuery(con, "SELECT * FROM t", ptype = ptype)
  expect_equal(dbFetch(rs, 0), as.data.frame(ptype))
  expect_equal(
    dbFetch(rs, 1),
    data.frame(a = bit64::NA_integer64_, b = NA_integer_, c = factor(NA, levels = "x"))
  )
  expect_warning(df <- dbFetch(rs, 1), class = "RSQLite_warning_coercion")
  expect_equal(df, data.frame(a = bit64::as.integer64(1), b = 2L, c = factor("x")))
  expect_equal(dbFetch(rs), data.frame(a = bit64::as.integer64(2), b = 3L, c = factor(NA, levels = "x")))
  expect_equal(dbFetch(rs), as.data.frame(ptype))
  dbClearResult(rs)
})

test_that("ptype applies to the rows kept for a schema", {
  con <- local_arrow_con()
  dbExecute(con, "CREATE TABLE t (a, b)")
  dbExecute(con, "INSERT INTO t VALUES (NULL, 1), (1, 2), (2, 3)")

  rs <- dbSendQuery(con, "SELECT * FROM t", ptype = list(a = bit64::integer64()))
  stream <- dbFetchArrow(rs, chunk_size = 2)
  expect_equal(schema_formats(stream), c(a = "l", b = "l"))
  expect_equal(
    dbFetch(rs, 1),
    data.frame(a = bit64::NA_integer64_, b = 1L)
  )
  expect_equal(
    dbFetch(rs),
    data.frame(a = bit64::as.integer64(1:2), b = 2:3)
  )
  stream$release()
  dbClearResult(rs)
})

test_that("an integer64 prototype stays integer64 whatever bigint says", {
  for (bigint in c("integer64", "integer", "numeric", "character")) {
    con <- local_arrow_con(bigint = bigint)
    dbExecute(con, "CREATE TABLE t (a, b)")
    dbExecute(con, "INSERT INTO t VALUES (1, 1099511627776), (NULL, 2)")
    ptype <- list(a = bit64::integer64(), b = bit64::integer64())
    expect_equal(
      dbGetQuery(con, "SELECT * FROM t", ptype = ptype),
      data.frame(a = bit64::as.integer64(c(1, NA)), b = bit64::as.integer64(c(2^40, 2))),
      info = bigint
    )

    rs <- dbSendQuery(con, "SELECT * FROM t", ptype = ptype["a"])
    expect_s3_class(dbFetch(rs, 0)$a, "integer64")
    expect_s3_class(dbFetch(rs, 1)$a, "integer64")
    expect_s3_class(dbFetch(rs)$a, "integer64")
    dbClearResult(rs)
  }
})

test_that("logical and factor prototypes", {
  con <- local_arrow_con()
  dbExecute(con, "CREATE TABLE t (b, f)")
  dbExecute(con, "INSERT INTO t VALUES (0, 'b'), (1, 'a'), (NULL, 'c'), (2, NULL)")

  expect_equal(
    dbGetQuery(con, "SELECT b FROM t", ptype = list(b = logical())),
    data.frame(b = c(FALSE, TRUE, NA, TRUE))
  )

  # Values outside the levels become NA, as with factor()
  expect_equal(
    dbGetQuery(con, "SELECT f FROM t", ptype = list(f = factor(levels = c("b", "a")))),
    data.frame(f = factor(c("b", "a", NA, NA), levels = c("b", "a")))
  )
  expect_equal(
    dbGetQuery(con, "SELECT f FROM t", ptype = list(f = factor(levels = c("c", "b", "a"), ordered = TRUE))),
    data.frame(f = factor(c("b", "a", "c", NA), levels = c("c", "b", "a"), ordered = TRUE))
  )
  # Without levels, the levels come from the values of each fetch
  expect_equal(
    dbGetQuery(con, "SELECT f FROM t", ptype = list(f = ordered(character()))),
    data.frame(f = ordered(c("b", "a", "c", NA)))
  )
  rs <- dbSendQuery(con, "SELECT f FROM t", ptype = list(f = factor()))
  expect_equal(dbFetch(rs, 1), data.frame(f = factor("b")))
  expect_equal(dbFetch(rs), data.frame(f = factor(c("a", "c", NA))))
  dbClearResult(rs)
})

test_that("ptype rejects prototypes it can't request or convert back to", {
  con <- local_arrow_con()
  expect_error(
    dbGetQuery(con, "SELECT 1 AS a", ptype = list(a = complex())),
    "Can't request a type for column `a` of `ptype`",
    fixed = TRUE
  )
  expect_error(
    dbGetQuery(con, "SELECT 1 AS a, 2 AS b", ptype = list(a = integer(), b = NULL)),
    "Can't request a type for column `b` of `ptype`",
    fixed = TRUE
  )
  expect_error(
    dbGetQuery(con, "SELECT 1 AS a", ptype = list(a = I(numeric()))),
    "Can't convert the values of column `a` of `ptype` to its class <AsIs>",
    fixed = TRUE
  )
  expect_error(
    dbGetQuery(con, "SELECT 1 AS a", ptype = list(a = list())),
    "column `a` of `ptype`",
    fixed = TRUE
  )

  # A rejected prototype leaves an open result alone
  rs <- dbSendQuery(con, "SELECT 1 AS a")
  expect_error(dbSendQuery(con, "SELECT 1 AS a", ptype = list(a = I(numeric()))))
  expect_error(dbSendQuery(con, "SELECT 1 AS a", ptype = list(a = complex())))
  expect_true(dbIsValid(rs))
  expect_equal(dbFetch(rs), data.frame(a = 1L))
  dbClearResult(rs)
})
