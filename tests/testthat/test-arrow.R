# Native Arrow interface: results are filled straight from the SQLite
# statement, parameters are bound straight from Arrow arrays.

test_that("dbSendQueryArrow() returns a SQLiteResultArrow", {
  con <- local_con()
  rs <- dbSendQueryArrow(con, "SELECT 1 AS a, 'x' AS b, 1.5 AS c, x'0102' AS d, NULL AS e")
  on.exit(dbClearResult(rs))

  expect_s4_class(rs, "SQLiteResultArrow")
  expect_s4_class(rs, "DBIResultArrow")
  expect_true(dbIsValid(rs))
  expect_false(dbHasCompleted(rs))
  expect_equal(dbGetStatement(rs), "SELECT 1 AS a, 'x' AS b, 1.5 AS c, x'0102' AS d, NULL AS e")
  expect_snapshot(rs)

  stream <- dbFetchArrow(rs)
  expect_s3_class(stream, "nanoarrow_array_stream")
  expect_equal(
    schema_formats(stream),
    c(a = "l", b = "u", c = "g", d = "z", e = "n")
  )

  df <- as.data.frame(stream)
  expect_equal(df$a, 1)
  expect_equal(df$b, "x")
  expect_equal(df$c, 1.5)
  expect_equal(df$d, blob::blob(as.raw(1:2)))
  expect_true(dbHasCompleted(rs))
  expect_equal(dbGetRowCount(rs), 1L)
  expect_snapshot(rs)
})

test_that("column types come from the values, then from the declared types", {
  con <- local_con()
  dbExecute(con, "CREATE TABLE t (i INTEGER, r REAL, s TEXT, b BLOB, n NUMERIC, x)")
  dbExecute(con, "INSERT INTO t VALUES (NULL, NULL, NULL, NULL, NULL, NULL)")

  # Only NULL values: declared types decide, undeclared columns are null
  stream <- dbGetQueryArrow(con, "SELECT * FROM t")
  expect_equal(
    schema_formats(stream),
    c(i = "l", r = "g", s = "u", b = "z", n = "g", x = "n")
  )
  expect_equal(nrow(as.data.frame(stream)), 1L)

  dbExecute(con, "INSERT INTO t VALUES (1, 2.5, 'a', x'00', 3, 'text')")
  # The first non-NULL value decides, also for the undeclared column
  df <- as.data.frame(dbGetQueryArrow(con, "SELECT * FROM t ORDER BY i"))
  expect_equal(df$i, c(NA, 1))
  expect_equal(df$r, c(NA, 2.5))
  expect_equal(df$s, c(NA, "a"))
  expect_equal(df$b, blob::blob(NULL, as.raw(0)))
  expect_equal(df$n, c(NA, 3))
  expect_equal(df$x, c(NA, "text"))
})

test_that("integers widen to double within the first chunk", {
  con <- local_con()
  stream <- dbGetQueryArrow(con, "SELECT 1 AS a UNION ALL SELECT 2.5 UNION ALL SELECT NULL")
  expect_equal(schema_formats(stream), c(a = "g"))
  expect_equal(as.data.frame(stream)$a, c(1, 2.5, NA))
})

test_that("mixed types after the first chunk are coerced with a warning", {
  con <- local_con()
  dbExecute(con, "CREATE TABLE t (x)")
  dbExecute(con, "INSERT INTO t VALUES (1), (2), ('three')")

  rs <- dbSendQueryArrow(con, "SELECT x FROM t")
  on.exit(dbClearResult(rs))
  chunk <- dbFetchArrowChunk(rs, chunk_size = 2)
  expect_equal(as.data.frame(chunk)$x, c(1, 2))
  expect_warning(
    chunk <- dbFetchArrowChunk(rs, chunk_size = 2),
    class = "RSQLite_warning_coercion"
  )
  expect_equal(nanoarrow::infer_nanoarrow_schema(chunk)$children$x$format, "l")
})

test_that("64-bit integers keep their range", {
  con <- local_con()
  stream <- dbGetQueryArrow(con, "SELECT 1099511627776 AS a")
  expect_equal(schema_formats(stream), c(a = "l"))
  expect_equal(
    nanoarrow::convert_array_stream(stream, data.frame(a = bit64::integer64()))$a,
    bit64::as.integer64("1099511627776")
  )
})

