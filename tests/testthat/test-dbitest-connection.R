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

test_that("data_type_connection", {
  test_data_type(ctx, con)
})

test_that("get_info_connection", {
  info <- dbGetInfo(con)
  expect_type(info, "list")
  info_names <- names(info)
  necessary_names <- c("db.version", "dbname", "username", "host", "port")
  for (name in necessary_names) {
    eval(bquote(expect_true(.(name) %in% info_names)))
  }
  expect_false("password" %in% info_names)
})
