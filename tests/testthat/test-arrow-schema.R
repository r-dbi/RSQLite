# Requesting Arrow types for result columns with `schema`

# Every array that these tests read is checked with arrow's ValidateFull()
# where arrow is installed: these read their streams to the end at once, the
# lazy streams of dbFetchArrow() are checked where they are read
dbGetQueryArrow <- function(...) arrow_validated(DBI::dbGetQueryArrow(...))
dbReadTableArrow <- function(...) arrow_validated(DBI::dbReadTableArrow(...))
dbFetchArrowChunk <- function(...) arrow_validated(DBI::dbFetchArrowChunk(...))

test_that("a requested type is used without looking at the values", {
  con <- local_con()
  dbExecute(con, "CREATE TABLE t (x, y)")
  dbExecute(con, "INSERT INTO t VALUES (1, 'a'), (2.5, 'b')")

  # Decided from the values: x widens to double
  expect_equal(schema_formats(dbGetQueryArrow(con, "SELECT * FROM t")), c(x = "g", y = "u"))

  # Requested: x stays int64 and the real is truncated with a warning, y is decided
  rs <- dbSendQueryArrow(con, "SELECT * FROM t", schema = list(x = nanoarrow::na_int64()))
  expect_warning(chunk <- dbFetchArrowChunk(rs), class = "RSQLite_warning_coercion")
  dbClearResult(rs)
  expect_equal(schema_formats(chunk), c(x = "l", y = "u"))
  df <- as.data.frame(chunk)
  expect_equal(df$x, c(1, 2))
  expect_equal(df$y, c("a", "b"))

  # A requested type does not depend on the chunk size, nor on NULL first rows
  dbExecute(con, "CREATE TABLE u (x)")
  dbExecute(con, "INSERT INTO u VALUES (NULL), (NULL), (1.5)")
  rs <- dbSendQueryArrow(con, "SELECT x FROM u", schema = list(x = nanoarrow::na_double()))
  on.exit(dbClearResult(rs))
  stream <- dbFetchArrow(rs, chunk_size = 1)
  expect_equal(schema_formats(stream), c(x = "g"))
  expect_equal(as.data.frame(arrow_validated(stream))$x, c(NA, NA, 1.5))
})

# The formats of a query's result, with the stream consumed
query_formats <- function(con, sql, ...) {
  stream <- dbGetQueryArrow(con, sql, ...)
  on.exit(stream$release())
  schema_formats(stream)
}

test_that("schema accepts a struct schema, a named list, and an arrow Schema", {
  con <- local_con()
  s1 <- nanoarrow::na_struct(list(a = nanoarrow::na_int32()))
  expect_equal(query_formats(con, "SELECT 1 AS a, 2 AS b", schema = s1), c(a = "i", b = "l"))
  expect_equal(
    query_formats(con, "SELECT 1 AS a, 2 AS b", schema = list(b = nanoarrow::na_int8())),
    c(a = "l", b = "c")
  )
  # Entries may come in any order
  expect_equal(
    query_formats(con, "SELECT 1 AS a, 2 AS b", schema = list(b = nanoarrow::na_int8(), a = nanoarrow::na_bool())),
    c(a = "b", b = "c")
  )
  skip_if_not_installed("arrow")
  expect_equal(
    query_formats(con, "SELECT 1 AS a", schema = arrow::schema(a = arrow::float32())),
    c(a = "f")
  )
})

test_that("schema entries are matched by name, exactly", {
  con <- local_con()
  int32 <- nanoarrow::na_int32()
  expect_error(dbGetQueryArrow(con, "SELECT 1 AS abc", schema = list(ab = int32)), "not in the result: `ab`")
  expect_error(dbGetQueryArrow(con, "SELECT 1 AS a", schema = list(A = int32)), "not in the result: `A`")
  expect_error(dbGetQueryArrow(con, "SELECT 1 AS a, 2 AS a", schema = list(a = int32)), "more than once: `a`")
  expect_error(
    dbGetQueryArrow(con, "SELECT 1 AS b, 2 AS a, 3 AS b, 4 AS c, 5 AS c", schema = list(a = int32, c = int32, b = int32)),
    "more than once: `c`, `b`$"
  )
  # Only the requested names matter
  expect_equal(query_formats(con, "SELECT 1 AS a, 2 AS b, 3 AS b", schema = list(a = int32)), c(a = "i", b = "l", b = "l"))
  expect_error(dbGetQueryArrow(con, "SELECT 1 AS a", schema = list(int32)), "named")
  expect_error(dbGetQueryArrow(con, "SELECT 1 AS a", schema = list(a = int32, a = int32)), "Duplicate names")
  expect_error(dbGetQueryArrow(con, "SELECT 1 AS a", schema = int32), "struct")
  expect_error(dbGetQueryArrow(con, "SELECT 1 AS a", schema = data.frame(a = integer())), "infer_nanoarrow_schema")

  # A failed request leaves no open result behind, also when `schema` itself
  # fails or is malformed, which is found before the query is sent
  expect_error(dbSendQueryArrow(con, "SELECT 1 AS a", schema = list(b = int32)))
  expect_error(dbSendQueryArrow(con, "SELECT 1 AS a", schema = list(a = nanoarrow::na_time32("us"))))
  expect_error(dbGetQueryArrow(con, "SELECT 1 AS a", schema = list(a = stop("oops"))), "oops")
  expect_no_warning(as.data.frame(dbGetQueryArrow(con, "SELECT 1 AS a")))
  dbExecute(con, "CREATE TABLE t (a)")
  expect_error(dbSendQueryArrow(con, "INSERT INTO t VALUES (1) RETURNING a", schema = int32), "struct")
  expect_equal(dbGetQuery(con, "SELECT COUNT(*) AS n FROM t")$n, 0L)
  # The names need the result: the statement has run
  expect_error(dbSendQueryArrow(con, "INSERT INTO t VALUES (1) RETURNING a", schema = list(b = int32)), "`b`")
  expect_equal(dbGetQuery(con, "SELECT COUNT(*) AS n FROM t")$n, 1L)
  expect_no_warning(as.data.frame(dbGetQueryArrow(con, "SELECT 1 AS a")))
})

