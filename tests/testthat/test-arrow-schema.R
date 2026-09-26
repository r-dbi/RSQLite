# Requesting Arrow types for result columns with `schema`

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
  expect_equal(as.data.frame(stream)$x, c(NA, NA, 1.5))
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
  expect_error(dbGetQueryArrow(con, "SELECT 1 AS a", schema = list(int32)), "named")
  expect_error(dbGetQueryArrow(con, "SELECT 1 AS a", schema = list(a = int32, a = int32)), "Duplicate names")
  expect_error(dbGetQueryArrow(con, "SELECT 1 AS a", schema = int32), "struct")
  expect_error(dbGetQueryArrow(con, "SELECT 1 AS a", schema = data.frame(a = integer())), "infer_nanoarrow_schema")

  # A failed request leaves no open result behind
  expect_error(dbSendQueryArrow(con, "SELECT 1 AS a", schema = list(b = int32)))
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

test_that("requested types survive dbBind() and apply to dbReadTableArrow()", {
  con <- local_con()
  dbExecute(con, "CREATE TABLE t (x)")
  dbExecute(con, "INSERT INTO t VALUES (1), (2)")

  rs <- dbSendQueryArrow(con, "SELECT x FROM t WHERE x >= ?", schema = list(x = nanoarrow::na_int32()))
  on.exit(dbClearResult(rs))
  dbBind(rs, list(1))
  expect_equal(as.data.frame(dbFetchArrow(rs))$x, c(1L, 2L))
  dbBind(rs, list(2))
  expect_equal(as.data.frame(dbFetchArrow(rs))$x, 2L)
  dbClearResult(rs)
  on.exit(NULL)

  stream <- dbReadTableArrow(con, "t", schema = list(x = nanoarrow::na_int32()))
  expect_equal(schema_formats(stream), c(x = "i"))
  expect_equal(as.data.frame(stream)$x, c(1L, 2L))
  expect_equal(schema_formats(dbReadTableArrow(con, "t")), c(x = "l"))
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
