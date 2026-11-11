# dbConnect(arrow = TRUE): data frames travel through Arrow

test_that("the arrow argument is validated and recorded", {
  con <- local_arrow_con()
  expect_true(con@arrow)

  con2 <- dbConnect(SQLite(), ":memory:")
  on.exit(dbDisconnect(con2), add = TRUE, after = FALSE)
  expect_false(con2@arrow)

  expect_error(dbConnect(SQLite(), ":memory:", arrow = NA), "arrow")
  expect_error(dbConnect(SQLite(), ":memory:", arrow = "yes"), "arrow")
})

test_that("dbFetch() converts Arrow chunks to the same data frames", {
  con <- local_arrow_con()
  df <- data.frame(
    i = c(1L, NA, 3L),
    d = c(1.5, NA, 3.5),
    s = c("a", NA, "c"),
    l = c(TRUE, NA, FALSE),
    stringsAsFactors = FALSE
  )
  df$b <- blob::blob(as.raw(1:2), NULL, as.raw(3))
  dbWriteTable(con, "t", df)

  out <- dbReadTable(con, "t")
  expected <- df
  expected$l <- as.integer(expected$l)
  expect_equal(out, expected)

  rs <- dbSendQuery(con, "SELECT * FROM t")
  on.exit(dbClearResult(rs), add = TRUE, after = FALSE)
  expect_equal(dbFetch(rs, n = 0), expected[0, ])
  expect_equal(dbFetch(rs, n = 2), expected[1:2, ])
  expect_false(dbHasCompleted(rs))
  last <- expected[3, ]
  rownames(last) <- NULL
  expect_equal(dbFetch(rs, n = -1), last)
  expect_true(dbHasCompleted(rs))
  expect_equal(nrow(dbFetch(rs)), 0L)
})

test_that("64-bit integers follow bigint on the Arrow path", {
  df <- data.frame(small = 1:2)
  df$big <- bit64::as.integer64(c("1099511627776", "2"))

  con <- local_arrow_con()
  dbWriteTable(con, "t", df)
  out <- dbReadTable(con, "t")
  expect_type(out$small, "integer")
  expect_s3_class(out$big, "integer64")
  expect_equal(out, df)

  con_num <- local_arrow_con(bigint = "numeric")
  dbWriteTable(con_num, "t", df)
  out <- dbReadTable(con_num, "t")
  expect_type(out$small, "integer")
  expect_equal(out$big, c(1099511627776, 2))

  con_chr <- local_arrow_con(bigint = "character")
  dbWriteTable(con_chr, "t", df)
  expect_equal(dbReadTable(con_chr, "t")$big, c("1099511627776", "2"))

  con_int <- local_arrow_con(bigint = "integer")
  dbWriteTable(con_int, "t", df)
  expect_equal(dbReadTable(con_int, "t")$big, c(NA, 2L))
})

test_that("extended types come back as Date, hms and POSIXct on the Arrow path", {
  con <- local_arrow_con(extended_types = TRUE)
  df <- data.frame(d = as.Date("2020-01-02") + 0:1)
  df$t <- hms::hms(c(61.5, NA))
  df$ts <- as.POSIXct(c("2020-01-02 03:04:05.5", NA), tz = "UTC")
  dbWriteTable(con, "t", df)

  out <- dbReadTable(con, "t")
  expect_equal(out, df)

  rs <- dbSendQuery(con, "SELECT * FROM t")
  on.exit(dbClearResult(rs), add = TRUE, after = FALSE)
  expect_equal(dbFetch(rs, n = 1), df[1, ])
})