test_that("unsupported types are rejected when the query is sent", {
  con <- local_con()
  expect_error(
    dbSendQueryArrow(con, "SELECT 1 AS a", schema = list(a = nanoarrow::na_list(nanoarrow::na_int32()))),
    "Can't fill a column of Arrow type list<item: int32> \\(column `a`\\)"
  )
  expect_error(
    dbSendQueryArrow(con, "SELECT 1 AS a", schema = list(a = nanoarrow::na_decimal128(10, 2))),
    "decimal"
  )
  expect_error(
    dbSendQueryArrow(con, "SELECT 1 AS a", schema = list(a = nanoarrow::na_dictionary(nanoarrow::na_string()))),
    "column `a`"
  )
})

test_that("every supported type can be requested", {
  con <- local_con()
  dbExecute(con, "CREATE TABLE t (x)")
  dbExecute(con, "INSERT INTO t VALUES (7), (NULL)")

  fetch_as <- function(type, sql = "SELECT x FROM t") {
    stream <- dbGetQueryArrow(con, sql, schema = list(x = type))
    list(format = schema_formats(stream)[["x"]], x = as.data.frame(stream)$x)
  }

  expect_equal(fetch_as(nanoarrow::na_bool()), list(format = "b", x = c(TRUE, NA)))
  expect_equal(fetch_as(nanoarrow::na_int8()), list(format = "c", x = c(7L, NA)))
  expect_equal(fetch_as(nanoarrow::na_int16()), list(format = "s", x = c(7L, NA)))
  expect_equal(fetch_as(nanoarrow::na_int32()), list(format = "i", x = c(7L, NA)))
  expect_equal(fetch_as(nanoarrow::na_int64()), list(format = "l", x = c(7, NA)))
  expect_equal(fetch_as(nanoarrow::na_uint8()), list(format = "C", x = c(7L, NA)))
  expect_equal(fetch_as(nanoarrow::na_uint16()), list(format = "S", x = c(7L, NA)))
  expect_equal(fetch_as(nanoarrow::na_uint32())$format, "I")
  expect_equal(as.numeric(fetch_as(nanoarrow::na_uint32())$x), c(7, NA))
  expect_equal(fetch_as(nanoarrow::na_uint64())$format, "L")
  expect_equal(as.numeric(fetch_as(nanoarrow::na_uint64())$x), c(7, NA))
  expect_equal(fetch_as(nanoarrow::na_float()), list(format = "f", x = c(7, NA)))
  expect_equal(fetch_as(nanoarrow::na_double()), list(format = "g", x = c(7, NA)))
  expect_equal(fetch_as(nanoarrow::na_string()), list(format = "u", x = c("7", NA)))
  expect_equal(fetch_as(nanoarrow::na_large_string()), list(format = "U", x = c("7", NA)))
  # A number into a binary type is a coercion
  expect_warning(
    expect_equal(fetch_as(nanoarrow::na_binary()), list(format = "z", x = blob::blob(charToRaw("7"), NULL))),
    class = "RSQLite_warning_coercion"
  )
  expect_warning(
    expect_equal(fetch_as(nanoarrow::na_large_binary()), list(format = "Z", x = blob::blob(charToRaw("7"), NULL))),
    class = "RSQLite_warning_coercion"
  )
  expect_warning(na <- fetch_as(nanoarrow::na_na()), class = "RSQLite_warning_coercion")
  expect_equal(na$format, "n")
  expect_equal(is.na(na$x), c(TRUE, TRUE))

  dbExecute(con, "CREATE TABLE d (x)")
  dbExecute(con, "INSERT INTO d VALUES ('2020-01-02'), (NULL)")
  sql <- "SELECT x FROM d"
  expect_equal(fetch_as(nanoarrow::na_date32(), sql), list(format = "tdD", x = as.Date(c("2020-01-02", NA))))
  date64 <- fetch_as(nanoarrow::na_date64(), sql)
  expect_equal(date64$format, "tdm")
  expect_equal(as.numeric(as.Date(date64$x)), c(as.numeric(as.Date("2020-01-02")), NA))

  dbExecute(con, "CREATE TABLE tm (x)")
  dbExecute(con, "INSERT INTO tm VALUES ('01:02:03.5'), (NULL)")
  sql <- "SELECT x FROM tm"
  secs <- 3723.5
  expect_equal(fetch_as(nanoarrow::na_time32("s"), sql), list(format = "tts", x = hms::hms(c(3724, NA))))
  expect_equal(fetch_as(nanoarrow::na_time32("ms"), sql), list(format = "ttm", x = hms::hms(c(secs, NA))))
  expect_equal(fetch_as(nanoarrow::na_time64("us"), sql), list(format = "ttu", x = hms::hms(c(secs, NA))))
  expect_equal(fetch_as(nanoarrow::na_time64("ns"), sql), list(format = "ttn", x = hms::hms(c(secs, NA))))

  dbExecute(con, "CREATE TABLE ts (x)")
  dbExecute(con, "INSERT INTO ts VALUES ('2020-01-02 03:04:05.25'), (NULL)")
  sql <- "SELECT x FROM ts"
  utc <- as.POSIXct(c("2020-01-02 03:04:05.25", NA), tz = "UTC")
  expect_equal(fetch_as(nanoarrow::na_timestamp("s", "UTC"), sql), list(format = "tss:UTC", x = as.POSIXct(c("2020-01-02 03:04:05", NA), tz = "UTC")))
  expect_equal(fetch_as(nanoarrow::na_timestamp("ms", "UTC"), sql), list(format = "tsm:UTC", x = utc))
  expect_equal(fetch_as(nanoarrow::na_timestamp("us", "UTC"), sql), list(format = "tsu:UTC", x = utc))
  # Nanoseconds since the epoch exceed the precision of a double, nanoarrow says so
  expect_warning(
    zurich <- fetch_as(nanoarrow::na_timestamp("ns", "Europe/Zurich"), sql),
    "loss of precision"
  )
  expect_equal(zurich$format, "tsn:Europe/Zurich")
  expect_equal(as.numeric(zurich$x), as.numeric(utc))
  expect_equal(attr(zurich$x, "tzone"), "Europe/Zurich")
})

