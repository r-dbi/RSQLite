# bind_arrow_stream() binds the rows of an Arrow stream as parameter sets,
# as dbBind() binds the rows of a data frame:
# the statement runs once for each row.

test_that("a stream binds each row, and round-trips through the Arrow read path", {
  skip_if_not_installed("nanoarrow")
  skip_if_not_installed("hms")
  con <- local_con(extended_types = TRUE)
  columns <- "(a INTEGER, b REAL, c TEXT, d BLOB, e DATE, f TIME, g TIMESTAMP)"
  dbExecute(con, paste("CREATE TABLE t", columns))
  df <- data.frame(
    a = c(1L, NA, 3L),
    b = c(1.5, 2, NA),
    c = c("x", NA, ""),
    d = blob::blob(as.raw(1:2), NULL, raw()),
    e = as.Date(c("2020-01-01", NA, "1960-05-06")),
    f = hms::hms(c(1.5, NA, 3600)),
    g = as.POSIXct(c(0.5, NA, 1e9), tz = "UTC")
  )

  res <- dbSendStatement(con, "INSERT INTO t VALUES (:a, :b, :c, :d, :e, :f, :g)")
  bind_arrow_stream(res, df)
  expect_equal(dbGetRowsAffected(res), 3)
  dbClearResult(res)
  expect_equal(dbGetQuery(con, "SELECT * FROM t"), df, ignore_attr = "class")
  # Empty text and blobs aren't NULL
  expect_equal(
    dbGetQuery(con, "SELECT typeof(c) AS c, typeof(d) AS d FROM t")[3, ],
    data.frame(c = "text", d = "blob", row.names = 3L)
  )

  # The int64, double, utf8, binary, date32, time64 and timestamp columns
  # of the read path bind as they were stored
  chunk <- fetch_arrow_all(con, "SELECT * FROM t")
  dbExecute(con, paste("CREATE TABLE t2", columns))
  res <- dbSendStatement(con, "INSERT INTO t2 VALUES (?, ?, ?, ?, ?, ?, ?)")
  unnamed <- nanoarrow::nanoarrow_array_modify(chunk, list(children = unname(chunk$children)))
  bind_arrow_stream(res, nanoarrow::basic_array_stream(list(unnamed)))
  dbClearResult(res)
  expect_identical(
    dbGetQuery(con, "SELECT * FROM t2"),
    dbGetQuery(con, "SELECT * FROM t")
  )
  expect_identical(
    arrow_values(fetch_arrow_all(con, "SELECT * FROM t2")),
    arrow_values(chunk)
  )
})

test_that("integers, booleans and floats bind as integers and reals", {
  skip_if_not_installed("nanoarrow")
  con <- local_con()
  expect_bound <- function(array, x, type = "integer") {
    expect_equal(
      bound_values(con, arrow_params(array)),
      data.frame(x = c(x, NA), type = c(type, "null"))
    )
  }
  na <- asNamespace("nanoarrow")
  for (type in c("int8", "int16", "int32")) {
    expect_bound(arrow_int_array(c(-1L, NA), na[[paste0("na_", type)]]()), "-1")
  }
  expect_bound(arrow_int_array(c(-1L, NA), na$na_uint8()), "255")
  expect_bound(arrow_int_array(c(-1L, NA), na$na_uint16()), "65535")
  expect_bound(arrow_int_array(c(-1L, NA), na$na_uint32()), "4294967295")
  int64 <- bit64::as.integer64(c("9223372036854775807", NA))
  for (type in list(na$na_int64(), na$na_uint64())) {
    expect_bound(na$as_nanoarrow_array(int64, schema = type), "9223372036854775807")
  }
  expect_bound(na$as_nanoarrow_array(c(TRUE, NA)), "1")
  for (type in list(na$na_half_float(), na$na_float(), na$na_double())) {
    expect_bound(na$as_nanoarrow_array(c(1.5, NA), schema = type), "1.5", "real")
  }
  nulls <- na$nanoarrow_array_modify(
    na$nanoarrow_array_init(na$na_na()),
    list(length = 2, null_count = 2)
  )
  expect_equal(
    bound_values(con, arrow_params(nulls)),
    data.frame(x = c(NA, NA), type = "null")
  )
})