test_that("times and timestamps keep their precision through Arrow", {
  # Like values of Sys.time(), whose fractions need more than microseconds
  df <- data.frame(id = 1:200)
  df$ts <- withr::with_seed(1, .POSIXct(1.79e9 + runif(200), tz = "UTC"))
  df$t <- withr::with_seed(2, hms::hms(runif(200) * 86400))
  df$ts[3] <- NA
  df$t[4] <- NA

  con_default <- dbConnect(SQLite(), ":memory:", extended_types = TRUE)
  on.exit(dbDisconnect(con_default))
  con <- local_arrow_con(extended_types = TRUE)
  dbWriteTable(con_default, "t", df)
  dbWriteTable(con, "t", df)

  # The same numbers are stored
  numbers <- "SELECT ts + 0 AS ts, t + 0 AS t FROM t"
  expect_identical(dbGetQuery(con, numbers), dbGetQuery(con_default, numbers))
  expect_identical(dbGetQuery(con, numbers)$ts, as.numeric(df$ts))

  # and read back as they were written
  expect_identical(dbReadTable(con_default, "t"), df)
  expect_identical(dbReadTable(con, "t"), df)
  rs <- dbSendQuery(con, "SELECT * FROM t")
  expect_identical(arrow_fetch_df(rs, 150, chunk_size = 7), df[1:150, ])
  rest <- df[151:200, ]
  rownames(rest) <- NULL
  expect_identical(dbFetch(rs), rest)
  dbClearResult(rs)

  # A stream keeps microseconds
  stream <- dbGetQueryArrow(con, "SELECT ts, t FROM t")
  schema <- nanoarrow::infer_nanoarrow_schema(stream)
  expect_identical(schema$children$ts$format, "tsu:UTC")
  expect_identical(schema$children$t$format, "ttu")
  stream$release()
})

test_that("times and timestamps keep their range through Arrow", {
  sql <- c(
    "CREATE TABLE t (t TIME, ts TIMESTAMP)",
    "INSERT INTO t VALUES (9223372036855, 1e19), (-1e300, 1.5), (NULL, NULL)"
  )
  con_default <- dbConnect(SQLite(), ":memory:", extended_types = TRUE)
  on.exit(dbDisconnect(con_default))
  con <- local_arrow_con(extended_types = TRUE)
  for (s in sql) {
    dbExecute(con_default, s)
    dbExecute(con, s)
  }

  expect_silent(out <- dbReadTable(con, "t"))
  expect_identical(out, dbReadTable(con_default, "t"))
  expect_identical(as.numeric(out$ts), c(1e19, 1.5, NA))
})

test_that("untyped NULL columns are logical on the Arrow path", {
  con <- local_arrow_con()
  expect_equal(dbGetQuery(con, "SELECT NULL AS a"), data.frame(a = NA))
  expect_equal(dbGetQuery(con, "SELECT 1 AS a WHERE 0"), data.frame(a = logical()))
})

test_that("dbAppendTable() writes through Arrow", {
  con <- local_arrow_con()
  dbExecute(con, "CREATE TABLE t (a INTEGER, f TEXT, b BLOB, d REAL)")

  df <- data.frame(a = 1:2, f = factor(c("x", "y")))
  df$b <- I(list(as.raw(1), NULL))
  df$d <- as.Date("2020-01-02") + 0:1
  expect_warning(
    expect_equal(dbAppendTable(con, "t", df), 2L),
    "Factors converted to character"
  )

  out <- dbReadTable(con, "t")
  expect_equal(out$a, 1:2)
  expect_equal(out$f, c("x", "y"))
  expect_equal(out$b, blob::blob(as.raw(1), NULL))
  expect_equal(out$d, as.numeric(df$d))

  expect_error(dbAppendTable(con, "t", data.frame(a = I(list(1)))), "raw vectors")
  expect_error(dbAppendTable(con, "t", data.frame(a = 1L), row.names = TRUE), "row.names")
})