test_that("the chunk kept for the schema is split in every requested type", {
  con <- local_con()
  dbExecute(con, "CREATE TABLE t (x)")
  dbExecute(con, "WITH RECURSIVE s(x) AS (SELECT 1 UNION ALL SELECT x + 1 FROM s WHERE x < 10) INSERT INTO t SELECT x FROM s")
  dbExecute(con, "UPDATE t SET x = NULL WHERE x IN (2, 7)")
  schema <- list(
    bool = nanoarrow::na_bool(), i8 = nanoarrow::na_int8(), i16 = nanoarrow::na_int16(),
    i32 = nanoarrow::na_int32(), i64 = nanoarrow::na_int64(), u8 = nanoarrow::na_uint8(),
    u16 = nanoarrow::na_uint16(), u32 = nanoarrow::na_uint32(), u64 = nanoarrow::na_uint64(),
    f32 = nanoarrow::na_float(), f64 = nanoarrow::na_double(),
    s = nanoarrow::na_string(), ls = nanoarrow::na_large_string(),
    b = nanoarrow::na_binary(), lb = nanoarrow::na_large_binary(),
    d32 = nanoarrow::na_date32(), d64 = nanoarrow::na_date64(),
    t32 = nanoarrow::na_time32("ms"), t64 = nanoarrow::na_time64("ns"),
    ts = nanoarrow::na_timestamp("s", "UTC"), n = nanoarrow::na_na()
  )
  sql <- paste(
    "SELECT", paste0("x AS ", names(schema)[1:11], collapse = ", "),
    ", CAST(x AS TEXT) AS s, CAST(x AS TEXT) AS ls, CAST(x AS BLOB) AS b, CAST(x AS BLOB) AS lb,",
    "date('2020-01-01', '+' || x || ' days') AS d32, date('2020-01-01', '+' || x || ' days') AS d64,",
    "time(0, '+' || x || ' seconds') AS t32, time(0, '+' || x || ' seconds') AS t64,",
    "datetime(0, '+' || x || ' hours') AS ts, NULL AS n, x AS open FROM t ORDER BY rowid"
  )
  whole <- as.data.frame(dbGetQueryArrow(con, sql, schema = schema))

  rs <- dbSendQueryArrow(con, sql, schema = schema)
  on.exit(dbClearResult(rs))
  stream <- dbFetchArrow(rs, chunk_size = 8)
  # The column without a requested type needs the first 8 rows
  expect_equal(schema_formats(stream)[["open"]], "l")

  chunks <- list()
  repeat {
    chunk <- dbFetchArrowChunk(rs, chunk_size = 3)
    if (chunk$length == 0) {
      break
    }
    chunks <- c(chunks, list(chunk))
  }
  expect_equal(vapply(chunks, function(chunk) chunk$length, numeric(1)), c(3, 3, 2, 2))
  expect_equal(as.data.frame(nanoarrow::basic_array_stream(chunks)), whole)
  expect_equal(whole$u8, c(1L, NA, 3:6, NA, 8:10))
  expect_equal(whole$ls, as.character(c(1, NA, 3:6, NA, 8:10)))
})

test_that("values out of range and coercions are reported per the rules", {
  con <- local_con()
  dbExecute(con, "CREATE TABLE t (x)")
  dbExecute(con, "INSERT INTO t VALUES (200), (-1), ('abc'), (2.5), (X'ff'), (1e10)")

  w <- NULL
  df <- withCallingHandlers(
    as.data.frame(dbGetQueryArrow(con, "SELECT x FROM t", schema = list(x = nanoarrow::na_uint8()))),
    RSQLite_warning_coercion = function(cnd) {
      w <<- cnd
      invokeRestart("muffleWarning")
    }
  )
  expect_equal(df$x, c(200L, NA, 0L, 2L, 0L, NA))
  values <- w$coercions[[1]]$values
  expect_equal(
    vapply(values, function(v) paste(v$class, v$reason), ""),
    c("integer out_of_range", "string converted", "real converted", "blob converted", "real out_of_range")
  )
  expect_equal(vapply(values, `[[`, 1, "rows"), c(2, 3, 4, 5, 6))

  # Silent: integers into double and text, text into binary
  expect_no_warning(as.data.frame(dbGetQueryArrow(con, "SELECT 1 AS x", schema = list(x = nanoarrow::na_double()))))
  expect_equal(
    expect_no_warning(as.data.frame(dbGetQueryArrow(con, "SELECT 1 AS x UNION ALL SELECT 2.5", schema = list(x = nanoarrow::na_string())))$x),
    c("1", "2.5")
  )
  expect_equal(
    expect_no_warning(as.data.frame(dbGetQueryArrow(con, "SELECT 'ab' AS x", schema = list(x = nanoarrow::na_binary())))$x),
    blob::blob(charToRaw("ab"))
  )
  # A number into binary is a coercion
  expect_warning(
    as.data.frame(dbGetQueryArrow(con, "SELECT 1 AS x", schema = list(x = nanoarrow::na_binary()))),
    class = "RSQLite_warning_coercion"
  )
})

