# Arrow arrays built from the text and blob columns of a result,
# through the internal result_fetch_arrow_chunk().
# Where the rules agree, each chunk is compared with what dbFetch() returns.

test_that("text and blob columns become utf8 and binary", {
  skip_if_not_installed("nanoarrow")
  con <- local_con()
  dbExecute(con, "CREATE TABLE t (id INTEGER, s TEXT, b BLOB, x)")
  dbExecute(con, paste0(
    "INSERT INTO t VALUES (1, NULL, NULL, NULL), (2, 'a', x'00ff', ''), ",
    "(3, '', x'', 'Gr\u00fc\u00dfe, \u65e5\u672c'), ",
    "(4, 'Gr\u00fc\u00dfe, \u65e5\u672c', NULL, NULL), (5, NULL, x'61', 'z')"
  ))

  chunks <- expect_same_chunks(con, "SELECT s, b, x FROM t ORDER BY id", -1)
  expect_equal(arrow_formats(chunks[[1]]), c(s = "u", b = "z", x = "u"))
  values <- arrow_values(chunks[[1]])
  expect_identical(
    values$s,
    c(NA, "a", "", "Gr\u00fc\u00dfe, \u65e5\u672c", NA)
  )
  expect_identical(
    values$b,
    blob::blob(NULL, as.raw(c(0, 255)), raw(), NULL, charToRaw("a"))
  )
})

test_that("numbers and blobs in a utf8 column and text in a binary one", {
  skip_if_not_installed("nanoarrow")
  con <- local_con()
  dbExecute(con, "CREATE TABLE t (id INTEGER, s, b)")
  dbExecute(con, paste0(
    "INSERT INTO t VALUES (1, NULL, NULL), (2, 'a', x'00ff'), ",
    "(3, 1, 'Gr\u00fc\u00dfe'), (4, -2.5, 3), (5, x'62', 4.5), (6, NULL, '')"
  ))

  # SQLite renders numbers as text, as the default path reads them
  chunks <- expect_same_chunks(
    con,
    "SELECT s, b FROM t ORDER BY id",
    -1,
    mixed = TRUE
  )
  expect_equal(arrow_formats(chunks[[1]]), c(s = "u", b = "z"))
  values <- arrow_values(chunks[[1]])
  expect_identical(values$s, c(NA, "a", "1", "-2.5", "b", NA))
  expect_identical(
    values$b,
    blob::blob(
      NULL,
      as.raw(c(0, 255)),
      charToRaw("Gr\u00fc\u00dfe"),
      charToRaw("3"),
      charToRaw("4.5"),
      raw()
    )
  )
})

test_that("text and blobs in int64 and double columns as SQLite reads them", {
  skip_if_not_installed("nanoarrow")
  skip_if_not_installed("bit64")
  con <- local_con()
  dbExecute(con, "CREATE TABLE t (id INTEGER, i, r)")
  dbExecute(con, paste(
    "INSERT INTO t VALUES (1, 1, 1.5), (2, '2', '2.5'),",
    "(3, ' 3.9x', x'332e35'), (4, x'34', 'abc'), (5, 'abc', NULL),",
    "(6, '1e3', '1e3')"
  ))

  chunks <- expect_same_chunks(
    con,
    "SELECT i, r FROM t ORDER BY id",
    -1,
    mixed = TRUE
  )
  expect_equal(arrow_formats(chunks[[1]]), c(i = "l", r = "g"))
  expect_identical(arrow_values(chunks[[1]])$i, c(1, 2, 3, 4, 0, 1))
  expect_identical(arrow_values(chunks[[1]])$r, c(1.5, 2.5, 3.5, 0, NA, 1000))

  # NULL where SQLite would saturate the leading integer of text or a blob,
  # as for a real beyond the range of int64
  dbExecute(con, "CREATE TABLE u (id INTEGER, i)")
  dbExecute(con, paste(
    "INSERT INTO u VALUES (1, 1), (2, '9223372036854775807'),",
    "(3, '9223372036854775808'), (4, ' -9223372036854775808'),",
    "(5, '-9223372036854775809'), (6, '000000000000000000000000000012'),",
    "(7, x'3939393939393939393939393939393939393939'), (8, '+12e300')"
  ))
  res <- local_result(con, "SELECT i FROM u ORDER BY id")
  chunk <- fetch_arrow_chunk(res)
  expect_valid_chunk(chunk)
  expect_equal(
    as.character(arrow_values(chunk, bit64::integer64())$i),
    # bit64 takes the smallest int64 for NA, the array holds it as a value
    c("1", "9223372036854775807", NA, NA, NA, "12", NA, "12")
  )
  expect_equal(chunk$children$i$null_count, 3L)
})

