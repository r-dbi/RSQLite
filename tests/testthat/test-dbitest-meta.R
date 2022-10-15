# Created by DBItest::use_dbitest(), do not edit by hand

ctx <- get_default_context()

con <- local_connection(ctx)

test_that("bind_formals", {
  # <establish formals of described functions>
  expect_equal(names(formals(dbBind)), c("res", "params", "..."))
})

test_that("bind_return_value", {
  extra <- new_bind_tester_extra(
    check_return_value = function(bind_res, res) {
      expect_identical(res, `$`(bind_res, value))
      expect_false(`$`(bind_res, visible))
    }
  )
  test_select_bind(con, ctx, 1L, extra = extra)
  test_select_bind(con, ctx, 1L, extra = extra, query = FALSE)
})

test_that("bind_empty", {
  #' @section Failure modes:
  #' Calling `dbBind()` for a query without parameters
  res <- local_result(dbSendQuery(con, trivial_query()))
  #' raises an error.
  expect_error(dbBind(res, list()))
})

test_that("bind_too_many", {
  extra <- new_bind_tester_extra(
    patch_bind_values = function(bind_values) {
      if (is.null(names(bind_values))) {
        c(bind_values, bind_values[[1L]])
      } else {
        c(bind_values, bogus = bind_values[[1L]])
      }
    },
    bind_error = function() ".*"
  )
  test_select_bind(con, ctx, 1L, extra = extra)
})

test_that("bind_not_enough", {
  extra <- new_bind_tester_extra(patch_bind_values = function(bind_values) {
    bind_values[-1L]
  }, bind_error = function() ".*")
  test_select_bind(con, ctx, 1L, extra = extra)
})

test_that("bind_wrong_name", {
  extra <- new_bind_tester_extra(
    patch_bind_values = function(bind_values) {
      `::`(stats, setNames)(bind_values, paste0("bogus", names(bind_values)))
    },
    requires_names = function() TRUE,
    bind_error = function() ".*"
  )
  test_select_bind(con, ctx, 1L, extra = extra)
})

test_that("bind_multi_row_unequal_length", {
  extra <- new_bind_tester_extra(
    patch_bind_values = function(bind_values) {
      bind_values[[2]] <- bind_values[[2]][-1]
      bind_values
    },
    bind_error = function() ".*"
  )
  test_select_bind(con, ctx, list(1:3, 2:4), extra = extra, query = FALSE)
})

test_that("bind_named_param_unnamed_placeholders", {
  extra <- new_bind_tester_extra(
    patch_bind_values = function(bind_values) {
      `::`(stats, setNames)(bind_values, NULL)
    },
    bind_error = function() ".*",
    requires_names = function() TRUE
  )
  test_select_bind(con, ctx, 1L, extra = extra)
})

test_that("bind_named_param_empty_placeholders", {
  extra <- new_bind_tester_extra(
    patch_bind_values = function(bind_values) {
      names(bind_values)[[1]] <- ""
    },
    bind_error = function() ".*",
    requires_names = function() TRUE
  )
  test_select_bind(con, ctx, list(1L, 2L), extra = extra)
})

test_that("bind_named_param_na_placeholders", {
  extra <- new_bind_tester_extra(
    patch_bind_values = function(bind_values) {
      names(bind_values)[[1]] <- NA
    },
    bind_error = function() ".*",
    requires_names = function() TRUE
  )
  test_select_bind(con, ctx, list(1L, 2L), extra = extra)
})

test_that("bind_unnamed_param_named_placeholders", {
  extra <- new_bind_tester_extra(
    patch_bind_values = function(bind_values) {
      `::`(stats, setNames)(bind_values, letters[seq_along(bind_values)])
    },
    bind_error = function() ".*",
    requires_names = function() FALSE
  )
  test_select_bind(con, ctx, 1L, extra = extra)
})

test_that("bind_premature_clear", {
  extra <- new_bind_tester_extra(is_premature_clear = function() TRUE)
  expect_error(test_select_bind(con, ctx, 1L, extra = extra))
})

test_that("bind_multi_row", {
  #' @section Specification:
  #' The elements of the `params` argument do not need to be scalars,
  #' vectors of arbitrary length
  test_select_bind(con, ctx, list(1:3))
})

test_that("bind_multi_row_zero_length", {
  #' (including length 0)
  test_select_bind(con, ctx, list(integer(), integer()))

  #' are supported.
  # This behavior is tested as part of run_bind_tester$fun
  #' For queries, calling `dbFetch()` binding such parameters returns
  #' concatenated results, equivalent to binding and fetching for each set
  #' of values and connecting via [rbind()].
})

