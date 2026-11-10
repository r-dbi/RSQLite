# Character columns as views into their Arrow arrays: `lazy_strings = TRUE`

# Whether a character vector is one of nanoarrow's views
is_lazy <- function(x) {
  any(grepl("altrep_chr", capture.output(.Internal(inspect(x)))))
}

test_that("lazy_strings is validated and recorded", {
  expect_error(dbConnect(SQLite(), lazy_strings = TRUE), "requires `arrow = TRUE`", fixed = TRUE)
  expect_error(dbConnect(SQLite(), arrow = TRUE, lazy_strings = NA), "must be `TRUE` or `FALSE`", fixed = TRUE)

  con <- local_arrow_con()
  expect_false(con@lazy_strings)
  con <- local_arrow_con(lazy_strings = TRUE)
  expect_true(con@lazy_strings)

  # Cloning keeps the option
  path <- withr::local_tempfile(fileext = ".sqlite")
  con <- dbConnect(SQLite(), path, arrow = TRUE, lazy_strings = TRUE)
  withr::defer(dbDisconnect(con))
  clone <- dbConnect(con)
  withr::defer(dbDisconnect(clone))
  expect_true(clone@lazy_strings)
})

test_that("lazy strings give the same data frames", {
  path <- withr::local_tempfile(fileext = ".sqlite")
  eager <- dbConnect(SQLite(), path, arrow = TRUE)
  withr::defer(dbDisconnect(eager))
  lazy <- dbConnect(SQLite(), path, arrow = TRUE, lazy_strings = TRUE)
  withr::defer(dbDisconnect(lazy))

  n <- 70000L # more than one chunk of a full fetch
  df_in <- data.frame(
    a = seq_len(n),
    s = c(letters, NA)[seq_len(n) %% 27 + 1],
    t = ifelse(seq_len(n) %% 5 == 0, NA_character_, paste0("value ", seq_len(n))),
    x = seq_len(n) / 7,
    stringsAsFactors = FALSE
  )
  dbWriteTable(eager, "t", df_in)

  df_eager <- dbReadTable(eager, "t")
  df_lazy <- dbReadTable(lazy, "t")
  expect_equal(df_eager, df_in)
  expect_equal(df_lazy, df_in)
  expect_false(is_lazy(df_eager$s))
  expect_true(is_lazy(df_lazy$s))
  expect_true(is_lazy(df_lazy$t))
  expect_type(df_lazy$a, "integer")

  # Chunks, an empty tail, and a zero-row result
  rs <- dbSendQuery(lazy, "SELECT * FROM t")
  chunk <- dbFetch(rs, 3)
  expect_equal(chunk, df_in[1:3, ])
  expect_true(is_lazy(chunk$s))
  rest <- dbFetch(rs)
  expect_equal(nrow(rest), n - 3L)
  expect_equal(dbFetch(rs, 3), df_in[0, ])
  dbClearResult(rs)
  expect_equal(dbGetQuery(lazy, "SELECT * FROM t WHERE 0"), df_in[0, ])

  # The view outlives the result and the connection
  con <- dbConnect(SQLite(), path, arrow = TRUE, lazy_strings = TRUE)
  df <- dbGetQuery(con, "SELECT s, t FROM t")
  dbDisconnect(con)
  gc()
  expect_equal(df$s, df_in$s)
  expect_equal(df$t, df_in$t)
})

test_that("lazy strings follow ptype", {
  con <- local_arrow_con(lazy_strings = TRUE)
  dbExecute(con, "CREATE TABLE t (id, txt, b)")
  dbExecute(con, "INSERT INTO t VALUES (1, 'a', X'0102'), (2, 'b', NULL)")

  df <- dbGetQuery(con, "SELECT * FROM t", ptype = list(id = character(), txt = factor(), b = blob::blob()))
  expect_true(is_lazy(df$id))
  expect_equal(df$id, c("1", "2"))
  expect_equal(df$txt, factor(c("a", "b")))
  expect_equal(df$b, blob::blob(as.raw(c(1, 2)), NULL))

  df <- dbGetQuery(con, "SELECT txt FROM t", ptype = list(txt = factor(levels = c("b", "a"))))
  expect_equal(df$txt, factor(c("a", "b"), levels = c("b", "a")))
})

# Lowers the bytes of string data above which concatenated strings take the
# large_utf8 type, from 2^31 - 1
local_concat_utf8_max_bytes <- function(max_bytes, envir = parent.frame()) {
  old <- arrow_set_concat_utf8_max_bytes(max_bytes)
  withr::defer(arrow_set_concat_utf8_max_bytes(old), envir = envir)
}

