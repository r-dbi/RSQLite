# Created by DBItest::use_dbitest(), do not edit by hand

ctx <- get_default_context()

test_that("send_query_formals", {
  # <establish formals of described functions>
  expect_equal(names(formals(dbSendQuery)), c("conn", "statement", "..."))
})

test_that("send_query_trivial", {
  res <- expect_visible(dbSendQuery(con, trivial_query()))
  #' an S4 object that inherits from [DBIResult-class].
  expect_s4_class(res, "DBIResult")
  #' The result set can be used with [dbFetch()] to extract records.
  expect_equal(check_df(dbFetch(res))[[1]], 1.5)
  #' Once you have finished using a result, make sure to clear it
  #' with [dbClearResult()].
  dbClearResult(res)
})

test_that("send_query_non_string", {
  expect_error(dbSendQuery(con, character()))
  expect_error(dbSendQuery(con, letters))
  expect_error(dbSendQuery(con, NA_character_))
})

test_that("send_query_syntax_error", {
  expect_error(dbSendQuery(con, "SELLECT", params = list()))
  expect_error(dbSendQuery(con, "SELLECT", immediate = TRUE))
})

test_that("send_query_result_valid", {
  #' No warnings occur under normal conditions.
  expect_warning(res <- dbSendQuery(con, trivial_query()), NA)
  #' When done, the DBIResult object must be cleared with a call to
  #' [dbClearResult()].
  dbClearResult(res)
})

test_that("send_query_stale_warning", {
  con <- connect(ctx)
  on.exit(dbDisconnect(con))
  expect_warning(dbSendQuery(con, trivial_query()), NA)
  expect_warning({
    dbDisconnect(con)
    gc()
  })
  on.exit(NULL)
})

test_that("send_query_only_one_result_set", {
  res1 <- dbSendQuery(con, trivial_query())
  #' issuing a second query invalidates an already open result set
  #' and raises a warning.
  expect_warning(res2 <- dbSendQuery(con, "SELECT 2"))
  expect_false(dbIsValid(res1))
  #' The newly opened result set is valid
  expect_true(dbIsValid(res2))
  #' and must be cleared with `dbClearResult()`.
  dbClearResult(res2)
})

test_that("send_query_params", {
  placeholder_funs <- get_placeholder_funs(ctx)
  for (placeholder_fun in placeholder_funs) {
    placeholder <- placeholder_fun(1)
    query <- paste0("SELECT ", placeholder, " + 1.0 AS a")
    values <- trivial_values(3) - 1
    params <- `::`(stats, setNames)(list(values), names(placeholder))
    rs <- dbSendQuery(con, query, params = params)
    ret <- dbFetch(rs)
    expect_equal(ret, trivial_df(3), info = placeholder)
    dbClearResult(rs)
  }
})

test_that("fetch_formals", {
  # <establish formals of described functions>
  expect_equal(names(formals(dbFetch)), c("res", "n", "..."))
})

test_that("fetch_atomic", {
  query <- trivial_query()
  res <- local_result(dbSendQuery(con, query))
  rows <- check_df(dbFetch(res))
  expect_equal(rows, data.frame(a = 1.5))
})

test_that("fetch_one_row", {
  query <- trivial_query(3, letters[1:3])
  result <- trivial_df(3, letters[1:3])
  res <- local_result(dbSendQuery(con, query))
  rows <- check_df(dbFetch(res))
  expect_identical(rows, result)
})

test_that("fetch_zero_rows", {
  query <-
    "SELECT * FROM (SELECT 1 as a, 2 as b, 3 as c) AS x WHERE (1 = 0)"
  res <- local_result(dbSendQuery(con, query))
  rows <- check_df(dbFetch(res))
  expect_identical(class(rows), "data.frame")
})

test_that("fetch_closed", {
  query <- trivial_query()

  res <- dbSendQuery(con, query)
  dbClearResult(res)

  expect_error(dbFetch(res))
})

test_that("fetch_n_bad", {
  query <- trivial_query()
  res <- local_result(dbSendQuery(con, query))
  expect_error(dbFetch(res, -2))
  expect_error(dbFetch(res, 1.5))
  expect_error(dbFetch(res, integer()))
  expect_error(dbFetch(res, 1:3))
  expect_error(dbFetch(res, NA_integer_))
})

test_that("fetch_n_good_after_bad", {
  query <- trivial_query()
  res <- local_result(dbSendQuery(con, query))
  expect_error(dbFetch(res, NA_integer_))
  rows <- check_df(dbFetch(res))
  expect_equal(rows, data.frame(a = 1.5))
})

