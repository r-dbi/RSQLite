# Created by DBItest::use_dbitest(), do not edit by hand

ctx <- get_default_context()

test_that("compliance", {
  key_methods <- get_key_methods()
  expect_identical(names(key_methods), c("Driver", "Connection", "Result"))
  pkg <- package_name(ctx)
  where <- asNamespace(pkg)
  sapply(names(key_methods), function(name) {
    dbi_class <- paste0("DBI", name)
    classes <- Filter(function(class) {
      extends(class, dbi_class) && `@`(getClass(class), virtual) == FALSE
    }, getClasses(where))
    expect_gte(length(classes), 1)
    class <- classes[[1]]
    mapply(function(method, args) {
      expect_has_class_method(method, class, args, where)
    }, names(key_methods[[name]]), key_methods[[name]])
  })
})

test_that("reexport", {
  pkg <- package_name(ctx)
  where <- asNamespace(pkg)
  dbi_names <- dbi_generics(`$`(`$`(ctx, tweaks), dbitest_version))
  exported_names <- suppressWarnings(`::`(callr, r)(function(pkg) {
    tryCatch(getNamespaceExports(getNamespace(pkg)), error = function(e) character())
  }, args = list(pkg = pkg)))
  if (length(exported_names) == 0) {
    skip("reexport: package must be installed for this test")
  }
  missing <- setdiff(dbi_names, exported_names)
  expect_equal(paste(missing, collapse = ", "), "")
})

test_that("ellipsis", {
  pkg <- package_name(ctx)
  where <- asNamespace(pkg)
  methods <- s4_methods(where, function(x) x == "DBI")
  methods <- methods[grep("^db", names(methods))]
  Map(expect_ellipsis_in_formals, methods, names(methods))
})
