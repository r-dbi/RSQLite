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

test_that("begin_commit_return_value", {
  expect_invisible_true(dbBegin(con))
  on.exit({
    dbRollback(con)
  })
  expect_invisible_true(dbCommit(con))
  on.exit(NULL)
})

test_that("begin_rollback_return_value", {
  expect_invisible_true(dbBegin(con))
  expect_invisible_true(dbRollback(con))
})

test_that("commit_without_begin", {
  #' In addition, a call to `dbCommit()`
  expect_error(dbCommit(con))
})

test_that("rollback_without_begin", {
  #' or `dbRollback()`
  #' without a prior call to `dbBegin()` raises an error.
  expect_error(dbRollback(con))
})

test_that("begin_begin", {
  dbBegin(con)
  on.exit({
    dbRollback(con)
  })
  expect_error(dbBegin(con))
  dbCommit(con)
  on.exit(NULL)
})

test_that("begin_commit", {
  dbBegin(con)
  success <- FALSE
  expect_error(
    {
      dbCommit(con)
      success <- TRUE
    },
    NA
  )
  if (!success) dbRollback(con)
})

test_that("begin_write_commit", {
  table_name <- "dbit00"
  dbWriteTable(con, table_name, data.frame(a = 0L), overwrite = TRUE)
  dbBegin(con)
  on.exit({
    dbRollback(con)
  })
  dbExecute(con, paste0("INSERT INTO ", table_name, " (a) VALUES (1)"))
  expect_equal(check_df(dbReadTable(con, table_name)), data.frame(a = 0:1))
  dbCommit(con)
  on.exit(NULL)
  expect_equal(check_df(dbReadTable(con, table_name)), data.frame(a = 0:1))
})

test_that("begin_rollback", {
  #'
  #' A transaction
  dbBegin(con)
  #' can also be aborted with `dbRollback()`.
  expect_error(dbRollback(con), NA)
})

test_that("with_transaction_formals", {
  # <establish formals of described functions>
  expect_equal(names(formals(dbWithTransaction)), c("conn", "code", "..."))
})

test_that("with_transaction_return_value", {
  name <- random_table_name()
  expect_identical(dbWithTransaction(con, name), name)
})

test_that("with_transaction_error_nested", {
  dbBegin(con)
  #' gives an error.
  expect_error(dbWithTransaction(con, NULL))
  dbRollback(con)
})

test_that("with_transaction_side_effects", {
  expect_false(exists("a", inherits = FALSE))
  #' (such as the creation of new variables)
  dbWithTransaction(con, a <- 42)
  #' propagate to the calling environment.
  expect_identical(get0("a", inherits = FALSE), 42)
})