test_that("bind_multi_row_statement", {
  # This behavior is tested as part of run_bind_tester$fun
  #' For data manipulation statements, `dbGetRowsAffected()` returns the
  #' total number of rows affected if binding non-scalar parameters.
  test_select_bind(con, ctx, list(1:3), query = FALSE)
})

test_that("bind_repeated", {
  extra <- new_bind_tester_extra(is_repeated = function() TRUE)
  test_select_bind(con, ctx, 1L, extra = extra)
  test_select_bind(con, ctx, 1L, extra = extra, query = FALSE)
})

test_that("bind_repeated_untouched", {
  extra <- new_bind_tester_extra(is_repeated = function() TRUE, is_untouched = function() TRUE)
  test_select_bind(con, ctx, 1L, extra = extra)
  test_select_bind(con, ctx, 1L, extra = extra, query = FALSE)
})

test_that("bind_named_param_shuffle", {
  extra <- new_bind_tester_extra(patch_bind_values = function(bind_values) {
    bind_values[c(3, 1, 2, 4)]
  }, requires_names = function() TRUE)
  test_select_bind(con, ctx, c(1:3 + 0.5, NA), extra = extra)
})

test_that("bind_integer", {
  #' At least the following data types are accepted on input (including [NA]):
  #' - [integer]
  test_select_bind(con, ctx, c(1:3, NA))
})

test_that("bind_numeric", {
  #' - [numeric]
  test_select_bind(con, ctx, c(1:3 + 0.5, NA))
})

test_that("bind_logical", {
  #' - [logical] for Boolean values
  test_select_bind(con, ctx, c(TRUE, FALSE, NA))
})

test_that("bind_character", {
  #' - [character]
  test_select_bind(con, ctx, c(get_texts(), NA))
})

test_that("bind_character_escape", {
  #'   (also with special characters such as spaces, newlines, quotes, and backslashes)
  test_select_bind(con, ctx, c(" ", "\n", "\r", "\b", "'", '"', "[", "]", "\\", NA))
})

test_that("bind_factor", {
  #' - [factor] (bound as character,
  #' with warning)
  suppressWarnings(expect_warning(
    test_select_bind(
      con,
      ctx,
      lapply(c(get_texts(), NA_character_), factor)
    )
  ))
})

test_that("bind_date", {
  if (!isTRUE(`$`(`$`(ctx, tweaks), date_typed))) {
    skip("tweak: !date_typed")
  }
  test_select_bind(con, ctx, c(Sys.Date() + 0:2, NA))
})

test_that("bind_date_integer", {
  if (!isTRUE(`$`(`$`(ctx, tweaks), date_typed))) {
    skip("tweak: !date_typed")
  }
  test_select_bind(con, ctx, structure(c(18618:18620, NA), class = "Date"))
})

test_that("bind_timestamp", {
  if (!isTRUE(`$`(`$`(ctx, tweaks), timestamp_typed))) {
    skip("tweak: !timestamp_typed")
  }
  data_in <- as.POSIXct(c(round(Sys.time()) + 0:2, NA))
  test_select_bind(con, ctx, data_in)
})

test_that("bind_timestamp_lt", {
  if (!isTRUE(`$`(`$`(ctx, tweaks), timestamp_typed))) {
    skip("tweak: !timestamp_typed")
  }
  data_in <- lapply(round(Sys.time()) + c(0:2, NA), as.POSIXlt)
  test_select_bind(con, ctx, data_in)
})

test_that("bind_time_seconds", {
  if (!isTRUE(`$`(`$`(ctx, tweaks), time_typed))) {
    skip("tweak: !time_typed")
  }
  data_in <- as.difftime(as.numeric(c(1:3, NA)), units = "secs")
  test_select_bind(con, ctx, data_in)
})

test_that("bind_time_hours", {
  if (!isTRUE(`$`(`$`(ctx, tweaks), time_typed))) {
    skip("tweak: !time_typed")
  }
  data_in <- as.difftime(as.numeric(c(1:3, NA)), units = "hours")
  test_select_bind(con, ctx, data_in)
})

test_that("bind_time_minutes_integer", {
  if (!isTRUE(`$`(`$`(ctx, tweaks), time_typed))) {
    skip("tweak: !time_typed")
  }
  data_in <- as.difftime(c(1:3, NA), units = "mins")
  test_select_bind(con, ctx, data_in)
})

test_that("bind_raw", {
  if (isTRUE(`$`(`$`(ctx, tweaks), omit_blob_tests))) {
    skip("tweak: omit_blob_tests")
  }
  test_select_bind(con, ctx, list(list(as.raw(1:10)), list(raw(3)), list(NULL)), cast_fun = `$`(`$`(ctx, tweaks), blob_cast))
})

