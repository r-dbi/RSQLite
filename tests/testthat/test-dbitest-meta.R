# Created by DBItest::use_dbitest(), do not edit by hand

ctx <- get_default_context()

test_that("is_valid_connection", {
  con <- connect(ctx)
  #' A [DBIConnection-class] object is initially valid,
  expect_true(expect_visible(dbIsValid(con)))
  expect_error(dbDisconnect(con), NA)
  #' and becomes invalid after disconnecting with [dbDisconnect()].
  expect_false(expect_visible(dbIsValid(con)))
})
