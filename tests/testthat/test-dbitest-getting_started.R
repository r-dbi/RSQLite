# Created by DBItest::use_dbitest(), do not edit by hand

ctx <- get_default_context()

con <- local_connection(ctx)

test_that("package_dependencies", {
  #' A DBI backend is an R package
  pkg_path <- get_pkg_path(ctx)

  pkg_deps_df <- desc::desc_get_deps(pkg_path)
  pkg_imports <- pkg_deps_df$package[pkg_deps_df$type == "Imports"]

  #' which imports the \pkg{DBI}
  expect_true("DBI" %in% pkg_imports)
  #' and \pkg{methods}
  expect_true("methods" %in% pkg_imports)
  #' packages.
})

test_that("package_name", {
  pkg_name <- package_name(ctx)

  #' For better or worse, the names of many existing backends start with
  #' \sQuote{R}, e.g., \pkg{RSQLite}, \pkg{RMySQL}, \pkg{RSQLServer}; it is up
  #' to the backend author to adopt this convention or not.
  expect_match(pkg_name, "^R")
})