test_that("later chunks convert text and blobs to the types of the first", {
  skip_if_not_installed("nanoarrow")
  skip_if_not_installed("bit64")
  con <- local_con()
  dbExecute(con, "CREATE TABLE t (id INTEGER, s, b, t TEXT, z BLOB, i, n)")
  dbExecute(con, paste(
    "INSERT INTO t VALUES (1, 'a', x'00', NULL, NULL, 1, NULL),",
    "(2, 2, 'text', x'6869', 3.5, '7', 'x'),",
    "(3, x'ff', 4, 5, 'q', x'38', x'00')"
  ))
  res <- local_result(con, "SELECT s, b, t, z, i, n FROM t ORDER BY id")

  first <- fetch_arrow_chunk(res, 1)
  formats <- c(s = "u", b = "z", t = "u", z = "z", i = "l", n = "n")
  expect_equal(arrow_formats(first), formats)

  rest <- fetch_arrow_chunk(res)
  expect_valid_chunk(rest)
  expect_equal(arrow_formats(rest), formats)
  expect_identical(
    arrow_values(rest, bit64::integer64()),
    data.frame(
      s = c("2", NA),
      b = blob::blob(charToRaw("text"), charToRaw("4")),
      # TEXT affinity stores 5 as text
      t = c("hi", "5"),
      z = blob::blob(charToRaw("3.5"), charToRaw("q")),
      i = bit64::as.integer64(c(7, 8)),
      n = NA
    )
  )
  expect_true(dbHasCompleted(res))
  expect_equal(dbGetRowCount(res), 3L)
})

test_that("text that isn't valid UTF-8 is NULL in a utf8 column", {
  skip_if_not_installed("nanoarrow")
  con <- local_con()
  ascii <- strrep("61", 20)
  hex <- c(
    "61", "ff", "c3", "c0af", "eda080", "f4908080",
    paste0(ascii, "ff", ascii), paste0(ascii, "e282"),
    "c3a9", paste0(ascii, "f09f9880", ascii)
  )
  dbWriteTable(con, "t", data.frame(id = seq_along(hex), h = hex))
  bytes <- lapply(hex, function(h) {
    as.raw(strtoi(substring(h, seq(1, nchar(h), 2), seq(2, nchar(h), 2)), 16))
  })
  text <- vapply(bytes, rawToChar, character(1))
  Encoding(text) <- "UTF-8"
  valid <- c(TRUE, rep(FALSE, 7), TRUE, TRUE)

  # Text cast from blobs, and blobs after text, in a utf8 column
  res <- local_result(con, paste(
    "SELECT CAST(unhex(h) AS TEXT) AS s, iif(id = 1, 'a', unhex(h)) AS b",
    "FROM t ORDER BY id"
  ))
  chunk <- fetch_arrow_chunk(res)
  expect_valid_chunk(chunk)
  expect_equal(arrow_formats(chunk), c(s = "u", b = "u"))
  expected <- ifelse(valid, text, NA)
  expect_identical(arrow_values(chunk), data.frame(s = expected, b = expected))
  dbClearResult(res)

  # The default path passes such text through
  expect_identical(
    dbGetQuery(con, "SELECT CAST(unhex(h) AS TEXT) AS s FROM t ORDER BY id")$s,
    text
  )

  # A binary column keeps the bytes of text as they are
  chunks <- expect_same_chunks(
    con,
    paste(
      "SELECT unhex(h) AS b, iif(id = 1, x'61', CAST(unhex(h) AS TEXT)) AS s",
      "FROM t ORDER BY id"
    ),
    -1,
    mixed = TRUE
  )
  expect_identical(
    arrow_values(chunks[[1]]),
    data.frame(b = blob::as_blob(bytes), s = blob::as_blob(bytes))
  )
})