test_that("concatenated strings take large_utf8 beyond the 32-bit offsets", {
  concat <- function(...) {
    arrays <- lapply(list(...), nanoarrow::as_nanoarrow_array)
    out <- arrow_concat_strings(nanoarrow::basic_array_stream(arrays))
    list(
      format = nanoarrow::infer_nanoarrow_schema(out$array)$format,
      values = nanoarrow::convert_array(out$array, character())
    )
  }
  values <- c("ab", NA, "cde", "")

  expect_equal(concat(c("ab", NA), c("cde", "")), list(format = "u", values = values))
  local_concat_utf8_max_bytes(4)
  # Five bytes of strings, and four with the second array shorter
  expect_equal(concat(c("ab", NA), c("cde", "")), list(format = "U", values = values))
  expect_equal(concat(c("ab", NA), c("c", ""))$format, "u")
  # A single array is handed on as it is
  expect_equal(concat(c("ab", NA, "cde", "")), list(format = "u", values = values))
  # An empty array may come without offsets
  empty <- nanoarrow::nanoarrow_array_init(nanoarrow::na_string())
  expect_equal(concat(empty, c("ab", NA)), list(format = "u", values = c("ab", NA)))
})

test_that("lazy strings beyond the 32-bit offsets give the same data frames", {
  local_concat_utf8_max_bytes(100)
  path <- withr::local_tempfile(fileext = ".sqlite")
  eager <- dbConnect(SQLite(), path, arrow = TRUE)
  withr::defer(dbDisconnect(eager))
  lazy <- dbConnect(SQLite(), path, arrow = TRUE, lazy_strings = TRUE)
  withr::defer(dbDisconnect(lazy))
  dbWriteTable(eager, "t", data.frame(i = 1:50, s = ifelse(1:50 %% 7 == 0, NA, strrep("x", 1:50))))

  rs <- dbSendQuery(lazy, "SELECT * FROM t")
  df <- arrow_fetch_df(rs, -1, chunk_size = 8)
  dbClearResult(rs)
  expect_true(is_lazy(df$s))
  expect_equal(df, dbReadTable(eager, "t"))
})

test_that("lazy strings beyond 2 GiB take large_utf8", {
  skip_on_cran()
  # Off unless the variable is true, which the GitHub Actions checks of this
  # repository set in .github/workflows/custom/after-install
  skip_if_not(
    identical(Sys.getenv("RSQLITE_TEST_LARGE_ARROW"), "true"),
    "Needs about 2.5 GB of memory, set RSQLITE_TEST_LARGE_ARROW=true to run"
  )
  gc_until_stable()

  con <- local_arrow_con(lazy_strings = TRUE)
  # 2049 strings of 1 MiB: 2^31 + 2^20 bytes, past the 32-bit offsets
  sql <- paste(
    "WITH RECURSIVE s(i) AS (SELECT 1 UNION ALL SELECT i + 1 FROM s WHERE i < 2049)",
    "SELECT i, hex(zeroblob(524288)) AS s FROM s"
  )
  rs <- dbSendQuery(con, sql)
  # Chunks end at 64 MiB instead of 1 GiB, so that the copy into one array
  # needs little more than the column itself
  set_bytes_limits(rs, 2^26, 2^31 - 1)
  df <- dbFetch(rs)
  dbClearResult(rs)
  expect_equal(df$i, 1:2049)
  expect_true(is_lazy(df$s))
  expect_equal(nchar(df$s[c(1, 64, 65, 2048, 2049)]), rep(2^20, 5))

  # The column goes with its view, before the next test
  rm(df)
  gc_until_stable()
})