test_that("bind_blob", {
  if (isTRUE(`$`(`$`(ctx, tweaks), omit_blob_tests))) {
    skip("tweak: omit_blob_tests")
  }
  test_select_bind(
    con,
    ctx,
    list(`::`(blob, blob)(as.raw(1:10)), `::`(blob, blob)(raw(3)), `::`(blob, blob)(NULL)),
    cast_fun = `$`(`$`(ctx, tweaks), blob_cast)
  )
})

test_that("is_valid_formals", {
  # <establish formals of described functions>
  expect_equal(names(formals(dbIsValid)), c("dbObj", "..."))
})

test_that("is_valid_connection", {
  #' @return
  #' `dbIsValid()` returns a logical scalar,
  #' `TRUE` if the object specified by `dbObj` is valid,
  #' `FALSE` otherwise.
  con <- connect(ctx)
  #' A [DBIConnection-class] object is initially valid,
  expect_true(expect_visible(dbIsValid(con)))
  expect_error(dbDisconnect(con), NA)
  #' and becomes invalid after disconnecting with [dbDisconnect()].
  expect_false(expect_visible(dbIsValid(con)))
})

test_that("is_valid_result_query", {
  query <- trivial_query()
  res <- dbSendQuery(con, query)
  on.exit(dbClearResult(res))
  #' A [DBIResult-class] object is valid after a call to [dbSendQuery()],
  expect_true(expect_visible(dbIsValid(res)))
  expect_error(dbFetch(res), NA)
  #' and stays valid even after all rows have been fetched;
  expect_true(expect_visible(dbIsValid(res)))
  dbClearResult(res)
  on.exit(NULL)
  #' only clearing it with [dbClearResult()] invalidates it.
  expect_false(dbIsValid(res))
})

test_that("has_completed_formals", {
  # <establish formals of described functions>
  expect_equal(names(formals(dbHasCompleted)), c("res", "..."))
})

test_that("has_completed_query", {
  #' @return
  #' `dbHasCompleted()` returns a logical scalar.
  #' For a query initiated by [dbSendQuery()] with non-empty result set,
  res <- local_result(dbSendQuery(con, trivial_query()))
  #' `dbHasCompleted()` returns `FALSE` initially
  expect_false(expect_visible(dbHasCompleted(res)))
  #' and `TRUE` after calling [dbFetch()] without limit.
  check_df(dbFetch(res))
  expect_true(expect_visible(dbHasCompleted(res)))
})

test_that("has_completed_error", {
  #' @section Failure modes:
  res <- dbSendQuery(con, trivial_query())
  dbClearResult(res)
  #' Attempting to query completion status for a result set cleared with
  #' [dbClearResult()] gives an error.
  expect_error(dbHasCompleted(res))
})

test_that("has_completed_query_spec", {
  #' @section Specification:
  #' The completion status for a query is only guaranteed to be set to
  #' `FALSE` after attempting to fetch past the end of the entire result.
  #' Therefore, for a query with an empty result set,
  res <- local_result(dbSendQuery(con, "SELECT * FROM (SELECT 1 as a) AS x WHERE (1 = 0)"))
  #' the initial return value is unspecified,
  #' but the result value is `TRUE` after trying to fetch only one row.
  check_df(dbFetch(res, 1))
  expect_true(expect_visible(dbHasCompleted(res)))
})

test_that("has_completed_query_spec_partial", {
  #' @section Specification:
  #' Similarly, for a query with a result set of length n,
  res <- local_result(dbSendQuery(con, trivial_query()))
  #' the return value is unspecified after fetching n rows,
  check_df(dbFetch(res, 1))
  #' but the result value is `TRUE` after trying to fetch only one more
  #' row.
  check_df(dbFetch(res, 1))
  expect_true(expect_visible(dbHasCompleted(res)))
})

test_that("get_statement_formals", {
  # <establish formals of described functions>
  expect_equal(names(formals(dbGetStatement)), c("res", "..."))
})

test_that("get_statement_query", {
  #' @return
  #' `dbGetStatement()` returns a string, the query used in
  query <- trivial_query()
  #' either [dbSendQuery()]
  res <- local_result(dbSendQuery(con, query))
  s <- dbGetStatement(res)
  expect_type(s, "character")
  expect_identical(s, query)
})

test_that("get_statement_error", {
  #' @section Failure modes:
  res <- dbSendQuery(con, trivial_query())
  dbClearResult(res)
  #' Attempting to query the statement for a result set cleared with
  #' [dbClearResult()] gives an error.
  expect_error(dbGetStatement(res))
})

test_that("column_info_formals", {
  # <establish formals of described functions>
  expect_equal(names(formals(dbColumnInfo)), c("res", "..."))
})

test_that("column_info_closed", {
  #' @section Failure modes:
  #' An attempt to query columns for a closed result set raises an error.
  query <- trivial_query()

  res <- dbSendQuery(con, query)
  dbClearResult(res)

  expect_error(dbColumnInfo(res))
})