test_that("float keeps to its range, bool takes a real as true unless zero", {
  con <- local_con()
  dbExecute(con, "CREATE TABLE t (x)")
  dbExecute(con, "INSERT INTO t VALUES (1.5), (3.4e38), (1e300), (-1e300), (9e999), ('1e300'), (16777217), (0.0)")

  w <- coercion_warnings(
    array <- arrow_validated(nanoarrow::as_nanoarrow_array(
      dbGetQueryArrow(con, "SELECT x FROM t", schema = list(x = nanoarrow::na_float()))
    ))
  )
  expect_equal(
    nanoarrow::convert_array(array$children$x, double()),
    c(1.5, as.numeric(3.4e38), NA, NA, Inf, NA, 16777216, 0),
    tolerance = 1e-7
  )
  expect_equal(
    vapply(w[[1]]$coercions[[1]]$values, function(v) paste(v$class, v$reason, paste(v$rows, collapse = " ")), ""),
    c("real out_of_range 3 4", "string out_of_range 6")
  )

  dbExecute(con, "DELETE FROM t")
  dbExecute(con, "INSERT INTO t VALUES (0.5), (-0.9), (0.0), (2), (0), ('true'), ('2')")
  w <- coercion_warnings(
    array <- arrow_validated(nanoarrow::as_nanoarrow_array(
      dbGetQueryArrow(con, "SELECT x FROM t", schema = list(x = nanoarrow::na_bool()))
    ))
  )
  expect_equal(nanoarrow::convert_array(array$children$x), c(TRUE, TRUE, FALSE, TRUE, FALSE, FALSE, TRUE))
  expect_equal(
    vapply(w[[1]]$coercions[[1]]$values, function(v) paste(v$class, v$reason, paste(v$rows, collapse = " ")), ""),
    c("real converted 1 2 3", "string converted 6 7")
  )
})

# Compares the values of a 64-bit integer array exactly with `expected`, as
# strings, NA for NULL: a uint64 above 2^63 - 1 is written as the int64 with
# its bits, such as "-1" for 2^64 - 1
expect_int64_bits <- function(array, expected) {
  is_null <- suppressWarnings(is.na(nanoarrow::convert_array(array, double())))
  expect_equal(is_null, is.na(expected))
  actual <- matrix(as.raw(array$buffers[[2]])[seq_len(8 * array$length)], nrow = 8)
  # bit64 reads -2^63, its NA, with a warning, but with the right bits
  wanted <- suppressWarnings(bit64::as.integer64(expected))
  wanted <- matrix(writeBin(unclass(wanted), raw()), nrow = 8)
  expect_equal(actual[, !is_null], wanted[, !is_null])
}

test_that("numbers beyond 64 bits are out of range, not saturated", {
  con <- local_con()
  dbExecute(con, "CREATE TABLE t (x)")
  # SQLite stores an integer literal beyond 64 bits as a real:
  # 18446744073709551615 becomes 2^64, 9223372036854775808 is 2^63
  dbExecute(con, paste(
    "INSERT INTO t VALUES (9223372036854775807), (-9223372036854775808), (-1),",
    "(18446744073709551615), (9223372036854775808), (1e19), (1e30), (-1e30), (9e999),",
    "('18446744073709551615'), ('99999999999999999999'), ('-9223372036854775809'),",
    "('9223372036854775807'), (' -9223372036854775808x'), (2.5)"
  ))
  fetch <- function(type) {
    w <- coercion_warnings(
      array <- nanoarrow::as_nanoarrow_array(dbGetQueryArrow(con, "SELECT x FROM t", schema = list(x = type)))
    )
    values <- w[[1]]$coercions[[1]]$values
    list(
      array = array$children$x,
      reasons = vapply(values, function(v) paste(v$class, v$reason, paste(v$rows, collapse = " ")), "")
    )
  }

  int64 <- fetch(nanoarrow::na_int64())
  expect_int64_bits(int64$array, c(
    "9223372036854775807", "-9223372036854775808", "-1",
    NA, NA, NA, NA, NA, NA,
    NA, NA, NA,
    "9223372036854775807", "-9223372036854775808", "2"
  ))
  expect_equal(int64$reasons, c(
    "real out_of_range 4 5 6 7 8 9", "string out_of_range 10 11 12",
    "string converted 13 14", "real converted 15"
  ))

  uint64 <- fetch(nanoarrow::na_uint64())
  expect_int64_bits(uint64$array, c(
    "9223372036854775807", NA, NA,
    NA, "-9223372036854775808", "-8446744073709551616", NA, NA, NA,
    "-1", NA, NA,
    "9223372036854775807", NA, "2"
  ))
  expect_equal(uint64$reasons, c(
    "integer out_of_range 2 3", "real out_of_range 4 7 8 9", "real converted 5 6 15",
    "string converted 10 13", "string out_of_range 11 12 14"
  ))
})

