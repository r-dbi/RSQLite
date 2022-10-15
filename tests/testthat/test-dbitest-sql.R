# Created by DBItest::use_dbitest(), do not edit by hand

ctx <- get_default_context()

test_that("quote_string_formals", {
  # <establish formals of described functions>
  expect_equal(names(formals(dbQuoteString)), c("conn", "x", "..."))
})

test_that("quote_literal_formals", {
  # <establish formals of described functions>
  expect_equal(names(formals(dbQuoteLiteral)), c("conn", "x", "..."))
})

test_that("quote_identifier_formals", {
  # <establish formals of described functions>
  expect_equal(names(formals(dbQuoteIdentifier)), c("conn", "x", "..."))
})

test_that("unquote_identifier_formals", {
  # <establish formals of described functions>
  expect_equal(names(formals(dbUnquoteIdentifier)), c("conn", "x", "..."))
})

test_that("read_table_formals", {
  # <establish formals of described functions>
  expect_equal(names(formals(dbReadTable)), c("conn", "name", "..."))
})

test_that("create_table_formals", {
  # <establish formals of described functions>
  expect_equal(names(formals(dbCreateTable)), c("conn", "name", "fields", "...", "row.names", "temporary"))
})

test_that("append_table_formals", {
  # <establish formals of described functions>
  expect_equal(names(formals(dbAppendTable)), c("conn", "name", "value", "...", "row.names"))
})

test_that("write_table_formals", {
  # <establish formals of described functions>
  expect_equal(names(formals(dbWriteTable)), c("conn", "name", "value", "..."))
})

test_that("list_tables_formals", {
  # <establish formals of described functions>
  expect_equal(names(formals(dbListTables)), c("conn", "..."))
})

test_that("exists_table_formals", {
  # <establish formals of described functions>
  expect_equal(names(formals(dbExistsTable)), c("conn", "name", "..."))
})

test_that("remove_table_formals", {
  # <establish formals of described functions>
  expect_equal(names(formals(dbRemoveTable)), c("conn", "name", "..."))
})

test_that("list_objects_formals", {
  # <establish formals of described functions>
  expect_equal(names(formals(dbListObjects)), c("conn", "prefix", "..."))
})

test_that("list_fields_formals", {
  # <establish formals of described functions>
  expect_equal(names(formals(dbListFields)), c("conn", "name", "..."))
})
