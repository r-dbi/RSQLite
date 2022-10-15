# Created by DBItest::use_dbitest(), do not edit by hand

ctx <- get_default_context()

test_that("send_query_formals", {
  # <establish formals of described functions>
  expect_equal(names(formals(dbSendQuery)), c("conn", "statement", "..."))
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

test_that("fetch_formals", {
  # <establish formals of described functions>
  expect_equal(names(formals(dbFetch)), c("res", "n", "..."))
})

test_that("clear_result_formals", {
  # <establish formals of described functions>
  expect_equal(names(formals(dbClearResult)), c("res", "..."))
})

test_that("get_query_formals", {
  # <establish formals of described functions>
  expect_equal(names(formals(dbGetQuery)), c("conn", "statement", "..."))
})

test_that("send_statement_formals", {
  # <establish formals of described functions>
  expect_equal(names(formals(dbSendStatement)), c("conn", "statement", "..."))
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

test_that("execute_formals", {
  # <establish formals of described functions>
  expect_equal(names(formals(dbExecute)), c("conn", "statement", "..."))
})