test_that("dbAppendTable() through Arrow writes difftime in its own units", {
  df <- data.frame(id = 1:4)
  df$d <- as.difftime(c(2, NA, 0.5, -1), units = "mins")
  df$w <- as.difftime(c(1, 2, NA, 3), units = "weeks")
  df$h <- hms::hms(c(61.5, NA, 90000, -5))

  con_default <- dbConnect(SQLite(), ":memory:")
  on.exit(dbDisconnect(con_default))
  con <- local_arrow_con()
  for (conn in list(con_default, con)) {
    dbExecute(conn, "CREATE TABLE t (id INTEGER, d REAL, w REAL, h REAL)")
    dbAppendTable(conn, "t", df)
  }

  out <- dbReadTable(con, "t")
  expect_identical(out, dbReadTable(con_default, "t"))
  expect_identical(out$d, c(2, NA, 0.5, -1))
  expect_identical(out$w, c(1, 2, NA, 3))
})

test_that("dbAppendTable() through Arrow writes POSIXlt like POSIXct", {
  df <- data.frame(id = 1:3)
  df$ts <- as.POSIXct(c("2020-01-02 03:04:05.25", NA, "1960-06-07 08:09:10"), tz = "UTC")
  df_lt <- df
  df_lt$ts <- as.POSIXlt(df$ts)

  con_default <- dbConnect(SQLite(), ":memory:")
  on.exit(dbDisconnect(con_default))
  con <- local_arrow_con()
  for (conn in list(con_default, con)) {
    dbExecute(conn, "CREATE TABLE t (id INTEGER, ts REAL)")
  }
  # The default path can only write it as POSIXct
  dbAppendTable(con_default, "t", df)
  expect_identical(dbAppendTable(con, "t", df_lt), 3L)
  expect_identical(dbReadTable(con, "t"), dbReadTable(con_default, "t"))
  expect_identical(dbReadTable(con, "t")$ts, as.numeric(df$ts))
})

test_that("dbWriteTable() and row names work through Arrow", {
  con <- local_arrow_con()
  dbWriteTable(con, "mtcars", mtcars, row.names = TRUE)
  out <- dbReadTable(con, "mtcars", row.names = TRUE)
  expect_equal(out, mtcars)

  dbWriteTable(con, "mtcars", mtcars[1:2, ], overwrite = TRUE)
  expect_equal(nrow(dbReadTable(con, "mtcars")), 2L)
  dbWriteTable(con, "mtcars", mtcars[3:4, ], append = TRUE)
  expect_equal(nrow(dbReadTable(con, "mtcars")), 4L)
})

test_that("dbGetQuery() with parameters works through Arrow", {
  con <- local_arrow_con()
  dbWriteTable(con, "t", data.frame(a = 1:5))
  expect_equal(
    dbGetQuery(con, "SELECT a FROM t WHERE a > ? ORDER BY a", params = list(3L)),
    data.frame(a = 4:5)
  )
  expect_equal(
    dbGetQuery(con, "SELECT a FROM t WHERE a = ? ORDER BY a", params = list(c(1L, 2L))),
    data.frame(a = 1:2)
  )
})

test_that("dbFetch() through Arrow handles results larger than one chunk", {
  con <- local_arrow_con()
  n <- 70000L # more than the 65536 rows of a chunk
  df_in <- data.frame(
    a = seq_len(n),
    b = c(letters, NA)[seq_len(n) %% 27 + 1],
    stringsAsFactors = FALSE
  )
  dbWriteTable(con, "t", df_in)
  expect_equal(dbReadTable(con, "t"), df_in)
  expect_equal(dbGetQuery(con, "SELECT * FROM t WHERE 0"), df_in[0, ])

  rs <- dbSendQuery(con, "SELECT * FROM t")
  expect_equal(dbFetch(rs, 3), df_in[1:3, ])
  expect_equal(nrow(dbFetch(rs)), n - 3L)
  dbClearResult(rs)
})

test_that("data frames fetched in chunks through Arrow own their strings", {
  con <- local_arrow_con()
  dbWriteTable(con, "t", data.frame(s = c("a", "b", "c"), stringsAsFactors = FALSE))
  rs <- dbSendQuery(con, "SELECT s FROM t")
  chunks <- list(dbFetch(rs, 2), dbFetch(rs, 2))
  dbClearResult(rs)
  gc()
  expect_equal(chunks[[1]]$s, c("a", "b"))
  expect_equal(chunks[[2]]$s, "c")
})