test_that("large types, other time units and time zones bind, and null rows", {
  skip_if_not_installed("nanoarrow")
  skip_if_not_installed("hms")
  con <- local_con()
  as_array <- nanoarrow::as_nanoarrow_array
  stream <- arrow_params(
    as_array(c("a", NA, "c"), schema = nanoarrow::na_large_string()),
    as_array(blob::blob(as.raw(1), NULL, as.raw(3)), schema = nanoarrow::na_large_binary()),
    as_array(hms::hms(c(1.5, NA, 3)), schema = nanoarrow::na_time32("ms")),
    as_array(
      as.POSIXct(c(2, NA, 3), tz = "UTC"),
      schema = nanoarrow::na_timestamp("s", "Europe/Zurich")
    )
  )
  # A null row of the struct array binds NULL to every placeholder
  array <- stream$get_next()
  array <- nanoarrow::nanoarrow_array_modify(array, list(
    null_count = 1,
    buffers = list(nanoarrow::as_nanoarrow_array(c(TRUE, TRUE, FALSE))$buffers[[2]])
  ))

  res <- local_result(con, "SELECT ?, ?, ?, ?")
  bind_arrow_stream(res, nanoarrow::basic_array_stream(list(array)))
  expect_equal(
    unname(as.list(dbFetch(res))),
    list(c("a", NA, NA), blob::blob(as.raw(1), NULL, NULL), c(1.5, NA, NA), c(2, NA, NA))
  )
})

test_that("a stream of several arrays, some empty, or of none binds its rows", {
  skip_if_not_installed("nanoarrow")
  con <- local_con()
  arrays <- lapply(list(1:2, integer(), 3L), function(x) {
    nanoarrow::as_nanoarrow_array(data.frame(x = x))
  })
  res <- local_result(con, "SELECT :x + 1 AS y")
  bind_arrow_stream(res, nanoarrow::basic_array_stream(arrays))
  expect_equal(dbFetch(res, 1), data.frame(y = 2))
  expect_equal(dbFetch(res), data.frame(y = 3:4))
  expect_equal(dbGetRowCount(res), 3)
  expect_true(dbHasCompleted(res))

  # No rows run the statement as often as a data frame without rows
  bind_arrow_stream(res, nanoarrow::basic_array_stream(
    list(),
    schema = nanoarrow::infer_nanoarrow_schema(arrays[[1]])
  ))
  expect_true(dbHasCompleted(res))
  expect_equal(dbFetch(res), data.frame(y = integer()))
  dbClearResult(res)
  dbExecute(con, "CREATE TABLE t (x)")
  res <- dbSendStatement(con, "INSERT INTO t VALUES (?)")
  bind_arrow_stream(res, setNames(data.frame(integer()), ""))
  expect_equal(dbGetRowsAffected(res), 0)
  dbClearResult(res)
})

test_that("named placeholders take columns by name, others by position", {
  skip_if_not_installed("nanoarrow")
  con <- local_con()
  values <- function(sql, params) {
    res <- dbSendQuery(con, sql)
    on.exit(dbClearResult(res))
    bind_arrow_stream(res, params)
    unname(unlist(dbFetch(res)))
  }
  df <- data.frame(a = 1, b = 2)
  expect_equal(values("SELECT :b, :a", df), c(2, 1))
  expect_equal(values("SELECT $b, @a, :b", df), c(2, 1, 2))
  unnamed <- setNames(df, c("", ""))
  expect_equal(values("SELECT ?, ?", unnamed), c(1, 2))
  expect_equal(values("SELECT ?2, ?1", unnamed), c(2, 1))
})

test_that("parameters that don't match the placeholders fail as for dbBind()", {
  skip_if_not_installed("nanoarrow")
  con <- local_con()
  bind_error <- function(sql, params) {
    res <- dbSendQuery(con, sql)
    on.exit(dbClearResult(res))
    # Columns without names are unnamed parameters, as for DBI's dbBindArrow()
    list <- as.list(params)
    if (all(names(list) == "")) {
      names(list) <- NULL
    }
    expected <- tryCatch(dbBind(res, list), error = conditionMessage)
    actual <- tryCatch(bind_arrow_stream(res, params), error = conditionMessage)
    expect_type(actual, "character")
    expect_identical(actual, expected)
  }
  bind_error("SELECT :a, :b", data.frame(b = 1))
  bind_error("SELECT :a", data.frame(a = 1, b = 2, c = 3))
  bind_error("SELECT ?", data.frame(a = 1))
  bind_error("SELECT ?1", data.frame(a = 1))
  bind_error("SELECT ?", setNames(data.frame(1, 2), c("", "")))
  bind_error("SELECT 1", data.frame(a = 1))
  bind_error("SELECT ?, ?", setNames(data.frame(1), ""))

  res <- local_result(con, "SELECT ?")
  expect_snapshot(error = TRUE, {
    bind_arrow_stream(res, nanoarrow::basic_array_stream(list(nanoarrow::as_nanoarrow_array(1:3))))
  })
})