test_that("fetch_multi_row_single_column", {
  query <- trivial_query(3, .ctx = ctx, .order_by = "a")
  result <- trivial_df(3)

  res <- local_result(dbSendQuery(con, query))
  rows <- check_df(dbFetch(res))
  expect_identical(rows, result)
})

test_that("fetch_multi_row_multi_column", {
  query <- union(
    .ctx = ctx, paste("SELECT", 1:5 + 0.5, "AS a,", 4:0 + 0.5, "AS b"), .order_by = "a"
  )

  res <- local_result(dbSendQuery(con, query))
  rows <- check_df(dbFetch(res))
  expect_identical(rows, data.frame(a = 1:5 + 0.5, b = 4:0 + 0.5))
})

test_that("fetch_n_progressive", {
  query <- trivial_query(25, .ctx = ctx, .order_by = "a")
  result <- trivial_df(25)

  res <- local_result(dbSendQuery(con, query))
  #' by passing a whole number ([integer]
  rows <- check_df(dbFetch(res, 10L))
  expect_identical(rows, unrowname(result[1:10, , drop = FALSE]))

  #' or [numeric])
  rows <- check_df(dbFetch(res, 10))
  expect_identical(rows, unrowname(result[11:20, , drop = FALSE]))

  #' as the `n` argument.
  rows <- check_df(dbFetch(res, n = 5))
  expect_identical(rows, unrowname(result[21:25, , drop = FALSE]))
})

test_that("fetch_n_multi_row_inf", {
  query <- trivial_query(3, .ctx = ctx, .order_by = "a")
  result <- trivial_df(3)

  res <- local_result(dbSendQuery(con, query))
  rows <- check_df(dbFetch(res, n = Inf))
  expect_identical(rows, result)
})

test_that("fetch_n_more_rows", {
  query <- trivial_query(3, .ctx = ctx, .order_by = "a")
  result <- trivial_df(3)

  res <- local_result(dbSendQuery(con, query))
  rows <- check_df(dbFetch(res, 5L))
  expect_identical(rows, result)
  #' If fewer rows than requested are returned, further fetches will
  #' return a data frame with zero rows.
  rows <- check_df(dbFetch(res))
  expect_identical(rows, result[0, , drop = FALSE])
})

test_that("fetch_n_zero_rows", {
  query <- trivial_query(3, .ctx = ctx, .order_by = "a")
  result <- trivial_df(0)

  res <- local_result(dbSendQuery(con, query))
  rows <- check_df(dbFetch(res, 0L))
  expect_identical(rows, result)
})

test_that("fetch_n_premature_close", {
  query <- trivial_query(3, .ctx = ctx, .order_by = "a")
  result <- trivial_df(2)

  res <- local_result(dbSendQuery(con, query))
  rows <- check_df(dbFetch(res, 2L))
  expect_identical(rows, result)
})

test_that("fetch_row_names", {
  query <- trivial_query(column = "row_names")
  result <- trivial_df(column = "row_names")

  res <- local_result(dbSendQuery(con, query))
  rows <- check_df(dbFetch(res))
  expect_identical(rows, result)
  expect_identical(.row_names_info(rows), -1L)
})

test_that("clear_result_formals", {
  # <establish formals of described functions>
  expect_equal(names(formals(dbClearResult)), c("res", "..."))
})

test_that("clear_result_return_query", {
  res <- dbSendQuery(con, trivial_query())
  expect_invisible_true(dbClearResult(res))
})

test_that("cannot_clear_result_twice_query", {
  res <- dbSendQuery(con, trivial_query())
  dbClearResult(res)
  expect_warning(expect_invisible_true(dbClearResult(res)))
})

test_that("get_query_formals", {
  # <establish formals of described functions>
  expect_equal(names(formals(dbGetQuery)), c("conn", "statement", "..."))
})

test_that("get_query_atomic", {
  query <- trivial_query()

  rows <- check_df(dbGetQuery(con, query))
  expect_equal(rows, data.frame(a = 1.5))
})

test_that("get_query_one_row", {
  query <- trivial_query(3, letters[1:3])
  result <- trivial_df(3, letters[1:3])

  rows <- check_df(dbGetQuery(con, query))
  expect_identical(rows, result)
})