test_that("each fetch through Arrow is typed like on the default path", {
  setup <- c(
    "CREATE TABLE t (x, y INTEGER, z TEXT, w REAL, b BLOB, big, n)",
    "INSERT INTO t VALUES (NULL, NULL, NULL, NULL, NULL, NULL, NULL)",
    "INSERT INTO t VALUES (1, 2.5, NULL, 1, NULL, 1099511627776, NULL)",
    "INSERT INTO t VALUES ('a', 3, 4, NULL, x'01', 1, NULL)",
    "INSERT INTO t VALUES (NULL, NULL, 'c', 2.5, NULL, 2, NULL)",
    "INSERT INTO t VALUES (2.5, 4, NULL, NULL, 'd', NULL, NULL)",
    "INSERT INTO t VALUES (NULL, NULL, NULL, NULL, NULL, 3, 'e')"
  )
  con <- dbConnect(SQLite(), ":memory:")
  on.exit(dbDisconnect(con))
  con_arrow <- local_arrow_con()
  for (sql in setup) {
    dbExecute(con, sql)
    dbExecute(con_arrow, sql)
  }

  sequences <- list(
    c(0, -1), c(1, -1), c(2, -1), c(1, 1, 1, 1, 1, 1, 1),
    c(0, 1, 0, 2, 0, -1), c(3, 0, 1, 1, 1), c(-1, 0, 1)
  )
  for (ns in sequences) {
    for (with_info in c(FALSE, TRUE)) {
      expected <- fetch_sequence(con, "SELECT * FROM t", ns, info = with_info)
      info <- paste("n =", paste(ns, collapse = ", "), "dbColumnInfo():", with_info)
      expect_identical(
        fetch_sequence(con_arrow, "SELECT * FROM t", ns, info = with_info),
        expected,
        info = info
      )
      # Several arrays per fetch
      for (chunk_size in 1:2) {
        expect_identical(
          fetch_sequence(con_arrow, "SELECT * FROM t", ns, chunk_size = chunk_size, info = with_info),
          expected,
          info = paste(info, "chunk_size =", chunk_size)
        )
      }
    }
  }
})

test_that("dbColumnInfo() through Arrow answers like the data frames", {
  con <- dbConnect(SQLite(), ":memory:")
  on.exit(dbDisconnect(con))
  con_arrow <- local_arrow_con()
  for (conn in list(con, con_arrow)) {
    dbExecute(conn, "CREATE TABLE t (a, b TEXT)")
    dbExecute(conn, "INSERT INTO t VALUES (1, 'x'), (2.5, 'y'), ('z', NULL)")
    dbExecute(conn, "CREATE TABLE u (a INTEGER)")
    dbExecute(conn, "INSERT INTO u VALUES (NULL), ('12abc')")
    dbExecute(conn, "CREATE TABLE v (a TEXT)")
    dbExecute(conn, "INSERT INTO v VALUES ('x'), (x'410042'), (x'ff')")
  }
  steps <- function(conn, sql, steps) {
    rs <- dbSendQuery(conn, sql)
    on.exit(dbClearResult(rs))
    lapply(steps, function(n) suppressWarnings(if (is.na(n)) dbColumnInfo(rs) else dbFetch(rs, n)))
  }

  # The type of the fetched rows, not of the next row
  out <- steps(con_arrow, "SELECT * FROM t", c(2, NA, -1))
  expect_identical(out[[2]]$type, c("double", "character"))
  expect_identical(out, steps(con, "SELECT * FROM t", c(2, NA, -1)))

  # Asked before the first fetch, it decides the types like on the default path
  out <- steps(con_arrow, "SELECT * FROM u", c(NA, -1))
  expect_identical(out[[2]]$a, c(NA, 12L))
  expect_identical(out, steps(con, "SELECT * FROM u", c(NA, -1)))

  # It leaves the waiting row as it is: the blobs are not converted to text
  out <- steps(con_arrow, "SELECT * FROM v", c(NA, 1, NA, -1))
  expect_identical(out[[4]]$a, c(NA_character_, NA_character_))
  expect_identical(out[c(1, 3)], steps(con, "SELECT * FROM v", c(NA, 1, NA, -1))[c(1, 3)])

  # Before the parameters are bound, and for a statement
  for (sql in c("SELECT a FROM u WHERE a = ?", "UPDATE u SET a = 1")) {
    rs <- dbSendQuery(con, sql)
    expected <- dbColumnInfo(rs)
    dbClearResult(rs)
    rs <- dbSendQuery(con_arrow, sql)
    expect_identical(dbColumnInfo(rs), expected)
    dbClearResult(rs)
  }
})

