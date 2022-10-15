# Created by DBItest::use_dbitest(), do not edit by hand

ctx <- get_default_context()

test_that("begin_formals", {
  # <establish formals of described functions>
  expect_equal(names(formals(dbBegin)), c("conn", "..."))
})

test_that("commit_formals", {
  # <establish formals of described functions>
  expect_equal(names(formals(dbCommit)), c("conn", "..."))
})

test_that("rollback_formals", {
  # <establish formals of described functions>
  expect_equal(names(formals(dbRollback)), c("conn", "..."))
})

test_that("with_transaction_formals", {
  # <establish formals of described functions>
  expect_equal(names(formals(dbWithTransaction)), c("conn", "code", "..."))
})
