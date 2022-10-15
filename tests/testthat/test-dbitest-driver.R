# Created by DBItest::use_dbitest(), do not edit by hand

ctx <- get_default_context()

test_that("constructor", {
  pkg_name <- package_name(ctx)
  default_constructor_name <- gsub("^R", "", pkg_name)
  constructor_name <- `$`(`$`(ctx, tweaks), constructor_name) %||% default_constructor_name
  pkg_env <- getNamespace(pkg_name)
  eval(bquote(expect_true(.(constructor_name) %in% getNamespaceExports(pkg_env))))
  eval(bquote(expect_true(exists(.(constructor_name), mode = "function", pkg_env))))
  constructor <- get(constructor_name, mode = "function", pkg_env)
  expect_all_args_have_default_values(constructor)
  if (!isTRUE(`$`(`$`(ctx, tweaks), constructor_relax_args))) {
    expect_arglist_is_empty(constructor)
  }
})

test_that("data_type_formals", {
  # <establish formals of described function>
  expect_equal(names(formals(dbDataType)), c("dbObj", "obj", "..."))
})

test_that("data_type_driver", {
  test_data_type(ctx, ctx$drv)
})

test_that("get_info_driver", {
  info <- dbGetInfo(`$`(ctx, drv))
  expect_type(info, "list")
  info_names <- names(info)
  necessary_names <- c("driver.version", "client.version")
  for (name in necessary_names) {
    eval(bquote(expect_true(.(name) %in% info_names)))
  }
})

test_that("connect_formals", {
  # <establish formals of described functions>
  expect_equal(names(formals(dbConnect)), c("drv", "..."))
})

test_that("connect_can_connect", {
  con <- expect_visible(connect(ctx))
  #' `dbConnect()` returns an S4 object that inherits from [DBIConnection-class].
  expect_s4_class(con, "DBIConnection")
  dbDisconnect(con)
  #' This object is used to communicate with the database engine.
})

test_that("connect_format", {
  #'
  #' A [format()] method is defined for the connection object.
  desc <- format(con)
  #' It returns a string that consists of a single line of text.
  expect_type(desc, "character")
  expect_length(desc, 1)
  expect_false(grepl("\n", desc, fixed = TRUE))
})

test_that("connect_bigint_integer", {
  #' - `"integer"`: always return as `integer`, silently overflow
  con <- local_connection(ctx, bigint = "integer")
  res <- dbGetQuery(con, "SELECT 10000000000")
  expect_type(res[[1]], "integer")
})

test_that("connect_bigint_numeric", {
  #' - `"numeric"`: always return as `numeric`, silently round
  con <- local_connection(ctx, bigint = "numeric")
  res <- dbGetQuery(con, "SELECT 10000000000")
  expect_type(res[[1]], "double")
  expect_equal(res[[1]], 1e10)
})

test_that("connect_bigint_character", {
  #' - `"character"`: always return the decimal representation as `character`
  con <- local_connection(ctx, bigint = "character")
  res <- dbGetQuery(con, "SELECT 10000000000")
  expect_type(res[[1]], "character")
  expect_equal(res[[1]], "10000000000")
})

test_that("connect_bigint_integer64", {
  #' - `"integer64"`: return as a data type that can be coerced using
  #'   [as.integer()] (with warning on overflow), [as.numeric()]
  #'   and [as.character()]
  con <- local_connection(ctx, bigint = "integer64")
  res <- dbGetQuery(con, "SELECT 10000000000")
  expect_warning(expect_true(is.na(as.integer(res[[1]]))))
  expect_equal(as.numeric(res[[1]]), 1e10)
  expect_equal(as.character(res[[1]]), "10000000000")
})
