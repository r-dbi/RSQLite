# Where the internal result_fetch_arrow_chunk() ends a chunk before `n` rows:
# before a row whose text or blobs would take a utf8 or binary column beyond
# the 2^31 - 1 bytes that the 32-bit offsets of these types address.
# The tests lower the limit for their result with result_set_arrow_max_bytes().

test_that("a chunk ends before the row that would take a column beyond the limit", {
  skip_if_not_installed("nanoarrow")
  con <- local_con()
  # The first row of a chunk takes up to all 150 bytes of the limit,
  # a value of no bytes fits a full column,
  # and the row whose value would go beyond them starts the next chunk
  sizes <- c(150, 0, 60, 90, 1, 150, 75, 75, 1)
  write_sized_table(con, sizes)

  for (column in c("s", "b")) {
    sql <- paste("SELECT", column, "FROM t ORDER BY i")
    # The limit ends a chunk before `n` rows, or `n` before the limit
    cases <- list(
      list(n = -1, lengths = c(2, 2, 1, 1, 2, 1)),
      list(n = 3, lengths = c(2, 2, 1, 1, 2, 1)),
      list(n = 1, lengths = rep(1, 9))
    )
    for (case in cases) {
      info <- paste(column, case$n)
      res <- local_limited_result(con, sql, 150)
      chunks <- fetch_arrow_chunks(res, case$n)
      expect_equal(chunk_lengths(chunks), case$lengths, info = info)
      # No row is lost or repeated
      values <- lapply(chunks, function(chunk) arrow_values(chunk)[[column]])
      values <- if (column == "s") nchar(unlist(values)) else lengths(do.call(c, values))
      expect_equal(values, sizes, info = info)
      dbClearResult(res)
    }
  }
})

test_that("each text or blob column ends a chunk, numbers count as their text", {
  skip_if_not_installed("nanoarrow")
  con <- local_con()
  dbExecute(con, "CREATE TABLE t (i INTEGER, s, b, x)")
  # 10 bytes per column; the bytes of each column after its row in comments
  dbExecute(con, paste(
    "INSERT INTO t VALUES",
    # s 4, b 5
    "(1, 'aaaa', x'0102030405', 1.5),",
    # s 4, b 10
    "(2, NULL, x'0102030405', NULL),",
    # s 10, b 10
    "(3, 'bbbbbb', NULL, 2),",
    # b 11 starts the second chunk: b 1
    "(4, NULL, x'01', 3),",
    # s 8 as the text of the integer, b 1
    "(5, 12345678, x'', 4.5),",
    # s 11 starts the third chunk: s 3
    "(6, 123, NULL, NULL),",
    # s 3, as text that isn't valid UTF-8 is NULL
    "(7, CAST(x'ff' || zeroblob(29) AS TEXT), NULL, 7),",
    # s 9
    "(8, 'cccccc', NULL, NULL),",
    # s 12 as the text of the real starts the fourth chunk
    "(9, 1.5, x'02', 9)"
  ))
  res <- local_limited_result(con, "SELECT s, b, x FROM t ORDER BY i", 10)

  chunks <- fetch_arrow_chunks(res, converted = TRUE)
  expect_equal(chunk_lengths(chunks), c(3, 2, 3, 1))
  values <- do.call(rbind, lapply(chunks, arrow_values))
  expect_identical(
    values$s,
    c("aaaa", NA, "bbbbbb", NA, "12345678", "123", NA, "cccccc", "1.5")
  )
  expect_identical(values$b, blob::blob(
    as.raw(1:5), as.raw(1:5), NULL, as.raw(1), raw(), NULL, NULL, NULL, as.raw(2)
  ))
  expect_equal(values$x, c(1.5, NA, 2, 3, 4.5, NA, 7, NA, 9))
})