test_that("get_query_zero_rows", {
  # Not all SQL dialects seem to support the query used here.
  query <-
    "SELECT * FROM (SELECT 1 as a, 2 as b, 3 as c) AS x WHERE (1 = 0)"

  rows <- check_df(dbGetQuery(con, query))
  expect_identical(names(rows), letters[1:3])
  expect_identical(dim(rows), c(0L, 3L))
})

test_that("get_query_syntax_error", {
  expect_error(dbGetQuery(con, "SELLECT"))
})

test_that("get_query_non_string", {
  expect_error(dbGetQuery(con, character()))
  expect_error(dbGetQuery(con, letters))
  expect_error(dbGetQuery(con, NA_character_))
})

test_that("get_query_n_bad", {
  query <- trivial_query()
  expect_error(dbGetQuery(con, query, n = -2))
  expect_error(dbGetQuery(con, query, n = 1.5))
  expect_error(dbGetQuery(con, query, n = integer()))
  expect_error(dbGetQuery(con, query, n = 1:3))
  expect_error(dbGetQuery(con, query, n = NA_integer_))
})

test_that("get_query_good_after_bad_n", {
  query <- trivial_query()
  expect_error(dbGetQuery(con, query, n = NA_integer_))
  rows <- check_df(dbGetQuery(con, query))
  expect_equal(rows, data.frame(a = 1.5))
})

test_that("get_query_row_names", {
  query <- trivial_query(column = "row_names")
  result <- trivial_df(column = "row_names")

  rows <- check_df(dbGetQuery(con, query))
  expect_identical(rows, result)
  expect_identical(.row_names_info(rows), -1L)
})

test_that("get_query_multi_row_single_column", {
  query <- trivial_query(3, .ctx = ctx, .order_by = "a")
  result <- trivial_df(3)

  rows <- check_df(dbGetQuery(con, query))
  expect_identical(rows, result)
})

test_that("get_query_multi_row_multi_column", {
  query <- union(
    .ctx = ctx, paste("SELECT", 1:5 + 0.5, "AS a,", 4:0 + 0.5, "AS b"), .order_by = "a"
  )

  rows <- check_df(dbGetQuery(con, query))
  expect_identical(rows, data.frame(a = 1:5 + 0.5, b = 4:0 + 0.5))
})

test_that("get_query_n_multi_row_inf", {
  query <- trivial_query(3, .ctx = ctx, .order_by = "a")
  result <- trivial_df(3)

  rows <- check_df(dbGetQuery(con, query, n = Inf))
  expect_identical(rows, result)
})

test_that("get_query_n_more_rows", {
  query <- trivial_query(3, .ctx = ctx, .order_by = "a")
  result <- trivial_df(3)

  rows <- check_df(dbGetQuery(con, query, n = 5L))
  expect_identical(rows, result)
})

test_that("get_query_n_zero_rows", {
  query <- trivial_query(3, .ctx = ctx, .order_by = "a")
  result <- trivial_df(0)

  rows <- check_df(dbGetQuery(con, query, n = 0L))
  expect_identical(rows, result)
})

test_that("get_query_n_incomplete", {
  query <- trivial_query(3, .ctx = ctx, .order_by = "a")
  result <- trivial_df(2)

  rows <- check_df(dbGetQuery(con, query, n = 2L))
  expect_identical(rows, result)
})

test_that("get_query_params", {
  placeholder_funs <- get_placeholder_funs(ctx)
  for (placeholder_fun in placeholder_funs) {
    placeholder <- placeholder_fun(1)
    query <- paste0("SELECT ", placeholder, " + 1.0 AS a")
    values <- trivial_values(3) - 1
    params <- `::`(stats, setNames)(list(values), names(placeholder))
    ret <- dbGetQuery(con, query, params = params)
    expect_equal(ret, trivial_df(3), info = placeholder)
  }
})

test_that("send_statement_formals", {
  # <establish formals of described functions>
  expect_equal(names(formals(dbSendStatement)), c("conn", "statement", "..."))
})

test_that("send_statement_non_string", {
  expect_error(dbSendStatement(con, character()))
  expect_error(dbSendStatement(con, letters))
  expect_error(dbSendStatement(con, NA_character_))
})

test_that("send_statement_syntax_error", {
  expect_error(dbSendStatement(con, "CREATTE", params = list()))
  expect_error(dbSendStatement(con, "CREATTE", immediate = TRUE))
})

test_that("send_statement_stale_warning", {
  con <- connect(ctx)
  on.exit(dbDisconnect(con))
  expect_warning(dbSendStatement(con, trivial_query()), NA)
  expect_warning({
    dbDisconnect(con)
    gc()
  })
  on.exit(NULL)
})