test_that("numbers of days outside the range of a date type are NULL", {
  con <- local_con()
  dbExecute(con, "CREATE TABLE t (x)")
  dbExecute(con, paste(
    "INSERT INTO t VALUES (18000), (18000.9), (-0.5), (2147483647), (2147483648), (4294985296),",
    "(106751991167), (106751991168), (9007199254740993), (1e30), (-1e30), ('2020-01-02'), ('abc')"
  ))
  fetch <- function(type) {
    w <- coercion_warnings(
      array <- nanoarrow::as_nanoarrow_array(dbGetQueryArrow(con, "SELECT x FROM t", schema = list(x = type)))
    )
    values <- w[[1]]$coercions[[1]]$values
    list(
      array = array$children$x,
      reasons = vapply(values, function(v) paste(v$class, v$reason, paste(v$rows, collapse = " ")), "")
    )
  }

  date32 <- fetch(nanoarrow::na_date32())
  expect_equal(
    as.numeric(nanoarrow::convert_array(date32$array)),
    c(18000, 18000, 0, 2147483647, NA, NA, NA, NA, NA, NA, NA, 18263, NA)
  )
  expect_equal(date32$reasons, c(
    "integer out_of_range 5 6 7 8 9", "real out_of_range 10 11", "string unparsable 13"
  ))

  # Milliseconds, exactly
  date64 <- fetch(nanoarrow::na_date64())
  ms <- function(days) format(bit64::as.integer64(days) * 86400000L, scientific = FALSE)
  expect_int64_bits(date64$array, c(
    ms(18000), ms(18000), "0", ms(2147483647), ms(2147483648), ms(4294985296),
    ms(106751991167), NA, NA, NA, NA, ms(18263), NA
  ))
  expect_equal(date64$reasons, c(
    "integer out_of_range 8 9", "real out_of_range 10 11", "string unparsable 13"
  ))
})

test_that("times and timestamps outside the range of their unit are NULL", {
  con <- local_con()
  dbExecute(con, "CREATE TABLE t (ts, tm)")
  dbExecute(con, "INSERT INTO t VALUES ('2020-01-02 03:04:05', '01:00:00'), ('3000-01-01 00:00:00', 1e10), ('1600-01-01 00:00:00', -1e10)")
  # Nanoseconds and microseconds since the epoch exceed the precision of a double
  fetch <- function(schema) {
    withCallingHandlers(
      as.data.frame(dbGetQueryArrow(con, "SELECT * FROM t", schema = schema)),
      nanoarrow_warning_lossy_conversion = function(w) invokeRestart("muffleWarning")
    )
  }

  df <- NULL
  w <- coercion_warnings(
    df <- fetch(list(ts = nanoarrow::na_timestamp("ns", "UTC"), tm = nanoarrow::na_time32("s")))
  )
  expect_equal(format(df$ts, "%Y"), c("2020", NA, NA))
  expect_equal(as.numeric(df$tm), c(3600, NA, NA))
  expect_length(w, 1)
  coercions <- w[[1]]$coercions
  expect_equal(vapply(coercions, `[[`, "", "type"), c("timestamp", "time32"))
  expect_equal(
    lapply(coercions, function(x) vapply(x$values, function(v) paste(v$class, v$reason), "")),
    list("string out_of_range", "real out_of_range")
  )
  expect_equal(lapply(coercions, function(x) x$values[[1]]$rows), list(2:3, 2:3))
  expect_match(conditionMessage(w[[1]]), "2 string values out of range, NA", fixed = TRUE)

  # Within the range of a coarser unit, but not within a time of day
  w <- coercion_warnings(df <- fetch(list(ts = nanoarrow::na_timestamp("us", "UTC"), tm = nanoarrow::na_time64("us"))))
  expect_equal(format(df$ts, "%Y"), c("2020", "3000", "1600"))
  expect_equal(as.numeric(df$tm), c(3600, NA, NA))
  expect_equal(vapply(w[[1]]$coercions, `[[`, "", "column"), "tm")
})

test_that("integers and text become times and timestamps exactly", {
  con <- local_con()
  dbExecute(con, "CREATE TABLE t (x)")
  dbExecute(con, paste(
    "INSERT INTO t VALUES ('2020-02-03 04:05:06.000001'), ('2262-04-11 23:47:16.854775'),",
    "('2262-04-11 23:47:16.854776'), ('1677-09-21 00:12:43.145225'), ('1677-09-21 00:12:43.145224'),",
    "('1969-12-31 23:59:59.5'), (9007199254740993), (9223372036854775807), (1.5)"
  ))
  fetch <- function(unit) {
    w <- coercion_warnings(
      array <- arrow_validated(nanoarrow::as_nanoarrow_array(
        dbGetQueryArrow(con, "SELECT x FROM t", schema = list(x = nanoarrow::na_timestamp(unit, "UTC")))
      ))
    )
    values <- if (length(w) > 0) w[[1]]$coercions[[1]]$values else list()
    list(
      array = array$children$x,
      reasons = vapply(values, function(v) paste(v$class, v$reason, paste(v$rows, collapse = " ")), "")
    )
  }

  ns <- fetch("ns")
  expect_int64_bits(ns$array, c(
    "1580702706000001000", "9223372036854775000", NA, "-9223372036854775000", NA,
    "-500000000", NA, NA, "1500000000"
  ))
  expect_equal(ns$reasons, c("string out_of_range 3 5", "integer out_of_range 7 8"))

  s <- fetch("s")
  expect_int64_bits(s$array, c(
    "1580702706", "9223372037", "9223372037", "-9223372037", "-9223372037",
    "0", "9007199254740993", "9223372036854775807", "2"
  ))
  expect_length(s$reasons, 0)

  # Text rounds half up in a coarser unit
  expect_equal(
    as.numeric(as.data.frame(dbGetQueryArrow(con, "SELECT '01:02:03.5' AS x", schema = list(x = nanoarrow::na_time32("s"))))$x),
    3724
  )
})