test_that("a chunk full by its rows reads ahead, one ended by the limit doesn't", {
  skip_if_not_installed("nanoarrow")
  # The step to row 5 fails, after four rows of three bytes
  con <- local_json_error_at_5()
  sql <- "SELECT json(v) AS j FROM t1"

  # The limit ends the first chunk at row 3, which the fetch has stepped to.
  # The second chunk is full with two rows: its step past them only reads
  # ahead, and keeps the error for the next fetch.
  res <- local_limited_result(con, sql, 6)
  expect_identical(arrow_values(fetch_arrow_chunk(res))$j, c("[1]", "[2]"))
  expect_false(dbHasCompleted(res))
  expect_identical(arrow_values(fetch_arrow_chunk(res, 2))$j, c("[3]", "[4]"))
  expect_false(dbHasCompleted(res))
  expect_equal(dbGetRowCount(res), 4)
  expect_error(fetch_arrow_chunk(res), "malformed JSON")
  expect_true(dbHasCompleted(res))
  expect_equal(dbGetRowCount(res), 4)
  dbClearResult(res)

  # A chunk that asks for more rows steps to row 5 and fails with it
  res <- local_limited_result(con, sql, 6)
  fetch_arrow_chunk(res)
  expect_error(fetch_arrow_chunk(res), "malformed JSON")
  expect_true(dbHasCompleted(res))
  expect_equal(dbGetRowCount(res), 2)
  dbClearResult(res)

  # The row stepped past a full chunk has storage classes of its own
  res <- local_limited_result(
    con,
    "SELECT column1 AS s FROM (VALUES ('a'), (x'62'))",
    6
  )
  expect_identical(arrow_values(fetch_arrow_chunk(res, 1))$s, "a")
  expect_coercions(
    warnings_of(chunk <- fetch_arrow_chunk(res, 1)),
    "Column `s` (utf8): 1 blob value converted (row 2)"
  )
  expect_identical(arrow_values(chunk)$s, "b")
})

test_that("a row held back reports its conversions with the chunk of its own", {
  skip_if_not_installed("nanoarrow")
  con <- local_con()
  dbExecute(con, "CREATE TABLE t (i INTEGER, s)")
  dbExecute(con, paste(
    "INSERT INTO t VALUES (1, 'a'), (2, 'bbbbbbbbb'), (3, x'636363'),",
    "(4, 4), (5, 'eeeeeeeee'), (6, 6)"
  ))
  res <- local_result(con, "SELECT s FROM t ORDER BY i")
  # Fixes `s` as character for the data frames
  expect_identical(dbFetch(res, 1)$s, "a")
  result_set_arrow_max_bytes(res@ptr, 10)

  # The blob of row 3 would take `s` to 12 bytes
  expect_length(warnings_of(chunk <- fetch_arrow_chunk(res)), 0)
  expect_identical(arrow_values(chunk)$s, "bbbbbbbbb")
  # Reading row 3 as a data frame converts its blob to text,
  # the next chunk keeps the storage class read before
  expect_warning(dbColumnInfo(res), "mixed type")
  expect_coercions(
    warnings_of(chunk <- fetch_arrow_chunk(res)),
    "Column `s` (utf8): 1 blob value converted (row 3); 1 integer value converted (row 4)"
  )
  expect_identical(arrow_values(chunk)$s, c("ccc", "4"))
  expect_coercions(
    warnings_of(chunk <- fetch_arrow_chunk(res)),
    "Column `s` (utf8): 1 integer value converted (row 6)"
  )
  expect_identical(arrow_values(chunk)$s, c("eeeeeeeee", "6"))
  expect_true(dbHasCompleted(res))
  expect_equal(dbGetRowCount(res), 6)
})

