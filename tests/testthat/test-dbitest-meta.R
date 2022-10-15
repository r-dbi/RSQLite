# Created by DBItest::use_dbitest(), do not edit by hand

ctx <- get_default_context()

test_that("bind_formals", {
  # <establish formals of described functions>
  expect_equal(names(formals(dbBind)), c("res", "params", "..."))
})

test_that("is_valid_formals", {
  # <establish formals of described functions>
  expect_equal(names(formals(dbIsValid)), c("dbObj", "..."))
})

test_that("is_valid_connection", {
  con <- connect(ctx)
  #' A [DBIConnection-class] object is initially valid,
  expect_true(expect_visible(dbIsValid(con)))
  expect_error(dbDisconnect(con), NA)
  #' and becomes invalid after disconnecting with [dbDisconnect()].
  expect_false(expect_visible(dbIsValid(con)))
})

test_that("has_completed_formals", {
  # <establish formals of described functions>
  expect_equal(names(formals(dbHasCompleted)), c("res", "..."))
})

test_that("get_statement_formals", {
  # <establish formals of described functions>
  expect_equal(names(formals(dbGetStatement)), c("res", "..."))
})

test_that("column_info_formals", {
  # <establish formals of described functions>
  expect_equal(names(formals(dbColumnInfo)), c("res", "..."))
})

test_that("get_row_count_formals", {
  # <establish formals of described functions>
  expect_equal(names(formals(dbGetRowCount)), c("res", "..."))
})

test_that("get_rows_affected_formals", {
  # <establish formals of described functions>
  expect_equal(names(formals(dbGetRowsAffected)), c("res", "..."))
})
