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

  # Within the range of a coarser unit
  expect_length(
    coercion_warnings(df <- fetch(list(ts = nanoarrow::na_timestamp("us", "UTC"), tm = nanoarrow::na_time64("us")))),
    0
  )
  expect_equal(format(df$ts, "%Y"), c("2020", "3000", "1600"))
  expect_equal(as.numeric(df$tm), c(3600, 1e10, -1e10))
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
  expect_equal(array$length, 2)
  expect_equal(dbGetRowCount(rs), 2)
  stream$release()
  dbClearResult(rs)

  # A column without a requested type needs the first chunk
  rs <- dbSendQueryArrow(con, sql, schema = list(x = nanoarrow::na_int32()))
  stream <- dbFetchArrow(rs)
  expect_length(coercion_warnings(stream$get_schema()), 1)
  expect_length(coercion_warnings(array <- stream$get_next()), 0)
  expect_equal(array$length, 2)
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
      stream <- dbGetQueryArrow(con, sql, schema = schema)
      expect_equal(suppressWarnings(chunk_lengths(stream)), lengths, info = info)
      values <- suppressWarnings(as.data.frame(dbGetQueryArrow(con, sql, schema = schema)))[[column]]
      expect_equal(if (is.character(values)) nchar(values) else lengths(values), sizes, info = info)
    }
  }
})