test_that("a value beyond the limit on its own fails after the rows before it", {
  skip_if_not_installed("nanoarrow")
  con <- local_con()
  write_sized_table(con, c(4, 11, 1))
  res <- local_limited_result(con, "SELECT s, b FROM t ORDER BY i", 10)

  expect_equal(fetch_arrow_chunk(res)$length, 1)
  expect_false(dbHasCompleted(res))
  expect_error(
    fetch_arrow_chunk(res),
    paste(
      "Column `s`: a value of 11 bytes exceeds the 10 bytes",
      "that an Arrow utf8 or binary array can hold."
    ),
    fixed = TRUE
  )
  # As any error of a fetch, it ends the result
  expect_true(dbHasCompleted(res))
  expect_equal(dbGetRowCount(res), 1)
  expect_equal(fetch_arrow_chunk(res)$length, 0)
  dbClearResult(res)

  # Also in the first row of a result
  res <- local_limited_result(con, "SELECT b FROM t WHERE i = 2", 10)
  expect_error(
    fetch_arrow_chunk(res),
    "Column `b`: a value of 11 bytes exceeds the 10 bytes",
    fixed = TRUE
  )
  expect_true(dbHasCompleted(res))
  expect_equal(dbGetRowCount(res), 0)
})

test_that("dbFetch() and dbBind() go on from a row held back", {
  skip_if_not_installed("nanoarrow")
  con <- local_con()
  dbExecute(con, "CREATE TABLE t (g INTEGER, i INTEGER, s)")
  dbExecute(con, paste(
    "INSERT INTO t VALUES (1, 1, 'aaaaaaaa'), (1, 2, 123), (1, 3, 456),",
    "(2, 1, x'01'), (2, 2, 'bbbbbbbbbb')"
  ))
  res <- local_result(con, "SELECT s FROM t WHERE g = ? ORDER BY i")
  result_set_arrow_max_bytes(res@ptr, 10)

  # The integer of row 2 would take `s` to 11 bytes as text.
  # A data frame reads the row with its storage class,
  # which SQLite keeps when it renders a number as text.
  dbBind(res, list(1))
  expect_equal(fetch_arrow_chunk(res)$length, 1)
  expect_identical(dbFetch(res)$s, c(123L, 456L))
  expect_true(dbHasCompleted(res))
  expect_equal(dbGetRowCount(res), 3)

  # A new execution starts with its own first row
  dbBind(res, list(1))
  expect_equal(fetch_arrow_chunk(res)$length, 1)
  dbBind(res, list(2))
  expect_equal(dbGetRowCount(res), 0)
  chunks <- fetch_arrow_chunks(res, converted = TRUE)
  expect_equal(chunk_lengths(chunks), c(1, 1))
  expect_equal(arrow_formats(chunks[[1]]), c(s = "z"))
  expect_identical(
    arrow_values(chunks[[2]])$s,
    blob::blob(charToRaw("bbbbbbbbbb"))
  )
})

test_that("chunks of blobs near 2 GiB stay within the 32-bit offsets", {
  skip_on_cran()
  # Off unless the variable is true, which the GitHub Actions checks of this
  # repository set in .github/workflows/custom/after-install
  skip_if_not(
    identical(Sys.getenv("RSQLITE_TEST_LARGE_ARROW"), "true"),
    "Needs about 2.5 GB of memory, set RSQLITE_TEST_LARGE_ARROW=true to run"
  )
  skip_if_not_installed("nanoarrow")
  con <- local_con()
  # 1e9 + 1.2e9 bytes would go beyond 2^31 - 1, 1.2e9 + 1 don't
  res <- local_result(con, paste(
    "SELECT zeroblob(1000000000) AS b",
    "UNION ALL SELECT zeroblob(1200000000) UNION ALL SELECT zeroblob(1)"
  ))

  lengths <- numeric()
  while (!dbHasCompleted(res)) {
    chunk <- fetch_arrow_chunk(res)
    lengths <- c(lengths, chunk$length)
    # Released at once, so that the chunks don't add up
    nanoarrow::nanoarrow_pointer_release(chunk)
  }
  expect_equal(lengths, c(1, 2))
})