test_that("text with a NUL byte is NULL in a utf8 column", {
  skip_if_not_installed("nanoarrow")
  con <- local_con()
  values <- "(x'610062'), (x'6100'), (x'0061'), (x'00')"

  # The validator rejects NUL bytes, as R strings can't hold them;
  # the default path ends such text at the first NUL
  for (sql in c(
    paste("SELECT CAST(column1 AS TEXT) AS s FROM (VALUES", values, ")"),
    paste("SELECT column1 AS s FROM (VALUES ('a'),", values, ")")
  )) {
    res <- local_result(con, sql)
    chunk <- fetch_arrow_chunk(res)
    expect_valid_chunk(chunk)
    expect_equal(arrow_formats(chunk), c(s = "u"))
    expect_true(all(is.na(tail(arrow_values(chunk)$s, 4))))
    dbClearResult(res)
  }
  expect_identical(
    dbGetQuery(
      con,
      paste("SELECT CAST(column1 AS TEXT) AS s FROM (VALUES", values, ")")
    )$s,
    c("a", "a", "", "")
  )

  # A binary column keeps all bytes
  res <- local_result(con, paste(
    "SELECT column1 AS b FROM",
    "(VALUES (x'00'), (CAST(x'610062' AS TEXT)), (CAST(x'0061' AS TEXT)))"
  ))
  chunk <- fetch_arrow_chunk(res)
  expect_valid_chunk(chunk)
  expect_identical(
    arrow_values(chunk)$b,
    blob::blob(as.raw(0), as.raw(c(0x61, 0, 0x62)), as.raw(c(0, 0x61)))
  )
})

test_that("long text and blobs are read whole", {
  skip_if_not_installed("nanoarrow")
  con <- local_con()
  set.seed(20261112)
  data <- data.frame(id = 1:4)
  data$s <- c(
    strrep("x", 100000),
    strrep("\u00e9\u65e5", 200000),
    "",
    paste(rep("a\u00e9", 3000), collapse = "")
  )
  data$b <- blob::blob(
    as.raw(sample(0:255, 2e6, replace = TRUE)),
    raw(),
    as.raw(1:255),
    as.raw(sample(0:255, 70000, replace = TRUE))
  )
  dbWriteTable(con, "t", data)

  sql <- "SELECT s, b FROM t ORDER BY id"
  for (ns in list(-1, c(1, 1, 1, 1, 1), c(3, 2))) {
    expect_same_chunks(con, sql, ns)
  }
})

test_that("chunks of text and blobs end where dbFetch() ends", {
  skip_if_not_installed("nanoarrow")
  con <- local_con()
  id <- 1:7
  s <- strrep("\u00e9", id * 100)
  s[id %% 4 == 1] <- NA
  b <- lapply(id, function(i) if (i %% 3 != 1) as.raw(rep(i, i * 50)))
  dbWriteTable(con, "t", data.frame(id, s, b = blob::as_blob(b)))
  sql <- "SELECT s, b FROM t ORDER BY id"

  # Each vector gives the chunks of one result, up to one past its end;
  # the row stepped past a full chunk starts the next one
  for (ns in list(rep(1, 8), c(2, 2, 2, 2), c(3, 4, 1), c(7, 1), c(-1, -1))) {
    chunks <- expect_same_chunks(con, sql, ns)
    for (chunk in chunks) {
      expect_equal(arrow_formats(chunk), c(s = "u", b = "z"))
    }
  }
})

test_that("a UTF-16 database gives text as UTF-8 and blobs as their bytes", {
  skip_if_not_installed("nanoarrow")
  con <- local_con()
  dbExecute(con, "PRAGMA encoding = 'UTF-16'")
  expect_equal(dbGetQuery(con, "PRAGMA encoding")$encoding, "UTF-16le")
  dbExecute(con, "CREATE TABLE t (id INTEGER, s TEXT, b BLOB, x)")
  dbExecute(con, paste0(
    "INSERT INTO t VALUES (1, 'abc', x'6162', 'abc'), ",
    "(2, 'Gr\u00fc\u00dfe, \u65e5\u672c', 'Gr\u00fc\u00dfe', x'6162'), ",
    "(3, '', 1.5, CAST(x'00d8' AS TEXT)), ",
    "(4, NULL, x'', CAST(x'610000006200' AS TEXT))"
  ))

  chunks <- expect_same_chunks(
    con,
    "SELECT s, b FROM t ORDER BY id",
    -1,
    mixed = TRUE
  )
  values <- arrow_values(chunks[[1]])
  expect_identical(values$s, c("abc", "Gr\u00fc\u00dfe, \u65e5\u672c", "", NA))
  expect_identical(
    values$b,
    blob::blob(
      charToRaw("ab"),
      charToRaw("Gr\u00fc\u00dfe"),
      charToRaw("1.5"),
      raw()
    )
  )

  # A blob in a utf8 column keeps its bytes, where the default path
  # transcodes them from UTF-16 (#799);
  # a lone surrogate and a NUL character make the text NULL
  res <- local_result(con, "SELECT x FROM t ORDER BY id")
  chunk <- fetch_arrow_chunk(res)
  expect_valid_chunk(chunk)
  expect_identical(arrow_values(chunk)$x, c("abc", "ab", NA, NA))
})