test_that("extended types map to Arrow date, time and timestamp types", {
  con <- local_con(extended_types = TRUE)
  dbExecute(con, "CREATE TABLE t (d DATE, t TIME, ts TIMESTAMP, dt DATETIME)")
  dbExecute(con, "INSERT INTO t VALUES ('2020-01-02', '12:34:56.5', '2020-01-02 12:34:56.25', 1577968496.75)")
  dbExecute(con, "INSERT INTO t VALUES (NULL, NULL, NULL, NULL)")

  stream <- dbGetQueryArrow(con, "SELECT * FROM t")
  expect_equal(schema_formats(stream), c(d = "tdD", t = "ttu", ts = "tsu:UTC", dt = "tsu:UTC"))
  df <- as.data.frame(stream)
  expect_equal(df$d, as.Date(c("2020-01-02", NA)))
  expect_equal(df$t, hms::as_hms(c(45296.5, NA)))
  expect_equal(df$ts, as.POSIXct(c("2020-01-02 12:34:56.25", NA), tz = "UTC"))
  expect_equal(df$dt, as.POSIXct(c(1577968496.75, NA), origin = "1970-01-01", tz = "UTC"))
})

test_that("dbFetchArrow() streams lazily in chunks", {
  con <- local_con()
  dbWriteTable(con, "t", data.frame(a = 1:10))

  rs <- dbSendQueryArrow(con, "SELECT a FROM t ORDER BY a")
  on.exit(dbClearResult(rs))
  stream <- dbFetchArrow(rs, chunk_size = 4)

  # Nothing has been fetched yet
  expect_equal(dbGetRowCount(rs), 0L)
  expect_false(dbHasCompleted(rs))

  first <- stream$get_next()
  expect_equal(first$length, 4L)
  expect_equal(dbGetRowCount(rs), 4L)
  expect_false(dbHasCompleted(rs))

  sizes <- c(4L)
  repeat {
    chunk <- stream$get_next()
    if (is.null(chunk)) {
      break
    }
    sizes <- c(sizes, chunk$length)
  }
  expect_equal(sizes, c(4L, 4L, 2L))
  expect_true(dbHasCompleted(rs))
  expect_equal(dbGetRowCount(rs), 10L)

  # A consumed result yields an empty stream
  again <- as.data.frame(dbFetchArrow(rs))
  expect_equal(nrow(again), 0L)
  expect_equal(names(again), "a")
})

test_that("dbFetchArrowChunk() returns one chunk per call", {
  con <- local_con()
  dbWriteTable(con, "t", data.frame(a = 1:5))

  rs <- dbSendQueryArrow(con, "SELECT a FROM t ORDER BY a")
  on.exit(dbClearResult(rs))

  chunk <- dbFetchArrowChunk(rs, chunk_size = 3)
  expect_s3_class(chunk, "nanoarrow_array")
  expect_equal(as.data.frame(chunk)$a, c(1, 2, 3))
  expect_false(dbHasCompleted(rs))

  chunk <- dbFetchArrowChunk(rs, chunk_size = 3)
  expect_equal(as.data.frame(chunk)$a, c(4, 5))
  expect_true(dbHasCompleted(rs))

  chunk <- dbFetchArrowChunk(rs)
  expect_equal(chunk$length, 0L)
  expect_equal(names(as.data.frame(chunk)), "a")
})

test_that("dbFetch() and dbFetchArrow() can be mixed on one result", {
  con <- local_con()
  dbWriteTable(con, "t", data.frame(a = 1:5))

  rs <- dbSendQuery(con, "SELECT a FROM t ORDER BY a")
  on.exit(dbClearResult(rs))

  expect_equal(dbFetch(rs, n = 2)$a, 1:2)
  expect_equal(as.data.frame(dbFetchArrowChunk(rs, chunk_size = 2))$a, c(3, 4))
  expect_equal(as.data.frame(dbFetchArrow(rs))$a, 5)
  expect_true(dbHasCompleted(rs))
})

test_that("the stream stays readable after the result is cleared", {
  con <- local_con()
  dbWriteTable(con, "t", data.frame(a = 1:3))

  rs <- dbSendQueryArrow(con, "SELECT a FROM t ORDER BY a")
  stream <- dbFetchArrow(rs, chunk_size = 2)
  dbClearResult(rs)
  expect_false(dbIsValid(rs))

  expect_equal(as.data.frame(stream)$a, c(1, 2, 3))
})

test_that("dbGetQueryArrow() reads the whole result", {
  con <- local_con()
  dbWriteTable(con, "t", data.frame(a = 1:3, b = letters[1:3]))

  df <- as.data.frame(dbGetQueryArrow(con, "SELECT * FROM t ORDER BY a"))
  expect_equal(df, data.frame(a = c(1, 2, 3), b = letters[1:3]))

  df <- as.data.frame(dbGetQueryArrow(con, "SELECT * FROM t WHERE a > ?", params = list(1L)))
  expect_equal(df, data.frame(a = c(2, 3), b = letters[2:3]))
})