test_that("a NULL-first column is typed by its first value through Arrow", {
  # The finding of the review: a small first fetch fixed the types
  con <- local_arrow_con()
  dbExecute(con, "CREATE TABLE t (x, y INTEGER)")
  dbExecute(con, "INSERT INTO t VALUES (NULL, NULL), (1, 2.5), ('a', 3)")

  for (n in 0:1) {
    rs <- dbSendQuery(con, "SELECT * FROM t")
    first <- dbFetch(rs, n)
    expect_warning(rest <- dbFetch(rs), "mixed type")
    dbClearResult(rs)
    expect_identical(first, data.frame(x = rep(NA, n), y = rep(NA_integer_, n)))
    expect_identical(rest$x, c(NA, 1L, 0L)[seq.int(n + 1L, 3L)])
    expect_identical(rest$y, c(NA, 2.5, 3)[seq.int(n + 1L, 3L)])
  }
})

test_that("each binding through Arrow starts from the types of the last one", {
  setup <- c(
    "CREATE TABLE t (k, v, w, s)",
    "INSERT INTO t VALUES (1, 1.5, 4294967296, 'a'), (2, NULL, 1, NULL)",
    # Not a real after the wide integer: that is a documented exception
    "INSERT INTO t VALUES (3, 2, 2, 5), (4, 'x', 'y', 1.5)"
  )
  con <- dbConnect(SQLite(), ":memory:")
  on.exit(dbDisconnect(con))
  con_arrow <- local_arrow_con()
  for (sql in setup) {
    dbExecute(con, sql)
    dbExecute(con_arrow, sql)
  }

  bind_and_fetch <- function(con, ns) {
    rs <- dbSendQuery(con, "SELECT v, w, s FROM t WHERE k = ?")
    on.exit(dbClearResult(rs))
    unlist(recursive = FALSE, lapply(c(1, 2, 3, 4, 99, 2), function(k) {
      dbBind(rs, list(k))
      lapply(ns, function(n) suppressWarnings(dbFetch(rs, n)))
    }))
  }
  for (ns in list(-1, c(0, -1), c(1, 1))) {
    expect_identical(bind_and_fetch(con_arrow, ns), bind_and_fetch(con, ns), info = paste(ns, collapse = ", "))
  }
})

test_that("results larger than one chunk are typed by all their values through Arrow", {
  sql <- paste(
    "WITH RECURSIVE cnt(i) AS (SELECT 1 UNION ALL SELECT i + 1 FROM cnt WHERE i < 70000)",
    "SELECT i,",
    "CASE WHEN i > 66000 THEN 'v' || i END AS s,",
    "CASE WHEN i > 66000 THEN i + 0.5 ELSE i END AS r,",
    "CASE WHEN i > 66000 THEN i * 1099511627776 ELSE i END AS big,",
    "NULL AS n",
    "FROM cnt"
  )
  con <- dbConnect(SQLite(), ":memory:")
  on.exit(dbDisconnect(con))
  con_arrow <- local_arrow_con()

  expected <- dbGetQuery(con, sql)
  expect_type(expected$s, "character")
  expect_type(expected$r, "double")
  expect_identical(dbGetQuery(con_arrow, sql), expected)
})

