# dbConnect(arrow = TRUE): data frames travel through Arrow

local_arrow_con <- function(..., envir = parent.frame()) {
  con <- dbConnect(SQLite(), ":memory:", arrow = TRUE, ...)
  withr::defer(dbDisconnect(con), envir = envir)
  con
}

test_that("the arrow argument is validated and recorded", {
  con <- local_arrow_con()
  expect_true(con@arrow)

  con2 <- dbConnect(SQLite(), ":memory:")
  on.exit(dbDisconnect(con2))
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
  on.exit(dbClearResult(rs))
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
  on.exit(dbClearResult(rs))
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

test_that("text through Arrow ends at its first NUL like on the default path", {
  sql <- "SELECT CAST(x'610062' AS TEXT) AS s UNION ALL SELECT 'c' UNION ALL SELECT NULL"
  con <- dbConnect(SQLite(), ":memory:")
  on.exit(dbDisconnect(con))
  con_arrow <- local_arrow_con()

  expect_identical(dbGetQuery(con_arrow, sql), dbGetQuery(con, sql))
  expect_identical(dbGetQuery(con_arrow, sql)$s, c("a", "c", NA))

  # An Arrow chunk keeps all three bytes
  rs <- dbSendQueryArrow(con_arrow, sql)
  on.exit(dbClearResult(rs), add = TRUE, after = FALSE)
  chunk <- dbFetchArrowChunk(rs)
  expect_identical(nanoarrow::convert_buffer(chunk$children$s$buffers[[2]]), c(0L, 3L, 4L, 4L))
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

# The data frames of a sequence of fetches; `chunk_size` sets the rows per
# Arrow array of a fetch through Arrow
fetch_sequence <- function(con, sql, ns, chunk_size = NULL) {
  rs <- dbSendQuery(con, sql)
  on.exit(dbClearResult(rs))
  lapply(ns, function(n) {
    suppressWarnings(
      if (is.null(chunk_size)) {
        dbFetch(rs, n)
      } else {
        arrow_fetch_df(rs, n, chunk_size = chunk_size)
      }
    )
  })
}

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
    expected <- fetch_sequence(con, "SELECT * FROM t", ns)
    info <- paste("n =", paste(ns, collapse = ", "))
    expect_identical(fetch_sequence(con_arrow, "SELECT * FROM t", ns), expected, info = info)
    # Several arrays per fetch
    for (chunk_size in 1:2) {
      expect_identical(
        fetch_sequence(con_arrow, "SELECT * FROM t", ns, chunk_size = chunk_size),
        expected,
        info = paste(info, "chunk_size =", chunk_size)
      )
    }
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

test_that("dbFetch() through Arrow returns `n` rows across arrays cut short", {
  old <- arrow_set_bytes_limits(100, 150)
  withr::defer(arrow_set_bytes_limits(old[[1]], old[[2]]))

  con <- local_arrow_con()
  df <- data.frame(s = strrep(letters[1:7], 90), stringsAsFactors = FALSE)
  dbWriteTable(con, "t", df)

  rs <- dbSendQuery(con, "SELECT s FROM t")
  on.exit(dbClearResult(rs))
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
  on.exit(dbClearResult(rs))

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