test_that("errors of the statement surface from the stream", {
  con <- local_con()
  dbExecute(con, "CREATE TABLE t (a)")
  dbExecute(con, "INSERT INTO t VALUES ('{\"x\": 1}'), ('{\"x\": 2}'), ('not json')")

  rs <- dbSendQueryArrow(con, "SELECT json_extract(a, '$.x') AS x FROM t")
  on.exit(dbClearResult(rs))
  stream <- dbFetchArrow(rs, chunk_size = 1)
  expect_equal(as.data.frame(stream$get_next())$x, 1)

  # The third row fails to evaluate while the second chunk is fetched
  expect_error(stream$get_next(), "malformed JSON")
})

test_that("fetching from a cleared or unbound result fails", {
  con <- local_con()
  rs <- dbSendQueryArrow(con, "SELECT 1")
  dbClearResult(rs)
  expect_error(dbFetchArrow(rs), "Invalid result set")
  expect_error(dbFetchArrowChunk(rs), "Invalid result set")

  rs <- dbSendQueryArrow(con, "SELECT ? AS a")
  on.exit(dbClearResult(rs))
  expect_error(dbFetchArrow(rs), "bound")
  expect_error(dbFetchArrowChunk(rs), "bound")
  expect_error(dbFetch(rs), "bound")
})

test_that("chunk_size is validated", {
  con <- local_con()
  rs <- dbSendQueryArrow(con, "SELECT 1")
  on.exit(dbClearResult(rs))
  expect_error(dbFetchArrow(rs, chunk_size = 0), "chunk_size")
  expect_error(dbFetchArrow(rs, chunk_size = 1.5), "chunk_size")
  expect_error(dbFetchArrowChunk(rs, chunk_size = NA), "chunk_size")
})

test_that("dbBindArrow() binds all Arrow types SQLite can store", {
  con <- local_con()
  rs <- dbSendQueryArrow(con, "SELECT ? AS a, typeof(?) AS b")
  on.exit(dbClearResult(rs))

  bind_one <- function(value) {
    # Anonymous placeholders are bound by position, the columns can't be named
    params <- structure(data.frame(value, value), names = c("", ""))
    dbBindArrow(rs, nanoarrow::as_nanoarrow_array_stream(params))
    as.data.frame(dbFetchArrow(rs))
  }

  expect_equal(bind_one(1L), data.frame(a = 1, b = "integer"))
  expect_equal(bind_one(TRUE), data.frame(a = 1, b = "integer"))
  expect_equal(bind_one(1.5), data.frame(a = 1.5, b = "real"))
  expect_equal(bind_one("x"), data.frame(a = "x", b = "text"))
  expect_equal(bind_one(factor("x")), data.frame(a = "x", b = "text"))
  na_out <- bind_one(NA)
  expect_true(is.na(na_out$a))
  expect_equal(na_out$b, "null")
  expect_equal(bind_one(as.Date("2020-01-02")), data.frame(a = 18263, b = "real"))
  expect_equal(bind_one(hms::hms(61.5)), data.frame(a = 61.5, b = "real"))
  expect_equal(
    bind_one(as.POSIXct("2020-01-02 03:04:05.5", tz = "UTC")),
    data.frame(a = 1577934245.5, b = "real")
  )
  expect_equal(
    bind_one(blob::blob(as.raw(1:3))),
    data.frame(a = blob::blob(as.raw(1:3)), b = "blob")
  )

  big <- bit64::as.integer64("1099511627776")
  out <- bind_one(big)
  expect_equal(out$a, 1099511627776)
  expect_equal(out$b, "integer")
})

test_that("dbBindArrow() consumes batches lazily and executes once per row", {
  con <- local_con()
  dbExecute(con, "CREATE TABLE t (a INTEGER, b TEXT)")

  rs <- dbSendStatement(con, "INSERT INTO t VALUES (?, ?)")
  on.exit(dbClearResult(rs))
  unnamed <- function(...) structure(data.frame(...), names = c("", ""))
  batches <- list(
    nanoarrow::as_nanoarrow_array(unnamed(1:2, c("x", "y"))),
    nanoarrow::as_nanoarrow_array(unnamed(integer(), character())),
    nanoarrow::as_nanoarrow_array(unnamed(3L, "z"))
  )
  stream <- nanoarrow::basic_array_stream(batches)
  dbBindArrow(rs, stream)
  expect_equal(dbGetRowsAffected(rs), 3L)
  dbClearResult(rs)
  on.exit(NULL)

  expect_equal(
    dbReadTable(con, "t"),
    data.frame(a = 1:3, b = c("x", "y", "z"))
  )
})