test_that("times outside a time of day are NULL", {
  con <- local_con()
  dbExecute(con, "CREATE TABLE t (x)")
  dbExecute(con, paste(
    "INSERT INTO t VALUES ('00:00:00'), ('23:59:59.6'), ('24:00:00'), ('-01:00:00'), ('2020-02-03'),",
    "(3600), (86400), (-1), (0.4), (86399.6)"
  ))
  units <- c(s = 1, ms = 1e3, us = 1e6, ns = 1e9)
  for (unit in names(units)) {
    type <- if (unit %in% c("s", "ms")) nanoarrow::na_time32(unit) else nanoarrow::na_time64(unit)
    w <- coercion_warnings(
      array <- arrow_validated(nanoarrow::as_nanoarrow_array(
        dbGetQueryArrow(con, "SELECT x FROM t", schema = list(x = type))
      ))
    )
    # The last tick of the day stops the rounding
    last <- if (unit == "s") 86399 else 86399.6
    expect_equal(
      as.numeric(nanoarrow::convert_array(array$children$x, double())) / units[[unit]],
      c(0, last, NA, NA, NA, 3600, NA, NA, if (unit == "s") 0 else 0.4, last),
      info = unit
    )
    expect_equal(
      lapply(w[[1]]$coercions[[1]]$values, function(v) paste(v$class, v$reason, paste(v$rows, collapse = " "))),
      list("string out_of_range 3 4 5", "integer out_of_range 7 8"),
      info = unit
    )
  }
})

test_that("requested types survive dbBind() and apply to dbReadTableArrow()", {
  con <- local_con()
  dbExecute(con, "CREATE TABLE t (x)")
  dbExecute(con, "INSERT INTO t VALUES (1), (2)")

  rs <- dbSendQueryArrow(con, "SELECT x FROM t WHERE x >= ?", schema = list(x = nanoarrow::na_int32()))
  on.exit(dbClearResult(rs))
  dbBind(rs, list(1))
  expect_equal(as.data.frame(arrow_validated(dbFetchArrow(rs)))$x, c(1L, 2L))
  dbBind(rs, list(2))
  expect_equal(as.data.frame(arrow_validated(dbFetchArrow(rs)))$x, 2L)
  dbClearResult(rs)
  on.exit(NULL)

  stream <- dbReadTableArrow(con, "t", schema = list(x = nanoarrow::na_int32()))
  expect_equal(schema_formats(stream), c(x = "i"))
  expect_equal(as.data.frame(stream)$x, c(1L, 2L))
  expect_equal(schema_formats(dbReadTableArrow(con, "t")), c(x = "l"))

  # Every kind of table name
  for (name in list(SQL('"t"'), Id(table = "t"), Id(schema = "main", table = "t"))) {
    stream <- dbReadTableArrow(con, name, schema = list(x = nanoarrow::na_int32()))
    expect_equal(schema_formats(stream), c(x = "i"))
    expect_equal(as.data.frame(stream)$x, c(1L, 2L))
  }
  expect_error(dbReadTableArrow(con, c("t", "u")), "Invalid name")
})

test_that("extended types play no part for a requested type", {
  con <- dbConnect(SQLite(), extended_types = TRUE)
  on.exit(dbDisconnect(con))
  dbExecute(con, "CREATE TABLE t (d DATE)")
  dbExecute(con, "INSERT INTO t VALUES ('2020-01-02')")
  expect_equal(query_formats(con, "SELECT d FROM t"), c(d = "tdD"))
  stream <- dbGetQueryArrow(con, "SELECT d FROM t", schema = list(d = nanoarrow::na_string()))
  expect_equal(schema_formats(stream), c(d = "u"))
  expect_equal(as.data.frame(stream)$d, "2020-01-02")
})

test_that("a requested null type drops the values with a reason of their own", {
  con <- local_con()
  dbExecute(con, "CREATE TABLE t (x)")
  dbExecute(con, "INSERT INTO t VALUES (1), (NULL), ('a')")

  df <- NULL
  w <- coercion_warnings(
    df <- as.data.frame(dbGetQueryArrow(con, "SELECT x FROM t", schema = list(x = nanoarrow::na_na())))
  )
  expect_true(all(is.na(df$x)))
  expect_equal(nrow(df), 3)
  expect_length(w, 1)
  coercions <- w[[1]]$coercions[[1]]
  expect_equal(coercions$type, "null")
  expect_equal(
    vapply(coercions$values, function(v) paste(v$class, v$reason), ""),
    c("integer null_type", "string null_type")
  )
  expect_match(conditionMessage(w[[1]]), "1 integer value dropped by the null type, NA (row 1)", fixed = TRUE)
})

