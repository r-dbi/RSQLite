# bind_arrow_stream() binds dictionaries by their values,
# checks the indices of dictionaries and the offsets and lengths of values,
# and refuses a stream that reads the rows of the result it binds.

test_that("dictionaries bind their values, with indices of every integer type", {
  skip_if_not_installed("nanoarrow")
  con <- local_con()
  # A factor with NA and an unused level
  factor <- factor(c("b", NA, "a"), levels = c("a", "b", "z"))
  expect_equal(
    bound_values(con, arrow_params(nanoarrow::as_nanoarrow_array(factor))),
    data.frame(x = c("b", NA, "a"), type = c("text", "null", "text"))
  )

  # A null index or a null value binds NULL
  index_types <- list(
    nanoarrow::na_int8(), nanoarrow::na_uint8(), nanoarrow::na_int16(),
    nanoarrow::na_uint16(), nanoarrow::na_int32(), nanoarrow::na_uint32(),
    nanoarrow::na_int64(), nanoarrow::na_uint64()
  )
  values <- list(
    nanoarrow::as_nanoarrow_array(c("x", NA, "z")),
    nanoarrow::as_nanoarrow_array(c(10L, NA, 30L)),
    nanoarrow::as_nanoarrow_array(blob::blob(charToRaw("x"), NULL, raw())),
    nanoarrow::as_nanoarrow_array(c("x", NA, "z"), schema = nanoarrow::na_large_string())
  )
  expected <- list(
    data.frame(x = c("z", NA, "x", NA), type = c("text", "null", "text", "null")),
    data.frame(x = c("30", NA, "10", NA), type = c("integer", "null", "integer", "null")),
    data.frame(x = c("", NA, "x", NA), type = c("blob", "null", "blob", "null")),
    data.frame(x = c("z", NA, "x", NA), type = c("text", "null", "text", "null"))
  )
  for (index_type in index_types) {
    for (i in seq_along(values)) {
      array <- arrow_dictionary(c(2, NA, 0, 1), values[[i]], index_type)
      expect_equal(bound_values(con, arrow_params(array)), expected[[i]])
    }
  }

  # A slice of a dictionary array and of its values
  array <- arrow_dictionary(c(9, 1, 0), values[[1]], nanoarrow::na_int32())
  array <- nanoarrow::nanoarrow_array_modify(array, list(
    offset = 1,
    length = 2,
    dictionary = nanoarrow::nanoarrow_array_modify(values[[1]], list(offset = 1, length = 2))
  ))
  expect_equal(
    bound_values(con, arrow_params(array)),
    data.frame(x = c("z", NA), type = c("text", "null"))
  )
})

test_that("a dictionary index out of range fails at its row", {
  skip_if_not_installed("nanoarrow")
  con <- local_con()
  dbExecute(con, "CREATE TABLE t (x)")
  res <- local_result(con, "INSERT INTO t VALUES (?)")
  values <- nanoarrow::as_nanoarrow_array(c("x", "y"))
  for (case in list(
    list(c(0, 2), nanoarrow::na_int8()),
    list(c(1, -1), nanoarrow::na_int16()),
    list(c(0, -1), nanoarrow::na_uint8()),
    list(c(1, -1), nanoarrow::na_int64()),
    list(c(0, -1), nanoarrow::na_uint64())
  )) {
    stream <- arrow_params(arrow_dictionary(case[[1]], values, case[[2]]))
    expect_snapshot(error = TRUE, bind_arrow_stream(res, stream))
    expect_equal(dbGetRowsAffected(res), 1)
  }
  # Also into values of the null type, which bind NULL
  nulls <- nanoarrow::nanoarrow_array_modify(
    nanoarrow::nanoarrow_array_init(nanoarrow::na_na()),
    list(length = 1, null_count = 1)
  )
  stream <- arrow_params(arrow_dictionary(c(0, 99), nulls, nanoarrow::na_int32()))
  expect_snapshot(error = TRUE, bind_arrow_stream(res, stream))
  expect_equal(dbGetRowsAffected(res), 1)
  dbClearResult(res)
  expect_equal(dbGetQuery(con, "SELECT x FROM t")$x, c("x", "y", "x", "y", "x", NA))
})