test_that("dbBindArrow() matches named placeholders", {
  con <- local_con()
  rs <- dbSendQueryArrow(con, "SELECT $a AS a, :b AS b")
  on.exit(dbClearResult(rs))

  dbBindArrow(rs, data.frame(b = 2L, a = 1L))
  expect_equal(as.data.frame(dbFetchArrow(rs)), data.frame(a = 1, b = 2))

  expect_error(dbBindArrow(rs, data.frame(a = 1L)), "No value given for placeholder b")
  expect_error(dbBindArrow(rs, data.frame(a = 1L, b = 2L, c = 3L)), "Named parameters not used")
  expect_error(dbBindArrow(rs, structure(data.frame(1L, 2L), names = c("", ""))), "No value given")
})

test_that("dbBindArrow() rejects the wrong number and shape of parameters", {
  con <- local_con()
  rs <- dbSendQueryArrow(con, "SELECT ? AS a")
  on.exit(dbClearResult(rs))

  unnamed <- function(...) structure(data.frame(...), names = rep("", ...length()))
  expect_error(dbBindArrow(rs, unnamed(1L, 2L)), "Query requires 1 params")
  expect_error(dbBindArrow(rs, data.frame(a = 1L)), "Cannot use named parameters")
  skip_if_not_installed("vctrs")
  nested <- unnamed(1L)
  nested[[1]] <- vctrs::list_of(1:2)
  expect_error(dbBindArrow(rs, nested), "Can't bind Arrow type")
  not_a_struct <- nanoarrow::basic_array_stream(list(nanoarrow::as_nanoarrow_array(1:3)))
  expect_error(dbBindArrow(rs, not_a_struct), "struct")

})

test_that("dbBindArrow() rejects parameters for a query without placeholders", {
  con <- local_con()
  rs <- dbSendQueryArrow(con, "SELECT 1 AS a")
  on.exit(dbClearResult(rs))
  expect_error(dbBindArrow(rs, structure(data.frame(1L), names = "")), "does not require parameters")
})

test_that("dbAppendTableArrow() appends rows and reports their number", {
  con <- local_con()
  dbExecute(con, "CREATE TABLE t (a INTEGER, b TEXT)")

  expect_equal(dbAppendTableArrow(con, "t", data.frame(a = 1:2, b = c("x", "y"))), 2L)
  expect_equal(dbAppendTableArrow(con, "t", data.frame(b = "z")), 1L)
  expect_equal(dbAppendTableArrow(con, "t", data.frame(a = integer(), b = character())), 0L)
  expect_equal(
    dbReadTable(con, "t"),
    data.frame(a = c(1L, 2L, NA), b = c("x", "y", "z"))
  )

  expect_error(dbAppendTableArrow(con, "t", data.frame(c = 1L)))
  expect_error(dbAppendTableArrow(con, "t", data.frame()), "at least one column")
  expect_error(dbAppendTableArrow(con, "missing", data.frame(a = 1L)))
  # The failed append leaves the table unchanged
  expect_equal(nrow(dbReadTable(con, "t")), 3L)
})

test_that("dbWriteTableArrow() and dbCreateTableArrow() create tables from Arrow data", {
  con <- local_con()
  stream <- nanoarrow::as_nanoarrow_array_stream(data.frame(a = 1:2, b = c(1.5, NA), c = c("x", "y")))
  dbWriteTableArrow(con, "t", stream)
  expect_equal(dbReadTable(con, "t"), data.frame(a = 1:2, b = c(1.5, NA), c = c("x", "y")))

  expect_error(dbWriteTableArrow(con, "t", data.frame(a = 3L)), "exists")
  dbWriteTableArrow(con, "t", data.frame(a = 3L), append = TRUE)
  expect_equal(dbReadTable(con, "t")$a, 1:3)
  dbWriteTableArrow(con, "t", data.frame(a = 4L), overwrite = TRUE)
  expect_equal(dbReadTable(con, "t"), data.frame(a = 4L))

  # The schema of a stream is enough to create the table, the stream is not consumed
  stream <- nanoarrow::as_nanoarrow_array_stream(data.frame(x = bit64::as.integer64(1), y = "a"))
  dbCreateTableArrow(con, "u", stream)
  expect_equal(dbListFields(con, "u"), c("x", "y"))
  expect_equal(dbAppendTableArrow(con, "u", stream), 1L)
  expect_equal(dbReadTable(con, "u"), data.frame(x = 1L, y = "a"))

  dbCreateTableArrow(con, "v", nanoarrow::infer_nanoarrow_schema(data.frame(z = 1)), field.types = c(z = "TEXT"))
  expect_equal(dbGetQuery(con, "SELECT type FROM pragma_table_info('v')")$type, "TEXT")
})

test_that("dbReadTableArrow() reads a table", {
  con <- local_con()
  dbWriteTable(con, "t", data.frame(a = c(1.5, 2.5)))
  expect_equal(as.data.frame(dbReadTableArrow(con, "t")), data.frame(a = c(1.5, 2.5)))
})
