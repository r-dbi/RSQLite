# Created by DBItest::use_dbitest(), do not edit by hand

ctx <- get_default_context()

test_that("disconnect_formals", {
  # <establish formals of described functions>
  expect_equal(names(formals(dbDisconnect)), c("conn", "..."))
})

test_that("can_disconnect", {
  con <- connect(ctx)
  #' `dbDisconnect()` returns `TRUE`, invisibly.
  expect_invisible_true(dbDisconnect(con))
})