test_that("data frame fetches through Arrow keep the requested types", {
  con <- local_arrow_con()
  dbExecute(con, "CREATE TABLE t (n, i, d)")
  dbExecute(con, "INSERT INTO t VALUES (NULL, 1, NULL), (1, 2.5, 3), (NULL, 3, NULL)")
  sql <- "SELECT * FROM t"
  schema <- list(n = nanoarrow::na_na(), i = nanoarrow::na_int64())

  # Without a schema, the second fetch decides `n` and widens `i`
  rs <- dbSendQueryArrow(con, sql)
  expect_equal(dbFetch(rs, 1), data.frame(n = NA, i = 1L, d = NA))
  expect_equal(dbFetch(rs), data.frame(n = c(1L, NA), i = c(2.5, 3), d = c(3L, NA)))
  dbClearResult(rs)

  # With one, `n` stays of the null type and `i` an integer, `d` is decided
  rs <- dbSendQueryArrow(con, sql, schema = schema)
  expect_equal(dbFetch(rs, 1), data.frame(n = NA, i = 1L, d = NA))
  w <- coercion_warnings(df <- dbFetch(rs))
  expect_equal(df, data.frame(n = c(NA, NA), i = c(2L, 3L), d = c(3L, NA)))
  expect_length(w, 1)
  expect_equal(
    lapply(w[[1]]$coercions, function(x) vapply(x$values, function(v) paste(v$class, v$reason), "")),
    list("integer null_type", "real converted")
  )
  dbClearResult(rs)

  # The same with one chunk per row, which rebuilds earlier chunks without a schema
  rs <- dbSendQueryArrow(con, sql)
  expect_equal(
    suppressWarnings(arrow_fetch_df(rs@result, -1, chunk_size = 1)),
    data.frame(n = c(NA, 1L, NA), i = c(1, 2.5, 3), d = c(NA, 3L, NA))
  )
  dbClearResult(rs)
  rs <- dbSendQueryArrow(con, sql, schema = schema)
  expect_equal(
    suppressWarnings(arrow_fetch_df(rs@result, -1, chunk_size = 1)),
    data.frame(n = rep(NA, 3), i = 1:3, d = c(NA, 3L, NA))
  )
  dbClearResult(rs)
  # The arrays behind such a fetch
  rs <- dbSendQueryArrow(con, sql, schema = schema)
  fetched <- result_fetch_arrow_df(rs@result@ptr, -1, 1)
  expect_equal(fetched$lengths, c(1, 1, 1))
  for (array in fetched$arrays) {
    arrow_validated(array)
  }
  dbClearResult(rs)

  # Like the default path, a 64-bit integer keeps a column as integer64 for
  # the later fetches, also in a fetch of no rows, and also from a real or text
  for (wide in c("4294967296", "4294967296.0", "'4294967296'")) {
    sql <- paste("SELECT", wide, "AS x UNION ALL SELECT 1 UNION ALL SELECT 2")
    for (type in list(nanoarrow::na_int64(), nanoarrow::na_uint64())) {
      rs <- dbSendQueryArrow(con, sql, schema = list(x = type))
      w <- coercion_warnings({
        expect_s3_class(dbFetch(rs, 0)$x, "integer64")
        expect_s3_class(dbFetch(rs, 1)$x, "integer64")
        expect_s3_class(dbFetch(rs, 1)$x, "integer64")
        expect_s3_class(dbFetch(rs)$x, "integer64")
      })
      dbClearResult(rs)
    }
  }
})

test_that("the schema reads no rows when every column has a requested type", {
  con <- local_con()
  dbExecute(con, "CREATE TABLE t (x, y)")
  dbExecute(con, "INSERT INTO t VALUES (1, 'a'), ('b', 'c')")
  sql <- "SELECT x, y FROM t"

  # The warning for the first chunk comes with the array, not with the schema
  rs <- dbSendQueryArrow(con, sql, schema = list(x = nanoarrow::na_int32(), y = nanoarrow::na_string()))
  on.exit(dbClearResult(rs))
  stream <- dbFetchArrow(rs)
  expect_length(coercion_warnings(stream$get_schema()), 0)
  expect_equal(dbGetRowCount(rs), 0)
  expect_length(coercion_warnings(array <- stream$get_next()), 1)
  expect_equal(arrow_validated(array)$length, 2)
  expect_equal(dbGetRowCount(rs), 2)
  stream$release()
  dbClearResult(rs)

  # A column without a requested type needs the first chunk
  rs <- dbSendQueryArrow(con, sql, schema = list(x = nanoarrow::na_int32()))
  stream <- dbFetchArrow(rs)
  expect_length(coercion_warnings(stream$get_schema()), 1)
  expect_length(coercion_warnings(array <- stream$get_next()), 0)
  expect_equal(arrow_validated(array)$length, 2)
  stream$release()
})

test_that("only the requested types with 32-bit offsets end chunks at the byte limits", {
  local_arrow_bytes_limits(100, 150)
  sizes <- c(60, 60, 80, 80, 200, 10, 10)
  con <- local_con()
  dbWriteTable(con, "t", data.frame(
    i = seq_along(sizes),
    s = strrep("x", sizes),
    b = blob::as_blob(lapply(sizes, function(size) as.raw(rep(1, size))))
  ))

  for (column in c("s", "b")) {
    sql <- paste0("SELECT ", column, " FROM t ORDER BY i")
    types <- list(
      utf8 = nanoarrow::na_string(), large_utf8 = nanoarrow::na_large_string(),
      binary = nanoarrow::na_binary(), large_binary = nanoarrow::na_large_binary()
    )
    for (type in names(types)) {
      schema <- setNames(list(types[[type]]), column)
      info <- paste(column, type)
      lengths <- if (startsWith(type, "large")) 7 else c(2, 1, 1, 1, 2)
      stream <- suppressWarnings(dbGetQueryArrow(con, sql, schema = schema))
      expect_equal(chunk_lengths(stream), lengths, info = info)
      values <- suppressWarnings(as.data.frame(dbGetQueryArrow(con, sql, schema = schema)))[[column]]
      expect_equal(if (is.character(values)) nchar(values) else lengths(values), sizes, info = info)
    }
  }
})