test_that("times outside a day keep their value through Arrow like on the default path", {
  sql <- c(
    "CREATE TABLE t (i INTEGER, tm TIME)",
    paste(
      "INSERT INTO t VALUES (1, 0), (2, 86400), (3, 100000), (4, -1), (5, '24:00:00'),",
      "(6, '30:00:00'), (7, 86399.9999996), (8, NULL)"
    )
  )
  con_default <- dbConnect(SQLite(), ":memory:", extended_types = TRUE)
  on.exit(dbDisconnect(con_default))
  con <- local_arrow_con(extended_types = TRUE)
  for (s in sql) {
    dbExecute(con_default, s)
    dbExecute(con, s)
  }
  query <- "SELECT tm FROM t ORDER BY i"

  expected <- dbGetQuery(con_default, query)
  expect_identical(as.numeric(expected$tm), c(0, 86400, 100000, -1, 86400, 108000, 86399.9999996, NA))
  expect_silent(out <- dbGetQuery(con, query))
  expect_identical(out, expected)
  expect_identical(fetch_sequence(con, query, c(1, 2, -1)), fetch_sequence(con_default, query, c(1, 2, -1)))

  # A stream holds times of day only
  expect_warning(
    stream_df <- as.data.frame(dbGetQueryArrow(con, query)),
    "outside the range of Arrow type time64 are NULL"
  )
  expect_identical(is.na(stream_df$tm), c(FALSE, TRUE, TRUE, TRUE, TRUE, TRUE, FALSE, TRUE))
  # and so do the data frames once a chunk has fixed the types
  rs <- dbSendQuery(con, query)
  on.exit(dbClearResult(rs), add = TRUE, after = FALSE)
  expect_silent(dbFetchArrowChunk(rs, chunk_size = 1))
  expect_warning(rest <- dbFetch(rs), "outside the range of Arrow type time64 are NULL")
  expect_identical(is.na(rest$tm), c(TRUE, TRUE, TRUE, TRUE, TRUE, FALSE, TRUE))
})

test_that("text through Arrow is read like on the default path", {
  # Text ends at its first NUL and is not checked for UTF-8
  sql <- paste(
    "SELECT 'c' AS s UNION ALL SELECT CAST(x'610062' AS TEXT) UNION ALL SELECT CAST(x'ff' AS TEXT)",
    "UNION ALL SELECT CAST(x'eda080' AS TEXT) UNION ALL SELECT NULL"
  )
  con <- dbConnect(SQLite(), ":memory:")
  on.exit(dbDisconnect(con))
  con_arrow <- local_arrow_con()

  expected <- dbGetQuery(con, sql)
  expect_identical(lapply(expected$s[1:4], charToRaw), list(charToRaw("c"), charToRaw("a"), as.raw(0xff), as.raw(c(0xed, 0xa0, 0x80))))
  expect_silent(out <- dbGetQuery(con_arrow, sql))
  expect_identical(out, expected)
  expect_identical(fetch_sequence(con_arrow, sql, c(1, 2, -1)), fetch_sequence(con, sql, c(1, 2, -1)))

  # A stream holds valid UTF-8 without NUL bytes only
  expect_warning(
    stream_df <- as.data.frame(dbGetQueryArrow(con_arrow, sql)),
    "not valid UTF-8, or hold a NUL byte, are NULL"
  )
  expect_identical(stream_df$s, c("c", NA, NA, NA, NA))
  # and so do the data frames once a chunk has fixed the types
  rs <- dbSendQuery(con_arrow, sql)
  on.exit(dbClearResult(rs), add = TRUE, after = FALSE)
  expect_silent(dbFetchArrowChunk(rs, chunk_size = 1))
  expect_warning(rest <- dbFetch(rs), "not valid UTF-8, or hold a NUL byte, are NULL")
  expect_identical(rest$s, c(NA_character_, NA, NA, NA))
})