test_that("lazy fetches convert column by column to the prototypes", {
  path <- withr::local_tempfile(fileext = ".sqlite")
  eager <- dbConnect(SQLite(), path, arrow = TRUE)
  withr::defer(dbDisconnect(eager))
  lazy <- dbConnect(SQLite(), path, arrow = TRUE, lazy_strings = TRUE)
  withr::defer(dbDisconnect(lazy))
  dbExecute(eager, "CREATE TABLE t (id, big, ts, d, tm, f, fo, fl, flo, b, chr, txt, num, nul)")
  dbExecute(eager, "INSERT INTO t VALUES
    (1, 1, '2024-01-01 12:00:00', '2024-01-01', '12:34:56', 'a', 'b', 'x', 'y', X'0102', 1, 'one', 1.5, NULL),
    (2, 2, '2024-06-01 00:00:00', '2024-02-02', '00:00:01', 'b', 'a', 'y', 'x', NULL, 2, NULL, 2, NULL),
    (3, 3, NULL, NULL, NULL, 'c', NULL, NULL, 'z', X'', NULL, 'three', NULL, NULL)")
  ptype <- list(
    big = bit64::integer64(), ts = as.POSIXct(character(), tz = "Europe/Zurich"),
    d = as.Date(character()), tm = hms::hms(),
    f = factor(levels = c("b", "a")), fo = factor(levels = c("b", "a"), ordered = TRUE),
    fl = factor(), flo = ordered(character()), b = blob::blob(), chr = character()
  )

  fetch <- function(con, chunk_size) {
    rs <- dbSendQuery(con, "SELECT * FROM t", ptype = ptype)
    on.exit(dbClearResult(rs))
    arrow_fetch_df(rs, -1, chunk_size = chunk_size)
  }
  # One array against one array per row, eagerly and column by column
  expected <- fetch(eager, 3)
  expect_identical(fetch(eager, 1), expected)
  expect_identical(fetch(lazy, 3), expected)
  expect_identical(fetch(lazy, 1), expected)

  ts <- as.POSIXct(c("2024-01-01 12:00:00", "2024-06-01 00:00:00", NA), tz = "UTC")
  attr(ts, "tzone") <- "Europe/Zurich"
  expect_equal(expected$ts, ts)
  expect_equal(expected$big, bit64::as.integer64(1:3))
  expect_equal(expected$f, factor(c("a", "b", NA), levels = c("b", "a")))
  expect_equal(expected$fo, factor(c("b", "a", NA), levels = c("b", "a"), ordered = TRUE))
  expect_equal(expected$fl, factor(c("x", "y", NA)))
  expect_equal(expected$flo, ordered(c("y", "x", "z")))
  expect_equal(expected$b, blob::blob(as.raw(1:2), NULL, raw()))
  expect_equal(expected$chr, c("1", "2", NA))
  expect_type(expected$id, "integer")
  expect_type(expected$nul, "logical")

  # Only character columns stay views, factors are built from copies
  for (chunk_size in c(1, 3)) {
    df <- fetch(lazy, chunk_size)
    expect_equal(names(df)[vapply(df, is_lazy, logical(1))], c("chr", "txt"))
    df <- fetch(eager, chunk_size)
    expect_false(any(vapply(df, is_lazy, logical(1))))
  }

  # The views own their arrays
  df <- fetch(lazy, 1)
  gc()
  expect_identical(df, expected)
})

test_that("lazy fetches keep times in seconds and the coercion warning", {
  path <- withr::local_tempfile(fileext = ".sqlite")
  eager <- dbConnect(SQLite(), path, arrow = TRUE, extended_types = TRUE)
  withr::defer(dbDisconnect(eager))
  lazy <- dbConnect(SQLite(), path, arrow = TRUE, extended_types = TRUE, lazy_strings = TRUE)
  withr::defer(dbDisconnect(lazy))
  dbExecute(eager, "CREATE TABLE t (i INTEGER, s TEXT, d DATE, tm TIME, ts TIMESTAMP)")
  dbExecute(eager, "INSERT INTO t VALUES
    (1, 'a', '2024-01-01', '12:34:56.5', '2024-01-01 12:00:00'),
    (2, NULL, NULL, '25:00:00', NULL),
    ('x', 'c', '2024-02-02', NULL, '2024-06-01 00:00:00')")

  fetch <- function(con, chunk_size) {
    rs <- dbSendQuery(con, "SELECT * FROM t")
    on.exit(dbClearResult(rs))
    w <- coercion_warnings(df <- arrow_fetch_df(rs, -1, chunk_size = chunk_size))
    list(df = df, warnings = length(w))
  }
  expected <- fetch(eager, 3)
  expect_equal(expected$warnings, 1L)
  expect_s3_class(expected$df$tm, "hms")
  expect_equal(as.numeric(expected$df$tm), c(45296.5, 90000, NA))
  expect_identical(fetch(eager, 1), expected)
  expect_identical(fetch(lazy, 3), expected)
  expect_identical(fetch(lazy, 1), expected)
  expect_true(is_lazy(fetch(lazy, 1)$df$s))
})

test_that("lazy fetches count their arrays towards the collection trigger", {
  con <- local_arrow_con(lazy_strings = TRUE)
  handed_out <- function(sql) {
    arrow_gc_state$bytes <- 0
    df <- dbGetQuery(con, sql)
    arrow_gc_state$bytes
  }
  strings <- handed_out("SELECT 'abc' AS s")
  expect_gt(strings, 0)
  # The arrays of the other columns wait for the collector too
  expect_gt(handed_out("SELECT 'abc' AS s, 1 AS i"), strings)
  # A fetch without a lazy column releases its arrays right away
  expect_equal(handed_out("SELECT 1 AS i"), 0)
})