test_that("send_statement_params", {
  placeholder_funs <- get_placeholder_funs(ctx)
  for (placeholder_fun in placeholder_funs) {
    table_name <- random_table_name()
    local_remove_test_table(con, table_name)
    dbWriteTable(con, table_name, data.frame(a = as.numeric(1:3)))
    placeholder <- placeholder_fun(1)
    query <- paste0("DELETE FROM ", table_name, " WHERE a > ", placeholder)
    values <- 1.5
    params <- `::`(stats, setNames)(list(values), names(placeholder))
    rs <- dbSendStatement(con, query, params = params)
    expect_equal(dbGetRowsAffected(rs), 2, info = placeholder)
    dbClearResult(rs)
  }
})

test_that("execute_formals", {
  # <establish formals of described functions>
  expect_equal(names(formals(dbExecute)), c("conn", "statement", "..."))
})

test_that("execute_syntax_error", {
  expect_error(dbExecute(con, "CREATTE"))
})

test_that("execute_non_string", {
  expect_error(dbExecute(con, character()))
  expect_error(dbExecute(con, letters))
  expect_error(dbExecute(con, NA_character_))
})

test_that("execute_params", {
  placeholder_funs <- get_placeholder_funs(ctx)
  for (placeholder_fun in placeholder_funs) {
    table_name <- random_table_name()
    local_remove_test_table(con, table_name)
    dbWriteTable(con, table_name, data.frame(a = as.numeric(1:3)))
    placeholder <- placeholder_fun(1)
    query <- paste0("DELETE FROM ", table_name, " WHERE a > ", placeholder)
    values <- 1.5
    params <- `::`(stats, setNames)(list(values), names(placeholder))
    ret <- dbExecute(con, query, params = params)
    expect_equal(ret, 2, info = placeholder)
  }
})

test_that("data_type_create_table", {
  check_connection_data_type <- function(value) {
    table_name <- random_table_name()
    local_remove_test_table(con, table_name)
    query <- paste0("CREATE TABLE ", table_name, " (a ", dbDataType(con, value), ")")
    eval(bquote(dbExecute(con, .(query))))
  }
  expect_conn_has_data_type <- function(value) {
    eval(bquote(expect_error(check_connection_data_type(.(value)), NA)))
  }
  expect_conn_has_data_type(logical(1))
  expect_conn_has_data_type(integer(1))
  expect_conn_has_data_type(numeric(1))
  expect_conn_has_data_type(character(1))
  expect_conn_has_data_type(Sys.Date())
  expect_conn_has_data_type(Sys.time())
  if (!isTRUE(`$`(`$`(ctx, tweaks), omit_blob_tests))) {
    expect_conn_has_data_type(list(as.raw(0:10)))
  }
})

test_that("data_integer", {
  #' with [NA] for SQL `NULL` values
  test_select_with_null(.ctx = ctx, con, 1L ~ equals_one, -100L ~ equals_minus_100)
})

test_that("data_numeric", {
  #' with NA for SQL `NULL` values
  test_select_with_null(.ctx = ctx, con, 1.5, -100.5)
})

test_that("data_logical", {
  int_values <- 1:0
  values <- ctx$tweaks$logical_return(as.logical(int_values))

  sql_names <- paste0("CAST(", int_values, " AS ", dbDataType(con, logical()), ")")

  #' with NA for SQL `NULL` values
  test_select_with_null(.ctx = ctx, con, .dots = setNames(values, sql_names))
})

test_that("data_character", {
  values <- texts
  test_funs <- rep(list(has_utf8_or_ascii_encoding), length(values))
  sql_names <- as.character(dbQuoteString(con, values))

  #' with NA for SQL `NULL` values
  test_select_with_null(.ctx = ctx, con, .dots = setNames(values, sql_names))
  test_select_with_null(.ctx = ctx, con, .dots = setNames(test_funs, sql_names))
})

test_that("data_raw", {
  if (isTRUE(`$`(`$`(ctx, tweaks), omit_blob_tests))) {
    skip("tweak: omit_blob_tests")
  }
  values <- list(is_raw_list)
  sql_names <- `$`(`$`(ctx, tweaks), blob_cast)(quote_literal(con, list(raw(1))))
  test_select_with_null(.ctx = ctx, con, .dots = setNames(values, sql_names))
})