test_that("a blob in a text column is text through Arrow only if it is valid UTF-8", {
  sql <- "SELECT 'a' AS x UNION ALL SELECT x'6869' UNION ALL SELECT x'610062' UNION ALL SELECT x'ff'"
  con_arrow <- local_arrow_con()

  # As in a stream, where the default path ends the blob at its first NUL
  # and does not check it
  messages <- character()
  out <- withCallingHandlers(
    dbGetQuery(con_arrow, sql),
    warning = function(w) {
      messages <<- c(messages, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
  expect_identical(out$x, c("a", "hi", NA, NA))
  expect_match(messages, "`x`: mixed type", all = FALSE)
  expect_match(messages, "`x`: values of type blob that are not valid UTF-8", all = FALSE)
})

test_that("dbFetch() through Arrow returns `n` rows across arrays cut short", {
  con <- local_arrow_con()
  df <- data.frame(s = strrep(letters[1:7], 90), stringsAsFactors = FALSE)
  dbWriteTable(con, "t", df)

  rs <- dbSendQuery(con, "SELECT s FROM t")
  on.exit(dbClearResult(rs), add = TRUE, after = FALSE)
  # The byte limits of this result, lowered from 1 GiB and 2^31 - 1
  result_set_bytes_limits(rs@ptr, 100, 150)
  expect_identical(dbFetch(rs, 5)$s, df$s[1:5])
  expect_false(dbHasCompleted(rs))
  expect_identical(dbFetch(rs, 5)$s, df$s[6:7])
  expect_true(dbHasCompleted(rs))
})

test_that("dbFetch() through Arrow takes a huge `n`", {
  con <- local_arrow_con()
  dbWriteTable(con, "t", data.frame(a = 1:3))
  for (n in c(2^31, 2^60, 1e300)) {
    rs <- dbSendQuery(con, "SELECT a FROM t")
    expect_identical(dbFetch(rs, n), data.frame(a = 1:3))
    dbClearResult(rs)
  }
})

test_that("dbFetch() through Arrow hands out the rows kept for a schema", {
  con <- local_arrow_con()
  dbWriteTable(con, "t", data.frame(a = 1:5))
  rs <- dbSendQuery(con, "SELECT a FROM t")
  on.exit(dbClearResult(rs), add = TRUE, after = FALSE)

  # The schema fetches the first chunk and keeps it, which fixes the types
  stream <- dbFetchArrow(rs, chunk_size = 3)
  expect_identical(stream$get_schema()$children$a$format, "l")
  expect_identical(dbFetch(rs, 0), data.frame(a = integer()))
  expect_identical(dbFetch(rs, 2), data.frame(a = 1:2))
  expect_identical(dbGetRowCount(rs), 2L)
  expect_identical(dbFetch(rs), data.frame(a = 3:5))
  expect_true(dbHasCompleted(rs))
  stream$release()
})

test_that("a handler of a fetch through Arrow can't use its result", {
  con <- local_arrow_con()
  dbExecute(con, "CREATE TABLE u (i INTEGER, x)")
  dbExecute(con, "INSERT INTO u VALUES (1, 1), (2, 'two'), (3, 3)")
  busy <- "while one of its fetches or binds is running"

  uses <- list(
    function(rs) dbFetch(rs),
    function(rs) dbFetch(rs, 0),
    function(rs) dbBind(rs, list(i = 2)),
    function(rs) dbClearResult(rs),
    function(rs) dbColumnInfo(rs),
    function(rs) dbFetchArrowChunk(rs)
  )
  for (use in uses) {
    rs <- dbSendQuery(con, "SELECT x FROM u WHERE i >= $i ORDER BY i", params = list(i = 1))
    # The mixed-type warning runs the handler in the middle of the fetch
    expect_error(
      withCallingHandlers(dbFetch(rs), warning = function(w) {
        use(rs)
        invokeRestart("muffleWarning")
      }),
      busy
    )
    # The result is usable again
    dbBind(rs, list(i = 3))
    expect_identical(dbFetch(rs), data.frame(x = 3L))
    dbClearResult(rs)
  }
})