test_that("column_info_consistent", {
  res <- local_result(dbSendQuery(con, "SELECT 1.5 AS a, 2.5 AS b"))
  #' The column names are always consistent
  info <- dbColumnInfo(res)
  #' with the data returned by `dbFetch()`.
  data <- dbFetch(res)
  expect_identical(info$name, names(data))
})

test_that("column_info_consistent_unnamed", {
  if (as.package_version(`$`(`$`(ctx, tweaks), dbitest_version)) < "1.7.2") {
    skip(paste0("tweak: dbitest_version: ", `$`(`$`(ctx, tweaks), dbitest_version)))
  }
  res <- local_result(dbSendQuery(con, "SELECT 1.5, 2.5 AS a, 1.5, 3.5"))
  info <- dbColumnInfo(res)
  data <- dbFetch(res)
  expect_identical(`$`(info, name), names(data))
  expect_equal(data[["a"]], 2.5)
  expect_false(anyNA(names(data)))
  expect_true(all(names(data) != ""))
})

test_that("column_info_consistent_keywords", {
  #' Column names that correspond to SQL or R keywords are left unchanged.
  res <- local_result(dbSendQuery(con, paste0("SELECT 1.5 AS ", dbQuoteIdentifier(con, "for"))))
  info <- dbColumnInfo(res)
  data <- dbFetch(res)
  expect_identical(info$name, names(data))
  expect_equal(data[["for"]], 1.5)
})

test_that("get_row_count_formals", {
  # <establish formals of described functions>
  expect_equal(names(formals(dbGetRowCount)), c("res", "..."))
})

test_that("row_count_query", {
  #' @return
  #' `dbGetRowCount()` returns a scalar number (integer or numeric),
  #' the number of rows fetched so far.
  query <- trivial_query()
  #' After calling [dbSendQuery()],
  res <- local_result(dbSendQuery(con, query))
  rc <- dbGetRowCount(res)
  #' the row count is initially zero.
  expect_equal(rc, 0L)
  #' After a call to [dbFetch()] without limit,
  check_df(dbFetch(res))
  rc <- dbGetRowCount(res)
  #' the row count matches the total number of rows returned.
  expect_equal(rc, 1L)
})

test_that("row_count_query_limited", {
  query <- sql_union(.ctx = ctx, trivial_query(), "SELECT 2", "SELECT 3")
  res <- local_result(dbSendQuery(con, query))
  rc1 <- dbGetRowCount(res)
  expect_equal(rc1, 0L)
  #' Fetching a limited number of rows
  check_df(dbFetch(res, 2L))
  #' increases the number of rows by the number of rows returned,
  rc2 <- dbGetRowCount(res)
  expect_equal(rc2, 2L)
  #' even if fetching past the end of the result set.
  check_df(dbFetch(res, 2L))
  rc3 <- dbGetRowCount(res)
  expect_equal(rc3, 3L)
})

test_that("row_count_query_empty", {
  #' For queries with an empty result set,
  query <- sql_union(
    .ctx = ctx, "SELECT * FROM (SELECT 1 as a) a WHERE (0 = 1)"
  )
  res <- local_result(dbSendQuery(con, query))
  rc <- dbGetRowCount(res)
  #' zero is returned
  expect_equal(rc, 0L)
  check_df(dbFetch(res))
  rc <- dbGetRowCount(res)
  #' even after fetching.
  expect_equal(rc, 0L)
})

test_that("get_row_count_error", {
  #' @section Failure modes:
  res <- dbSendQuery(con, trivial_query())
  dbClearResult(res)
  #' Attempting to get the row count for a result set cleared with
  #' [dbClearResult()] gives an error.
  expect_error(dbGetRowCount(res))
})

test_that("get_rows_affected_formals", {
  # <establish formals of described functions>
  expect_equal(names(formals(dbGetRowsAffected)), c("res", "..."))
})

test_that("rows_affected_query", {
  query <- trivial_query()
  #' For queries issued with [dbSendQuery()],
  res <- local_result(dbSendQuery(con, query))
  rc <- dbGetRowsAffected(res)
  #' zero is returned before
  expect_equal(rc, 0L)
  check_df(dbFetch(res))
  rc <- dbGetRowsAffected(res)
  #' and after the call to `dbFetch()`.
  expect_equal(rc, 0L)
})

test_that("get_info_result", {
  res <- local_result(dbSendQuery(con, trivial_query()))
  info <- dbGetInfo(res)
  expect_type(info, "list")
  info_names <- names(info)
  necessary_names <- c("statement", "row.count", "rows.affected", "has.completed")
  for (name in necessary_names) {
    eval(bquote(expect_true(.(name) %in% info_names)))
  }
})