test_that("the warning names each requested type", {
  con <- local_con()
  types <- list(
    bool = nanoarrow::na_bool(), int8 = nanoarrow::na_int8(), int16 = nanoarrow::na_int16(),
    int32 = nanoarrow::na_int32(), int64 = nanoarrow::na_int64(), uint8 = nanoarrow::na_uint8(),
    uint16 = nanoarrow::na_uint16(), uint32 = nanoarrow::na_uint32(), uint64 = nanoarrow::na_uint64(),
    float = nanoarrow::na_float(), double = nanoarrow::na_double(),
    utf8 = nanoarrow::na_string(), large_utf8 = nanoarrow::na_large_string(),
    binary = nanoarrow::na_binary(), large_binary = nanoarrow::na_large_binary(),
    date32 = nanoarrow::na_date32(), date64 = nanoarrow::na_date64(),
    time32 = nanoarrow::na_time32("ms"), time64 = nanoarrow::na_time64("us"),
    timestamp = nanoarrow::na_timestamp("us", "UTC"), null = nanoarrow::na_na()
  )
  # A value of another storage class that each type reports
  values <- c(utf8 = "x'ff'", large_utf8 = "x'ff'", binary = "1", large_binary = "1", null = "1")
  for (type in names(types)) {
    value <- if (type %in% names(values)) values[[type]] else "'abc'"
    w <- coercion_warnings(
      chunk_lengths(dbGetQueryArrow(con, paste("SELECT", value, "AS x"), schema = list(x = types[[type]])))
    )
    expect_length(w, 1)
    expect_equal(w[[1]]$coercions[[1]]$type, type, info = type)
  }
})

test_that("data frame fetches build requested times and timestamps as requested", {
  setup <- c(
    "CREATE TABLE t (tm TIME, ts TIMESTAMP)",
    "INSERT INTO t VALUES ('01:02:03.5', '2020-01-02 03:04:05.25'), ('25:00:00', '1960-01-01 00:00:00')"
  )
  con <- local_arrow_con(extended_types = TRUE)
  for (sql in setup) {
    dbExecute(con, sql)
  }
  sql <- "SELECT tm, ts FROM t"
  ts <- as.numeric(as.POSIXct(c("2020-01-02 03:04:05.25", "1960-01-01 00:00:00"), tz = "UTC"))

  # Decided: the seconds of the default path, a time outside a day included
  df <- dbGetQuery(con, sql)
  expect_s3_class(df$tm, "hms")
  expect_equal(as.numeric(df$tm), c(3723.5, 90000))
  expect_equal(attr(df$ts, "tzone"), "UTC")
  expect_equal(as.numeric(df$ts), ts)

  # Requested: the unit, the time zone and the time of day of the type
  schema <- list(tm = nanoarrow::na_time32("s"), ts = nanoarrow::na_timestamp("ms", "Europe/Zurich"))
  rs <- dbSendQueryArrow(con, sql, schema = schema)
  w <- coercion_warnings(df <- dbFetch(rs))
  dbClearResult(rs)
  expect_s3_class(df$tm, "hms")
  expect_equal(as.numeric(df$tm), c(3724, NA))
  expect_s3_class(df$ts, "POSIXct")
  expect_equal(attr(df$ts, "tzone"), "Europe/Zurich")
  expect_equal(as.numeric(df$ts), ts)
  expect_length(w, 1)
  expect_equal(w[[1]]$coercions[[1]]$column, "tm")
  expect_equal(w[[1]]$coercions[[1]]$type, "time32")
  expect_equal(w[[1]]$coercions[[1]]$values[[1]]$reason, "out_of_range")

  # The arrays of the fetch are of the requested types
  rs <- dbSendQueryArrow(con, sql, schema = schema)
  fetched <- suppressWarnings(result_fetch_arrow_df(rs@result@ptr, -1, 1))
  dbClearResult(rs)
  expect_equal(fetched$formats, c("tts", "tsm:Europe/Zurich"))
  expect_equal(fetched$seconds, c("", ""))
  for (array in fetched$arrays) {
    arrow_validated(array)
  }
})

test_that("a requested type wins over the type a data frame fetch carries to a new binding", {
  con <- local_arrow_con()
  dbExecute(con, "CREATE TABLE t (k INTEGER, v)")
  dbExecute(con, "INSERT INTO t VALUES (1, 'a'), (1, 'b'), (2, 1), (2, 2)")
  sql <- "SELECT v FROM t WHERE k = ? ORDER BY rowid"
  fetch_bindings <- function(...) {
    rs <- dbSendQueryArrow(con, sql, ...)
    on.exit(dbClearResult(rs))
    lapply(1:2, function(k) {
      dbBind(rs, list(k))
      w <- coercion_warnings(df <- dbFetch(rs))
      list(v = df$v, warnings = length(w))
    })
  }

  # Like the default path, the second binding starts from text
  expect_equal(fetch_bindings(), list(list(v = c("a", "b"), warnings = 0L), list(v = c("1", "2"), warnings = 0L)))
  # A requested type holds for every binding
  expect_equal(
    fetch_bindings(schema = list(v = nanoarrow::na_int32())),
    list(list(v = c(0L, 0L), warnings = 1L), list(v = 1:2, warnings = 0L))
  )
})