test_that("data_date", {
  char_values <- paste0("2015-01-", sprintf("%.2d", 1:12))
  values <- as_date_equals_to(as.Date(char_values))
  sql_names <- ctx$tweaks$date_cast(char_values)

  #' with NA for SQL `NULL` values
  test_select_with_null(.ctx = ctx, con, .dots = setNames(values, sql_names))
})

test_that("data_date_current", {
  test_select_with_null(
    .ctx = ctx, con,
    "current_date" ~ is_roughly_current_date
  )
})

test_that("data_time", {
  char_values <- c("00:00:00", "12:34:56")
  time_values <- as_hms_equals_to(hms::as_hms(char_values))
  sql_names <- ctx$tweaks$time_cast(char_values)

  #' with NA for SQL `NULL` values
  test_select_with_null(.ctx = ctx, con, .dots = setNames(time_values, sql_names))
})

test_that("data_time_current", {
  test_select_with_null(
    .ctx = ctx, con,
    "current_time" ~ coercible_to_time
  )
})

test_that("data_timestamp", {
  char_values <- c("2015-10-11 00:00:00", "2015-10-11 12:34:56")
  time_values <- rep(list(coercible_to_timestamp), 2L)
  sql_names <- ctx$tweaks$timestamp_cast(char_values)

  #' with NA for SQL `NULL` values
  test_select_with_null(.ctx = ctx, con, .dots = setNames(time_values, sql_names))
})

test_that("data_timestamp_current", {
  test_select_with_null(
    .ctx = ctx, con,
    "current_timestamp" ~ is_roughly_current_timestamp
  )
})

test_that("data_date_typed", {
  if (!isTRUE(`$`(`$`(ctx, tweaks), date_typed))) {
    skip("tweak: !date_typed")
  }
  char_values <- paste0("2015-01-", sprintf("%.2d", 1:12))
  values <- lapply(char_values, as_numeric_date)
  sql_names <- `$`(`$`(ctx, tweaks), date_cast)(char_values)
  test_select_with_null(.ctx = ctx, con, .dots = setNames(values, sql_names))
})

test_that("data_date_current_typed", {
  if (!isTRUE(`$`(`$`(ctx, tweaks), date_typed))) {
    skip("tweak: !date_typed")
  }
  test_select_with_null(.ctx = ctx, con, "current_date" ~ is_roughly_current_date_typed)
})

test_that("data_timestamp_typed", {
  if (!isTRUE(`$`(`$`(ctx, tweaks), timestamp_typed))) {
    skip("tweak: !timestamp_typed")
  }
  char_values <- c("2015-10-11 00:00:00", "2015-10-11 12:34:56")
  timestamp_values <- rep(list(is_timestamp), 2L)
  sql_names <- `$`(`$`(ctx, tweaks), timestamp_cast)(char_values)
  test_select_with_null(.ctx = ctx, con, .dots = setNames(timestamp_values, sql_names))
})

test_that("data_timestamp_current_typed", {
  if (!isTRUE(`$`(`$`(ctx, tweaks), timestamp_typed))) {
    skip("tweak: !timestamp_typed")
  }
  test_select_with_null(.ctx = ctx, con, "current_timestamp" ~ is_roughly_current_timestamp_typed)
})

test_that("data_64_bit_numeric", {
  char_values <- c("10000000000", "-10000000000")
  test_values <- as_numeric_identical_to(as.numeric(char_values))

  test_select_with_null(.ctx = ctx, con, .dots = setNames(test_values, char_values))
})

test_that("data_64_bit_numeric_warning", {
  char_values <- c(" 1234567890123456789", "-1234567890123456789")
  num_values <- as.numeric(char_values)
  test_values <- as_numeric_equals_to(num_values)

  suppressWarnings(
    expect_warning(
      test_select(.ctx = ctx, con, .dots = setNames(test_values, char_values), .add_null = "none")
    )
  )
  suppressWarnings(
    expect_warning(
      test_select(.ctx = ctx, con, .dots = setNames(test_values, char_values), .add_null = "above")
    )
  )
  suppressWarnings(
    expect_warning(
      test_select(.ctx = ctx, con, .dots = setNames(test_values, char_values), .add_null = "below")
    )
  )
})

test_that("data_64_bit_lossless", {
  char_values <- c("1234567890123456789", "-1234567890123456789")
  test_values <- as_character_equals_to(char_values)

  test_select_with_null(.ctx = ctx, con, .dots = setNames(test_values, char_values))
})