test_that("values beyond SQLite's length limit fail with their parameter and row", {
  skip_if_not_installed("nanoarrow")
  con <- local_con()
  dbExecute(con, "CREATE TABLE t (x, y)")
  res <- local_result(con, "INSERT INTO t VALUES (?, ?)")

  # SQLite's least length limit, 30 bytes, keeps the values small
  limit <- connection_limit_length(con@ptr, 30L)
  long <- strrep("x", 31)
  as_array <- nanoarrow::as_nanoarrow_array
  for (y in list(
    as_array(c("short", long)),
    as_array(c("short", long), schema = nanoarrow::na_large_string()),
    as_array(blob::blob(raw(5), raw(31))),
    as_array(blob::blob(raw(5), raw(31)), schema = nanoarrow::na_large_binary()),
    arrow_dictionary(c(0, 1), as_array(c("short", long)), nanoarrow::na_int32())
  )) {
    stream <- arrow_params(as_array(1:2), y)
    expect_snapshot(error = TRUE, bind_arrow_stream(res, stream))
    expect_equal(dbGetRowsAffected(res), 1)
  }

  # A 64-bit length fails whole, before its data is read:
  # the offsets alone give the size of the data in the C data interface
  connection_limit_length(con@ptr, limit)
  y <- arrow_offsets_array(c(0, 3e9), "x", nanoarrow::na_large_binary())
  expect_error(
    bind_arrow_stream(res, arrow_params(as_array(1L), y)),
    "value of 3000000000 bytes of parameter 2 in row 1, beyond SQLite's length limit"
  )
  expect_equal(dbGetRowsAffected(res), 0)
})

test_that("offsets that are negative, decreasing or beyond the data fail", {
  skip_if_not_installed("nanoarrow")
  con <- local_con()
  dbExecute(con, "CREATE TABLE t (x)")
  res <- local_result(con, "INSERT INTO t VALUES (?)")
  types <- list(
    nanoarrow::na_string(), nanoarrow::na_large_string(),
    nanoarrow::na_binary(), nanoarrow::na_large_binary()
  )
  for (type in types) {
    for (offsets in list(c(0, 2, -1, 6), c(0, 2, 1, 6), c(0, 2, 7, 6))) {
      x <- arrow_offsets_array(offsets, "abcdef", type)
      expect_error(
        bind_arrow_stream(res, arrow_params(x)),
        "Invalid Arrow parameters: the offsets of parameter 1 in row 2 point outside its data.",
        fixed = TRUE
      )
      expect_equal(dbGetRowsAffected(res), 1)
    }
  }
})

test_that("a stream that reads the rows of the result itself fails up front", {
  skip_if_not_installed("nanoarrow")
  con <- local_con()
  res <- local_result(con, "SELECT :x AS x")
  dbBind(res, list(x = 1:3))
  stream <- read_arrow_stream(res, 1)
  expect_snapshot(error = TRUE, bind_arrow_stream(res, stream))
  # Neither the stream nor the result has been read or changed
  expect_equal(dbGetRowCount(res), 0)
  expect_equal(nanoarrow::convert_array_stream(stream), data.frame(x = 1:3))
})

test_that("results whose parameters read each other's rows fail up front", {
  skip_if_not_installed("nanoarrow")
  # One connection for each, as a connection has one open result
  env <- environment()
  sql <- c("SELECT :c * 10 AS a", "SELECT :a * 10 AS b", "SELECT :b * 10 AS c")
  results <- lapply(sql, function(sql) {
    local_result(local_con(envir = env), sql, envir = env)
  })
  dbBind(results[[1]], list(c = 1:3))
  bind_arrow_stream(results[[2]], read_arrow_stream(results[[1]], 1))
  # Of two results
  stream <- read_arrow_stream(results[[2]], 1)
  expect_snapshot(error = TRUE, bind_arrow_stream(results[[1]], stream))
  # Of three results
  bind_arrow_stream(results[[3]], stream)
  stream <- read_arrow_stream(results[[3]], 1)
  expect_snapshot(error = TRUE, bind_arrow_stream(results[[1]], stream))
  expect_equal(nanoarrow::convert_array_stream(stream), data.frame(c = c(1000, 2000, 3000)))
})

test_that("a chain whose first stream has ended no longer reads its first result", {
  skip_if_not_installed("nanoarrow")
  env <- environment()
  results <- lapply(1:5, function(i) {
    local_result(local_con(envir = env), "SELECT :v + 1 AS v", envir = env)
  })
  dbBind(results[[1]], list(v = 1:3))
  for (i in 2:5) {
    bind_arrow_stream(results[[i]], read_arrow_stream(results[[i - 1]], 1))
  }
  # Reading the schemas has fetched ahead:
  # the stream of the first result has ended, which ends the chain there
  bind_arrow_stream(results[[1]], read_arrow_stream(results[[5]], 1))
  expect_equal(
    nanoarrow::convert_array_stream(read_arrow_stream(results[[1]], -1)),
    data.frame(v = 7:9)
  )
})