test_that("a type that can't be bound fails before any row runs", {
  skip_if_not_installed("nanoarrow")
  con <- local_con()
  dbExecute(con, "CREATE TABLE t (x)")
  res <- local_result(con, "INSERT INTO t VALUES (:x) RETURNING x")
  dbBind(res, list(x = 1:2))

  for (i in 1:2) {
    array <- list(
      nanoarrow::as_nanoarrow_array(factor("a")),
      nanoarrow::as_nanoarrow_array(list(1L), schema = nanoarrow::na_list(nanoarrow::na_int32()))
    )[[i]]
    stream <- arrow_params(x = array)
    expect_snapshot(error = TRUE, bind_arrow_stream(res, stream))
    # The stream stays with its owner, the previous bind goes on
    expect_equal(stream$get_next()$length, 1)
    expect_equal(dbFetch(res, 1), data.frame(x = i))
  }
  expect_equal(dbFetch(res), data.frame(x = integer()))
  dbClearResult(res)
  expect_equal(dbGetQuery(con, "SELECT x FROM t"), data.frame(x = 1:2))
})

test_that("a value that can't be bound fails like a later parameter set", {
  skip_if_not_installed("nanoarrow")
  con <- local_con()
  stream <- function() {
    arrow_params(x = nanoarrow::as_nanoarrow_array(
      bit64::as.integer64(c(1, 2, -1)),
      schema = nanoarrow::na_uint64()
    ))
  }
  message <- "18446744073709551615 of parameter 1 beyond the range"

  # Kept for the next fetch after a full one, as by dbBind()
  res <- local_result(con, "SELECT :x AS x")
  bind_arrow_stream(res, stream())
  expect_equal(dbFetch(res, 2), data.frame(x = c(1, 2)))
  expect_false(dbHasCompleted(res))
  expect_error(dbFetch(res), message)
  expect_true(dbHasCompleted(res))

  # Raised by the bind of a statement without rows, after the earlier rows
  dbClearResult(res)
  dbExecute(con, "CREATE TABLE t (x)")
  res <- local_result(con, "INSERT INTO t VALUES (:x)")
  expect_error(bind_arrow_stream(res, stream()), message)
  expect_equal(dbGetRowsAffected(res), 2)
  expect_error(dbFetch(res), "needs to be bound")
})

test_that("an error of the stream fails the bind, also by a jump out of R", {
  skip_if_not_installed("nanoarrow")
  con <- local_con()
  dbExecute(con, "CREATE TABLE t (x)")
  res <- local_result(con, "INSERT INTO t VALUES (:x)")

  # The third chunk of a stream of RSQLite fails with an error of SQLite
  other <- json_error_setup()
  on.exit(dbDisconnect(other), add = TRUE)
  source <- local_result(other, "SELECT json(v) AS x FROM t1")
  expect_error(
    bind_arrow_stream(res, read_arrow_stream(source, 1)),
    "Can't read the Arrow parameters: malformed JSON"
  )
  expect_equal(dbGetRowsAffected(res), 2)
  dbClearResult(source)

  # A warning of its second chunk calls R, under the result's busy guard
  sql <- "SELECT 1 AS x UNION ALL SELECT 'a' UNION ALL SELECT 3"
  source <- local_result(other, sql)
  cleared <- NULL
  withCallingHandlers(
    bind_arrow_stream(res, read_arrow_stream(source, 1)),
    RSQLite_warning_coercion = function(w) {
      cleared <<- tryCatch(dbClearResult(res), error = conditionMessage)
      invokeRestart("muffleWarning")
    }
  )
  expect_match(cleared, "Can't clear a result while one of its fetches or binds")
  expect_equal(dbGetRowsAffected(res), 3)
  dbClearResult(source)

  # Made an error, it leaves the stream by a jump, which fails the bind
  source <- local_result(other, sql)
  withr::with_options(
    list(warn = 2),
    expect_error(
      bind_arrow_stream(res, read_arrow_stream(source, 1)),
      "converted from warning"
    )
  )
  expect_equal(dbGetRowsAffected(res), 1)
  expect_error(dbFetch(res), "needs to be bound")
  bind_arrow_stream(res, data.frame(x = 4L))
  dbClearResult(res)
  expect_equal(
    dbGetQuery(con, "SELECT CAST(x AS TEXT) AS x FROM t")$x,
    c("[1]", "[2]", "1", "0", "3", "1", "4")
  )
})
