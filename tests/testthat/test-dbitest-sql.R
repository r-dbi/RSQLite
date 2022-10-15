# Created by DBItest::use_dbitest(), do not edit by hand

ctx <- get_default_context()

con <- local_connection(ctx)

test_that("quote_string_formals", {
  # <establish formals of described functions>
  expect_equal(names(formals(dbQuoteString)), c("conn", "x", "..."))
})

test_that("quote_string_return", {
  #' @return
  #' `dbQuoteString()` returns an object that can be coerced to [character],
  simple <- "simple"
  simple_out <- dbQuoteString(con, simple)
  expect_error(as.character(simple_out), NA)
  expect_type(as.character(simple_out), "character")
  expect_equal(length(simple_out), 1L)
})

test_that("quote_string_vectorized", {
  #' of the same length as the input.
  letters_out <- dbQuoteString(con, letters)
  expect_equal(length(letters_out), length(letters))

  #' For an empty character vector this function returns a length-0 object.
  empty_out <- dbQuoteString(con, character())
  expect_equal(length(empty_out), 0L)
})

test_that("quote_string_double", {
  simple <- "simple"
  simple_out <- dbQuoteString(con, simple)

  letters_out <- dbQuoteString(con, letters)

  empty <- character()
  empty_out <- dbQuoteString(con, character())

  #'
  #' When passing the returned object again to `dbQuoteString()`
  #' as `x`
  #' argument, it is returned unchanged.
  expect_identical(dbQuoteString(con, simple_out), simple_out)
  expect_identical(dbQuoteString(con, letters_out), letters_out)
  expect_identical(dbQuoteString(con, empty_out), empty_out)
  #' Passing objects of class [SQL] should also return them unchanged.
  expect_identical(dbQuoteString(con, SQL(simple)), SQL(simple))
  expect_identical(dbQuoteString(con, SQL(letters)), SQL(letters))
  expect_identical(dbQuoteString(con, SQL(empty)), SQL(empty))

  #' (For backends it may be most convenient to return [SQL] objects
  #' to achieve this behavior, but this is not required.)
})

test_that("quote_string_roundtrip", {
  do_test_string <- function(x) {
    query <- paste0("SELECT ", paste(dbQuoteString(con, x), collapse = ", "))
    x_out <- check_df(dbGetQuery(con, query))
    expect_equal(nrow(x_out), 1L)
    expect_identical(unlist(unname(x_out)), x)
  }
  expand_char <- function(...) {
    df <- expand.grid(..., stringsAsFactors = FALSE)
    do.call(paste0, df)
  }
  test_chars <- c("", " ", "\t", "'", "\"", "`", "\n")
  test_strings_0 <- expand_char(test_chars, "a", test_chars, "b", test_chars)
  test_strings_1 <- as.character(dbQuoteString(con, test_strings_0))
  test_strings_2 <- as.character(dbQuoteString(con, test_strings_1))
  test_strings <- c(test_strings_0, test_strings_1, test_strings_2)
  do_test_string(test_strings)
})

test_that("quote_string_na", {
  null <- dbQuoteString(con, NA_character_)
  quoted_null <- dbQuoteString(con, as.character(null))
  na <- dbQuoteString(con, "NA")
  quoted_na <- dbQuoteString(con, as.character(na))

  query <- paste0(
    "SELECT ",
    null, " AS null_return,",
    na, " AS na_return,",
    quoted_null, " AS quoted_null,",
    quoted_na, " AS quoted_na"
  )

  #' If `x` is `NA`, the result must merely satisfy [is.na()].
  rows <- check_df(dbGetQuery(con, query))
  expect_true(is.na(rows$null_return))
  #' The strings `"NA"` or `"NULL"` are not treated specially.
  expect_identical(rows$na_return, "NA")
  expect_identical(rows$quoted_null, as.character(null))
  expect_identical(rows$quoted_na, as.character(na))
})

test_that("quote_string_na_is_null", {
  #'
  #' `NA` should be translated to an unquoted SQL `NULL`,
  null <- dbQuoteString(con, NA_character_)
  #' so that the query `SELECT * FROM (SELECT 1) a WHERE ... IS NULL`
  rows <- check_df(dbGetQuery(con, paste0("SELECT * FROM (SELECT 1) a WHERE ", null, " IS NULL")))
  #' returns one row.
  expect_equal(nrow(rows), 1L)
})

test_that("quote_string_error", {
  #' @section Failure modes:
  #'
  #' Passing a numeric,
  expect_error(dbQuoteString(con, c(1, 2, 3)))
  #' integer,
  expect_error(dbQuoteString(con, 1:3))
  #' logical,
  expect_error(dbQuoteString(con, c(TRUE, FALSE)))
  #' or raw vector,
  expect_error(dbQuoteString(con, as.raw(1:3)))
  #' or a list
  expect_error(dbQuoteString(con, as.list(1:3)))
  #' for the `x` argument raises an error.
})

test_that("quote_literal_formals", {
  # <establish formals of described functions>
  expect_equal(names(formals(dbQuoteLiteral)), c("conn", "x", "..."))
})

test_that("quote_literal_return", {
  #' @return
  #' `dbQuoteLiteral()` returns an object that can be coerced to [character],
  simple <- "simple"
  simple_out <- dbQuoteLiteral(con, simple)
  expect_error(as.character(simple_out), NA)
  expect_type(as.character(simple_out), "character")
  expect_equal(length(simple_out), 1L)
})

test_that("quote_literal_vectorized", {
  #' of the same length as the input.
  letters_out <- dbQuoteLiteral(con, letters)
  expect_equal(length(letters_out), length(letters))
})

test_that("quote_literal_empty", {
  if (as.package_version(`$`(`$`(ctx, tweaks), dbitest_version)) < "1.7.2") {
    skip(paste0("tweak: dbitest_version: ", `$`(`$`(ctx, tweaks), dbitest_version)))
  }
  expect_equal(length(dbQuoteLiteral(con, integer())), 0L)
  expect_equal(length(dbQuoteLiteral(con, numeric())), 0L)
  expect_equal(length(dbQuoteLiteral(con, character())), 0L)
  expect_equal(length(dbQuoteLiteral(con, logical())), 0L)
  expect_equal(length(dbQuoteLiteral(con, Sys.Date()[0])), 0L)
  expect_equal(length(dbQuoteLiteral(con, Sys.time()[0])), 0L)
  expect_equal(length(dbQuoteLiteral(con, list())), 0L)
})

test_that("quote_literal_double", {
  simple <- "simple"
  simple_out <- dbQuoteLiteral(con, simple)

  letters_out <- dbQuoteLiteral(con, letters)

  empty <- character()
  empty_out <- dbQuoteLiteral(con, character())

  #'
  #' When passing the returned object again to `dbQuoteLiteral()`
  #' as `x`
  #' argument, it is returned unchanged.
  expect_identical(dbQuoteLiteral(con, simple_out), simple_out)
  expect_identical(dbQuoteLiteral(con, letters_out), letters_out)
  expect_identical(dbQuoteLiteral(con, empty_out), empty_out)
  #' Passing objects of class [SQL] should also return them unchanged.
  expect_identical(dbQuoteLiteral(con, SQL(simple)), SQL(simple))
  expect_identical(dbQuoteLiteral(con, SQL(letters)), SQL(letters))
  expect_identical(dbQuoteLiteral(con, SQL(empty)), SQL(empty))

  #' (For backends it may be most convenient to return [SQL] objects
  #' to achieve this behavior, but this is not required.)
})

test_that("quote_literal_roundtrip", {
  do_test_literal <- function(x) {
    literals <- vapply(x, dbQuoteLiteral, conn = con, character(1))
    query <- paste0("SELECT ", paste(literals, collapse = ", "))
    x_out <- check_df(dbGetQuery(con, query))
    expect_equal(nrow(x_out), 1L)
    is_logical <- vapply(x, is.logical, FUN.VALUE = logical(1))
    x_out[is_logical] <- lapply(x_out[is_logical], as.logical)
    is_numeric <- vapply(x, is.numeric, FUN.VALUE = logical(1))
    x_out[is_numeric] <- lapply(x_out[is_numeric], as.numeric)
    expect_equal(as.list(unname(x_out)), x)
  }
  test_literals <- list(1L, 2.5, "string", TRUE)
  do_test_literal(test_literals)
})

test_that("quote_literal_na", {
  null <- dbQuoteLiteral(con, NA_character_)
  quoted_null <- dbQuoteLiteral(con, as.character(null))
  na <- dbQuoteLiteral(con, "NA")
  quoted_na <- dbQuoteLiteral(con, as.character(na))

  query <- paste0(
    "SELECT ",
    null, " AS null_return,",
    na, " AS na_return,",
    quoted_null, " AS quoted_null,",
    quoted_na, " AS quoted_na"
  )

  #' If `x` is `NA`, the result must merely satisfy [is.na()].
  rows <- check_df(dbGetQuery(con, query))
  expect_true(is.na(rows$null_return))
  #' The literals `"NA"` or `"NULL"` are not treated specially.
  expect_identical(rows$na_return, "NA")
  expect_identical(rows$quoted_null, as.character(null))
  expect_identical(rows$quoted_na, as.character(na))
})

test_that("quote_literal_na_is_null", {
  #'
  #' `NA` should be translated to an unquoted SQL `NULL`,
  null <- dbQuoteLiteral(con, NA_character_)
  #' so that the query `SELECT * FROM (SELECT 1) a WHERE ... IS NULL`
  rows <- check_df(dbGetQuery(con, paste0("SELECT * FROM (SELECT 1) a WHERE ", null, " IS NULL")))
  #' returns one row.
  expect_equal(nrow(rows), 1L)
})

test_that("quote_literal_error", {
  #' @section Failure modes:
  #'
  #' Passing a list
  expect_error(dbQuoteString(con, as.list(1:3)))
  #' for the `x` argument raises an error.
})

test_that("quote_identifier_formals", {
  # <establish formals of described functions>
  expect_equal(names(formals(dbQuoteIdentifier)), c("conn", "x", "..."))
})

test_that("quote_identifier_return", {
  #' @return
  #' `dbQuoteIdentifier()` returns an object that can be coerced to [character],
  simple_out <- dbQuoteIdentifier(con, "simple")
  expect_error(as.character(simple_out), NA)
  expect_type(as.character(simple_out), "character")
})

test_that("quote_identifier_vectorized", {
  #' of the same length as the input.
  simple <- "simple"
  simple_out <- dbQuoteIdentifier(con, simple)
  expect_equal(length(simple_out), 1L)

  letters_out <- dbQuoteIdentifier(con, letters)
  expect_equal(length(letters_out), length(letters))

  #' For an empty character vector this function returns a length-0 object.
  empty <- character()
  empty_out <- dbQuoteIdentifier(con, empty)
  expect_equal(length(empty_out), 0L)

  #' The names of the input argument are preserved in the output.
  unnamed <- letters
  unnamed_out <- dbQuoteIdentifier(con, unnamed)
  expect_null(names(unnamed_out))
  named <- stats::setNames(LETTERS[1:3], letters[1:3])
  named_out <- dbQuoteIdentifier(con, named)
  expect_equal(names(named_out), letters[1:3])

  #' When passing the returned object again to `dbQuoteIdentifier()`
  #' as `x`
  #' argument, it is returned unchanged.
  expect_identical(dbQuoteIdentifier(con, simple_out), simple_out)
  expect_identical(dbQuoteIdentifier(con, letters_out), letters_out)
  expect_identical(dbQuoteIdentifier(con, empty_out), empty_out)
  #' Passing objects of class [SQL] should also return them unchanged.
  expect_identical(dbQuoteIdentifier(con, SQL(simple)), SQL(simple))
  expect_identical(dbQuoteIdentifier(con, SQL(letters)), SQL(letters))
  expect_identical(dbQuoteIdentifier(con, SQL(empty)), SQL(empty))

  #' (For backends it may be most convenient to return [SQL] objects
  #' to achieve this behavior, but this is not required.)
})

test_that("quote_identifier_error", {
  #' @section Failure modes:
  #'
  #' An error is raised if the input contains `NA`,
  expect_error(dbQuoteIdentifier(con, NA))
  expect_error(dbQuoteIdentifier(con, NA_character_))
  expect_error(dbQuoteIdentifier(con, c("a", NA_character_)))
  #' but not for an empty string.
  expect_error(dbQuoteIdentifier(con, ""), NA)
})

test_that("quote_identifier", {
  #' @section Specification:
  #' Calling [dbGetQuery()] for a query of the format `SELECT 1 AS ...`
  #' returns a data frame with the identifier, unquoted, as column name.
  #' Quoted identifiers can be used as table and column names in SQL queries,
  simple <- dbQuoteIdentifier(con, "simple")

  #' in particular in queries like `SELECT 1 AS ...`
  query <- trivial_query(column = simple)
  rows <- check_df(dbGetQuery(con, query))
  expect_identical(names(rows), "simple")
  expect_identical(unlist(unname(rows)), 1.5)

  #' and `SELECT * FROM (SELECT 1) ...`.
  query <- paste0("SELECT * FROM (", trivial_query(), ") ", simple)
  rows <- check_df(dbGetQuery(con, query))
  expect_identical(unlist(unname(rows)), 1.5)
})

test_that("quote_identifier_string", {
  #' The method must use a quoting mechanism that is unambiguously different
  #' from the quoting mechanism used for strings, so that a query like
  #' `SELECT ... FROM (SELECT 1 AS ...)`
  query <- paste0(
    "SELECT ", dbQuoteIdentifier(con, "b"), " FROM (",
    "SELECT 1 AS ", dbQuoteIdentifier(con, "a"), ")"
  )

  #' throws an error if the column names do not match.
  eval(bquote(expect_error(dbGetQuery(con, .(query)))))
})

test_that("quote_identifier_special", {
  with_space_in <- "with space"
  with_space <- dbQuoteIdentifier(con, with_space_in)
  with_dot_in <- "with.dot"
  with_dot <- dbQuoteIdentifier(con, with_dot_in)
  with_comma_in <- "with,comma"
  with_comma <- dbQuoteIdentifier(con, with_comma_in)
  with_quote_in <- as.character(dbQuoteString(con, "a"))
  with_quote <- dbQuoteIdentifier(con, with_quote_in)
  empty_in <- ""
  empty <- dbQuoteIdentifier(con, empty_in)
  quoted_empty <- dbQuoteIdentifier(con, as.character(empty))
  quoted_with_space <- dbQuoteIdentifier(con, as.character(with_space))
  quoted_with_dot <- dbQuoteIdentifier(con, as.character(with_dot))
  quoted_with_comma <- dbQuoteIdentifier(con, as.character(with_comma))
  quoted_with_quote <- dbQuoteIdentifier(con, as.character(with_quote))
  if (isTRUE(`$`(`$`(ctx, tweaks), strict_identifier))) {
    skip("tweak: strict_identifier")
  }
  query <- paste0("SELECT ", "2.5 as", with_space, ",", "3.5 as", with_dot, ",", "4.5 as", with_comma, ",", "5.5 as", with_quote, ",", "6.5 as", quoted_empty, ",", "7.5 as", quoted_with_space, ",", "8.5 as", quoted_with_dot, ",", "9.5 as", quoted_with_comma, ",", "10.5 as", quoted_with_quote)
  rows <- check_df(dbGetQuery(con, query))
  expect_identical(
    names(rows),
    c(with_space_in, with_dot_in, with_comma_in, with_quote_in, as.character(empty), as.character(with_space), as.character(with_dot), as.character(with_comma), as.character(with_quote))
  )
  expect_identical(unlist(unname(rows)), 2:10 + 0.5)
})

test_that("unquote_identifier_formals", {
  # <establish formals of described functions>
  expect_equal(names(formals(dbUnquoteIdentifier)), c("conn", "x", "..."))
})

test_that("unquote_identifier_return", {
  #' @return
  #' `dbUnquoteIdentifier()` returns a list of objects
  simple_in <- dbQuoteIdentifier(con, "simple")
  simple_out <- dbUnquoteIdentifier(con, simple_in)
  expect_type(simple_out, "list")
})

test_that("unquote_identifier_vectorized", {
  #' of the same length as the input.
  simple_in <- dbQuoteIdentifier(con, "simple")
  simple_out <- dbUnquoteIdentifier(con, simple_in)
  expect_equal(length(simple_out), 1L)

  letters_in <- dbQuoteIdentifier(con, letters)
  letters_out <- dbUnquoteIdentifier(con, letters_in)
  expect_equal(length(letters_out), length(letters_in))

  #' For an empty character vector this function returns a length-0 object.
  empty <- character()
  empty_in <- dbQuoteIdentifier(con, empty)
  empty_out <- dbUnquoteIdentifier(con, empty_in)
  expect_equal(length(empty_out), 0)

  #' The names of the input argument are preserved in the output.
  unnamed_in <- dbQuoteIdentifier(con, letters)
  unnamed_out <- dbUnquoteIdentifier(con, unnamed_in)
  expect_null(names(unnamed_out))
  named_in <- dbQuoteIdentifier(con, stats::setNames(LETTERS[1:3], letters[1:3]))
  named_out <- dbUnquoteIdentifier(con, named_in)
  expect_equal(names(named_out), letters[1:3])

  #' When passing the first element of a returned object again to
  #' `dbUnquoteIdentifier()` as `x`
  #' argument, it is returned unchanged (but wrapped in a list).
  expect_identical(dbUnquoteIdentifier(con, simple_out[[1]]), simple_out)
  expect_identical(dbUnquoteIdentifier(con, letters_out[[1]]), letters_out[1])
  #' Passing objects of class [Id] should also return them unchanged (but wrapped in a list).
  expect_identical(dbUnquoteIdentifier(con, Id(table = "simple")), list(Id(table = "simple")))

  #' (For backends it may be most convenient to return [Id] objects
  #' to achieve this behavior, but this is not required.)
})

test_that("unquote_identifier_error", {
  #' @section Failure modes:
  #'
  #' An error is raised if plain character vectors are passed as the `x`
  #' argument.
  expect_error(dbUnquoteIdentifier(con, NA_character_))
  expect_error(dbUnquoteIdentifier(con, c("a", NA_character_)))
  expect_error(dbUnquoteIdentifier(con, character()))
})

test_that("unquote_identifier_roundtrip", {
  #' @section Specification:
  #' For any character vector of length one, quoting (with [dbQuoteIdentifier()])
  #' then unquoting then quoting the first element is identical to just quoting.
  simple_in <- dbQuoteIdentifier(con, "simple")
  simple_out <- dbUnquoteIdentifier(con, simple_in)
  simple_roundtrip <- dbQuoteIdentifier(con, simple_out[[1]])
  expect_identical(simple_in, simple_roundtrip)
})

test_that("unquote_identifier_special", {
  with_space_in <- dbQuoteIdentifier(con, "with space")
  with_space_out <- dbUnquoteIdentifier(con, with_space_in)
  with_space_roundtrip <- dbQuoteIdentifier(con, with_space_out[[1]])
  with_dot_in <- dbQuoteIdentifier(con, "with.dot")
  with_dot_out <- dbUnquoteIdentifier(con, with_dot_in)
  with_dot_roundtrip <- dbQuoteIdentifier(con, with_dot_out[[1]])
  with_comma_in <- dbQuoteIdentifier(con, "with,comma")
  with_comma_out <- dbUnquoteIdentifier(con, with_comma_in)
  with_comma_roundtrip <- dbQuoteIdentifier(con, with_comma_out[[1]])
  with_quote_in <- dbQuoteIdentifier(con, as.character(dbQuoteString(con, "a")))
  with_quote_out <- dbUnquoteIdentifier(con, with_quote_in)
  with_quote_roundtrip <- dbQuoteIdentifier(con, with_quote_out[[1]])
  quoted_with_space_in <- dbQuoteIdentifier(con, as.character(with_space_in))
  quoted_with_space_out <- dbUnquoteIdentifier(con, quoted_with_space_in)
  quoted_with_space_roundtrip <- dbQuoteIdentifier(con, quoted_with_space_out[[1]])
  quoted_with_dot_in <- dbQuoteIdentifier(con, as.character(with_dot_in))
  quoted_with_dot_out <- dbUnquoteIdentifier(con, quoted_with_dot_in)
  quoted_with_dot_roundtrip <- dbQuoteIdentifier(con, quoted_with_dot_out[[1]])
  quoted_with_comma_in <- dbQuoteIdentifier(con, as.character(with_comma_in))
  quoted_with_comma_out <- dbUnquoteIdentifier(con, quoted_with_comma_in)
  quoted_with_comma_roundtrip <- dbQuoteIdentifier(con, quoted_with_comma_out[[1]])
  quoted_with_quote_in <- dbQuoteIdentifier(con, as.character(with_quote_in))
  quoted_with_quote_out <- dbUnquoteIdentifier(con, quoted_with_quote_in)
  quoted_with_quote_roundtrip <- dbQuoteIdentifier(con, quoted_with_quote_out[[1]])
  if (isTRUE(`$`(`$`(ctx, tweaks), strict_identifier))) {
    skip("tweak: strict_identifier")
  }
  expect_identical(with_space_in, with_space_roundtrip)
  expect_identical(with_dot_in, with_dot_roundtrip)
  expect_identical(with_comma_in, with_comma_roundtrip)
  expect_identical(with_quote_in, with_quote_roundtrip)
  expect_identical(quoted_with_space_in, quoted_with_space_roundtrip)
  expect_identical(quoted_with_dot_in, quoted_with_dot_roundtrip)
  expect_identical(quoted_with_comma_in, quoted_with_comma_roundtrip)
  expect_identical(quoted_with_quote_in, quoted_with_quote_roundtrip)
})

test_that("unquote_identifier_simple", {
  #' Unquoting simple strings (consisting of only letters) wrapped with [SQL()]
  #' and then quoting via [dbQuoteIdentifier()] gives the same result as just
  #' quoting the string.
  simple_in <- "simple"
  simple_quoted <- dbQuoteIdentifier(con, simple_in)
  simple_out <- dbUnquoteIdentifier(con, SQL(simple_in))
  simple_roundtrip <- dbQuoteIdentifier(con, simple_out[[1]])
  expect_identical(simple_roundtrip, simple_quoted)
})

test_that("unquote_identifier_table_schema", {
  #' Similarly, unquoting expressions of the form `SQL("schema.table")`
  #' and then quoting gives the same result as quoting the identifier
  #' constructed by `Id(schema = "schema", table = "table")`.
  schema_in <- "schema"
  table_in <- "table"
  simple_quoted <- dbQuoteIdentifier(con, Id(schema = schema_in, table = table_in))
  simple_out <- dbUnquoteIdentifier(con, SQL(paste0(schema_in, ".", table_in)))
  simple_roundtrip <- dbQuoteIdentifier(con, simple_out[[1]])
  expect_identical(simple_roundtrip, simple_quoted)
})

test_that("read_table_formals", {
  # <establish formals of described functions>
  expect_equal(names(formals(dbReadTable)), c("conn", "name", "..."))
})

test_that("read_table_row_names_false", {
  for (row.names in list(FALSE, NULL)) {
    table_name <- random_table_name()
    local_remove_test_table(con, table_name)
    mtcars_in <- `::`(datasets, mtcars)
    dbWriteTable(con, table_name, mtcars_in, row.names = TRUE)
    mtcars_out <- check_df(dbReadTable(con, table_name, row.names = row.names))
    expect_true("row_names" %in% names(mtcars_out))
    expect_true(all(`$`(mtcars_out, row_names) %in% rownames(mtcars_in)))
    expect_true(all(rownames(mtcars_in) %in% `$`(mtcars_out, row_names)))
    expect_equal_df(mtcars_out[names(mtcars_out) != "row_names"], unrowname(mtcars_in))
  }
})

test_that("read_table_name", {
  if (isTRUE(`$`(`$`(ctx, tweaks), strict_identifier))) {
    table_names <- "a"
  } else {
    table_names <- c("a", "with spaces", "with,comma")
  }
  for (table_name in table_names) {
    local_remove_test_table(con, table_name)
    test_in <- data.frame(a = 1L)
    dbWriteTable(con, table_name, test_in)
    test_out <- check_df(dbReadTable(con, table_name))
    expect_equal_df(test_out, test_in)
    test_out <- check_df(dbReadTable(con, dbQuoteIdentifier(con, table_name)))
    expect_equal_df(test_out, test_in)
  }
})

test_that("create_table_formals", {
  # <establish formals of described functions>
  expect_equal(names(formals(dbCreateTable)), c("conn", "name", "fields", "...", "row.names", "temporary"))
})

test_that("create_table_name", {
  if (isTRUE(`$`(`$`(ctx, tweaks), strict_identifier))) {
    table_names <- "a"
  } else {
    table_names <- c("a", "with spaces", "with,comma")
  }
  for (table_name in table_names) {
    test_in <- trivial_df()
    local_remove_test_table(con, table_name)
    dbCreateTable(con, table_name, test_in)
    test_out <- check_df(dbReadTable(con, dbQuoteIdentifier(con, table_name)))
    expect_equal_df(test_out, test_in[0, , drop = FALSE])
  }
})

test_that("create_table_name_quoted", {
  if (as.package_version(`$`(`$`(ctx, tweaks), dbitest_version)) < "1.7.2") {
    skip(paste0("tweak: dbitest_version: ", `$`(`$`(ctx, tweaks), dbitest_version)))
  }
  if (isTRUE(`$`(`$`(ctx, tweaks), strict_identifier))) {
    table_names <- "a"
  } else {
    table_names <- c("a", "with spaces", "with,comma")
  }
  for (table_name in table_names) {
    test_in <- trivial_df()
    local_remove_test_table(con, table_name)
    dbCreateTable(con, dbQuoteIdentifier(con, table_name), test_in)
    test_out <- check_df(dbReadTable(con, table_name))
    expect_equal_df(test_out, test_in[0, , drop = FALSE])
  }
})

test_that("create_temporary_table", {
  table_name <- "dbit03"
  expect_error(dbReadTable(con, table_name))
})

test_that("create_table_visible_in_other_connection", {
  penguins <- get_penguins(ctx)

  table_name <- "dbit04"

  #' in a pre-existing connection,
  expect_equal_df(check_df(dbReadTable(con, table_name)), penguins[0, , drop = FALSE])
})

test_that("create_roundtrip_keywords", {
  #' SQL keywords can be used freely in table names, column names, and data.
  tbl_in <- data.frame(
    select = "unique", from = "join", where = "order",
    stringsAsFactors = FALSE
  )
  test_table_roundtrip(con, tbl_in, name = "exists")
})

test_that("create_roundtrip_quotes", {
  if (isTRUE(`$`(`$`(ctx, tweaks), strict_identifier))) {
    skip("tweak: strict_identifier")
  }
  table_names <- c(as.character(dbQuoteIdentifier(con, "")), as.character(dbQuoteString(con, "")), "with space", ",")
  for (table_name in table_names) {
    tbl_in <- trivial_df(4, letters[1:4])
    names(tbl_in) <- c(as.character(dbQuoteIdentifier(con, "")), as.character(dbQuoteString(con, "")), "with space", ",")
    test_table_roundtrip(con, tbl_in)
  }
})

test_that("append_table_formals", {
  # <establish formals of described functions>
  expect_equal(names(formals(dbAppendTable)), c("conn", "name", "value", "...", "row.names"))
})

test_that("append_roundtrip_keywords", {
  #' @section Specification:
  #' SQL keywords can be used freely in table names, column names, and data.
  tbl_in <- data.frame(
    select = "unique", from = "join", where = "order",
    stringsAsFactors = FALSE
  )
  test_table_roundtrip(use_append = TRUE, con, tbl_in, name = "exists")
})

test_that("append_roundtrip_quotes_table_names", {
  if (isTRUE(`$`(`$`(ctx, tweaks), strict_identifier))) {
    skip("tweak: strict_identifier")
  }
  table_names <- c(as.character(dbQuoteIdentifier(con, "")), as.character(dbQuoteString(con, "")), "with space", "a,b", "a\nb", "a\tb", "a\rb", "a\bb", "a\\Nb", "a\\tb", "a\\rb", "a\\bb", "a\\Zb")
  tbl_in <- trivial_df()
  for (table_name in table_names) {
    test_table_roundtrip_one(con, tbl_in, use_append = TRUE, .add_na = FALSE)
  }
})

test_that("append_roundtrip_quotes_column_names", {
  if (isTRUE(`$`(`$`(ctx, tweaks), strict_identifier))) {
    skip("tweak: strict_identifier")
  }
  column_names <- c(as.character(dbQuoteIdentifier(con, "")), as.character(dbQuoteString(con, "")), "with space", "a,b", "a\nb", "a\tb", "a\rb", "a\bb", "a\\nb", "a\\tb", "a\\rb", "a\\bb", "a\\zb")
  tbl_in <- trivial_df(length(column_names), column_names)
  test_table_roundtrip_one(con, tbl_in, use_append = TRUE, .add_na = FALSE)
})

test_that("append_roundtrip_integer", {
  #' The following data types must be supported at least,
  #' and be read identically with [dbReadTable()]:
  #' - integer
  tbl_in <- data.frame(a = c(1:5))
  test_table_roundtrip(use_append = TRUE, con, tbl_in)
})

test_that("append_roundtrip_numeric", {
  #' - numeric
  tbl_in <- data.frame(a = c(seq(1, 3, by = 0.5)))
  test_table_roundtrip(use_append = TRUE, con, tbl_in)
  #'   (the behavior for `Inf` and `NaN` is not specified)
})

test_that("append_roundtrip_logical", {
  #' - logical
  tbl_in <- data.frame(a = c(TRUE, FALSE, NA))
  tbl_exp <- tbl_in
  tbl_exp$a <- ctx$tweaks$logical_return(tbl_exp$a)
  test_table_roundtrip(use_append = TRUE, con, tbl_in, tbl_exp)
})

test_that("append_roundtrip_null", {
  tbl_in <- data.frame(a = NA)
  test_table_roundtrip(
    use_append = TRUE,
    con,
    tbl_in,
    transform = function(tbl_out) {
      `$`(tbl_out, a) <- as.logical(`$`(tbl_out, a))
      tbl_out
    }
  )
})

test_that("append_roundtrip_64_bit_numeric", {
  tbl_in <- data.frame(a = c(-1e+14, 1e+15))
  test_table_roundtrip(
    use_append = TRUE,
    con,
    tbl_in,
    transform = function(tbl_out) {
      `$`(tbl_out, a) <- as.numeric(`$`(tbl_out, a))
      tbl_out
    },
    field.types = c(a = "BIGINT")
  )
})

test_that("append_roundtrip_64_bit_character", {
  tbl_in <- data.frame(a = c(-1e+14, 1e+15))
  tbl_exp <- tbl_in
  `$`(tbl_exp, a) <- format(`$`(tbl_exp, a), scientific = FALSE)
  test_table_roundtrip(
    use_append = TRUE,
    con,
    tbl_in,
    tbl_exp,
    transform = function(tbl_out) {
      `$`(tbl_out, a) <- as.character(`$`(tbl_out, a))
      tbl_out
    },
    field.types = c(a = "BIGINT")
  )
})

test_that("append_roundtrip_character", {
  #' - character (in both UTF-8
  tbl_in <- data.frame(
    id = seq_along(get_texts()),
    a = get_texts(),
    stringsAsFactors = FALSE
  )
  test_table_roundtrip(use_append = TRUE, con, tbl_in)
})

test_that("append_roundtrip_character_native", {
  #'   and native encodings),
  tbl_in <- data.frame(
    a = c(enc2native(get_texts())),
    stringsAsFactors = FALSE
  )
  test_table_roundtrip(use_append = TRUE, con, tbl_in)
})

test_that("append_roundtrip_character_empty", {
  #'   supporting empty strings
  tbl_in <- data.frame(
    a = c("", "a"),
    stringsAsFactors = FALSE
  )
  test_table_roundtrip(use_append = TRUE, con, tbl_in)
})

test_that("append_roundtrip_character_empty_after", {
  #'   (before and after non-empty strings)
  tbl_in <- data.frame(
    a = c("a", ""),
    stringsAsFactors = FALSE
  )
  test_table_roundtrip(use_append = TRUE, con, tbl_in)
})

test_that("append_roundtrip_factor", {
  #' - factor (returned as character,
  tbl_in <- data.frame(
    a = factor(get_texts())
  )
  tbl_exp <- tbl_in
  tbl_exp$a <- as.character(tbl_exp$a)
  #'     with a warning)
  suppressWarnings(
    expect_warning(
      test_table_roundtrip(use_append = TRUE, con, tbl_in, tbl_exp)
    )
  )
})

test_that("append_roundtrip_raw", {
  if (isTRUE(`$`(`$`(ctx, tweaks), omit_blob_tests))) {
    skip("tweak: omit_blob_tests")
  }
  tbl_in <- data.frame(id = 1L, a = I(list(as.raw(0:10))))
  tbl_exp <- tbl_in
  `$`(tbl_exp, a) <- `::`(blob, as_blob)(unclass(`$`(tbl_in, a)))
  test_table_roundtrip(
    use_append = TRUE,
    con,
    tbl_in,
    tbl_exp,
    transform = function(tbl_out) {
      `$`(tbl_out, a) <- `::`(blob, as_blob)(`$`(tbl_out, a))
      tbl_out
    }
  )
})

test_that("append_roundtrip_blob", {
  if (isTRUE(`$`(`$`(ctx, tweaks), omit_blob_tests))) {
    skip("tweak: omit_blob_tests")
  }
  tbl_in <- data.frame(id = 1L, a = `::`(blob, blob)(as.raw(0:10)))
  test_table_roundtrip(
    use_append = TRUE,
    con,
    tbl_in,
    transform = function(tbl_out) {
      `$`(tbl_out, a) <- `::`(blob, as_blob)(`$`(tbl_out, a))
      tbl_out
    }
  )
})

test_that("append_roundtrip_date", {
  if (!isTRUE(`$`(`$`(ctx, tweaks), date_typed))) {
    skip("tweak: !date_typed")
  }
  tbl_in <- data.frame(a = as_numeric_date(c(Sys.Date() + 1:5)))
  test_table_roundtrip(
    use_append = TRUE,
    con,
    tbl_in,
    transform = function(tbl_out) {
      expect_type(unclass(`$`(tbl_out, a)), "double")
      tbl_out
    }
  )
})

test_that("append_roundtrip_date_extended", {
  if (!isTRUE(`$`(`$`(ctx, tweaks), date_typed))) {
    skip("tweak: !date_typed")
  }
  tbl_in <- data.frame(
    a = as_numeric_date(
      c("1811-11-11", "1899-12-31", "1900-01-01", "1950-05-05", "1969-12-31", "1970-01-01", "2037-01-01", "2038-01-01", "2040-01-01", "2999-09-09")
    )
  )
  test_table_roundtrip(
    use_append = TRUE,
    con,
    tbl_in,
    transform = function(tbl_out) {
      expect_type(unclass(`$`(tbl_out, a)), "double")
      tbl_out
    }
  )
})

test_that("append_roundtrip_time", {
  if (!isTRUE(`$`(`$`(ctx, tweaks), time_typed))) {
    skip("tweak: !time_typed")
  }
  tbl_in <- data.frame(a = `::`(hms, hms)(minutes = 1:5))
  `$`(tbl_in, b) <- .difftime(as.numeric(`$`(tbl_in, a)) / 60, "mins")
  tbl_exp <- tbl_in
  `$`(tbl_exp, a) <- `::`(hms, as_hms)(`$`(tbl_exp, a))
  `$`(tbl_exp, b) <- `::`(hms, as_hms)(`$`(tbl_exp, b))
  test_table_roundtrip(
    con,
    tbl_in,
    tbl_exp,
    transform = function(tbl_out) {
      expect_s3_class(`$`(tbl_out, a), "difftime")
      expect_s3_class(`$`(tbl_out, b), "difftime")
      `$`(tbl_out, a) <- `::`(hms, as_hms)(`$`(tbl_out, a))
      `$`(tbl_out, b) <- `::`(hms, as_hms)(`$`(tbl_out, b))
      tbl_out
    }
  )
})

test_that("append_roundtrip_timestamp", {
  if (!isTRUE(`$`(`$`(ctx, tweaks), timestamp_typed))) {
    skip("tweak: !timestamp_typed")
  }
  local <- round(Sys.time()) + c(1, 60, 3600, 86400, 86400 * 90, 86400 * 180, 86400 * 270, 1e+09, 5e+09)
  attr(local, "tzone") <- ""
  tbl_in <- data.frame(id = seq_along(local))
  `$`(tbl_in, local) <- local
  `$`(tbl_in, gmt) <- `::`(lubridate, with_tz)(local, tzone = "GMT")
  `$`(tbl_in, pst8pdt) <- `::`(lubridate, with_tz)(local, tzone = "PST8PDT")
  `$`(tbl_in, utc) <- `::`(lubridate, with_tz)(local, tzone = "UTC")
  test_table_roundtrip(
    use_append = TRUE,
    con,
    tbl_in,
    transform = function(out) {
      dates <- vapply(out, inherits, "POSIXt", FUN.VALUE = logical(1L))
      tz <- toupper(names(out))
      tz[tz == "LOCAL"] <- ""
      out[dates] <- Map(`::`(lubridate, with_tz), out[dates], tz[dates])
      out
    }
  )
})

test_that("append_roundtrip_timestamp_extended", {
  if (!isTRUE(`$`(`$`(ctx, tweaks), timestamp_typed))) {
    skip("tweak: !timestamp_typed")
  }
  local <- as.POSIXct(
    c("1811-11-11", "1899-12-31", "1900-01-01", "1950-05-05", "1969-12-31", "1970-01-01", "2037-01-01", "2038-01-01", "2040-01-01", "2999-09-09")
  )
  attr(local, "tzone") <- ""
  tbl_in <- data.frame(id = seq_along(local))
  `$`(tbl_in, local) <- local
  `$`(tbl_in, gmt) <- `::`(lubridate, with_tz)(local, tzone = "GMT")
  `$`(tbl_in, pst8pdt) <- `::`(lubridate, with_tz)(local, tzone = "PST8PDT")
  `$`(tbl_in, utc) <- `::`(lubridate, with_tz)(local, tzone = "UTC")
  test_table_roundtrip(
    use_append = TRUE,
    con,
    tbl_in,
    transform = function(out) {
      dates <- vapply(out, inherits, "POSIXt", FUN.VALUE = logical(1L))
      tz <- toupper(names(out))
      tz[tz == "LOCAL"] <- ""
      out[dates] <- Map(`::`(lubridate, with_tz), out[dates], tz[dates])
      out
    }
  )
})

test_that("append_roundtrip_mixed", {
  data <- list("a", 1L, 1.5)
  data <- lapply(data, c, NA)
  expanded <- expand.grid(a = data, b = data, c = data)
  tbl_in_list <- lapply(
    seq_len(nrow(expanded)),
    function(i) {
      as.data.frame(lapply(expanded[i, ], unlist, recursive = FALSE))
    }
  )
  lapply(tbl_in_list, test_table_roundtrip, con = con)
})

test_that("append_table_name", {
  if (isTRUE(`$`(`$`(ctx, tweaks), strict_identifier))) {
    table_names <- "a"
  } else {
    table_names <- c("a", "with spaces", "with,comma")
  }
  for (table_name in table_names) {
    test_in <- trivial_df()
    local_remove_test_table(con, table_name)
    dbCreateTable(con, table_name, test_in)
    dbAppendTable(con, table_name, test_in)
    test_out <- check_df(dbReadTable(con, dbQuoteIdentifier(con, table_name)))
    expect_equal_df(test_out, test_in)
  }
})

test_that("append_table_name_quoted", {
  if (as.package_version(`$`(`$`(ctx, tweaks), dbitest_version)) < "1.7.2") {
    skip(paste0("tweak: dbitest_version: ", `$`(`$`(ctx, tweaks), dbitest_version)))
  }
  if (isTRUE(`$`(`$`(ctx, tweaks), strict_identifier))) {
    table_names <- "a"
  } else {
    table_names <- c("a", "with spaces", "with,comma")
  }
  for (table_name in table_names) {
    test_in <- trivial_df()
    local_remove_test_table(con, table_name)
    dbCreateTable(con, dbQuoteIdentifier(con, table_name), test_in)
    dbAppendTable(con, dbQuoteIdentifier(con, table_name), test_in)
    test_out <- check_df(dbReadTable(con, table_name))
    expect_equal_df(test_out, test_in)
  }
})

test_that("write_table_formals", {
  # <establish formals of described functions>
  expect_equal(names(formals(dbWriteTable)), c("conn", "name", "value", "..."))
})

test_that("write_table_name", {
  if (isTRUE(`$`(`$`(ctx, tweaks), strict_identifier))) {
    table_names <- "a"
  } else {
    table_names <- c("a", "with spaces", "with,comma")
  }
  for (table_name in table_names) {
    test_in <- data.frame(a = 1)
    local_remove_test_table(con, table_name)
    dbWriteTable(con, table_name, test_in)
    test_out <- check_df(dbReadTable(con, dbQuoteIdentifier(con, table_name)))
    expect_equal_df(test_out, test_in)
  }
})

test_that("write_table_name_quoted", {
  if (as.package_version(`$`(`$`(ctx, tweaks), dbitest_version)) < "1.7.2") {
    skip(paste0("tweak: dbitest_version: ", `$`(`$`(ctx, tweaks), dbitest_version)))
  }
  if (isTRUE(`$`(`$`(ctx, tweaks), strict_identifier))) {
    table_names <- "a"
  } else {
    table_names <- c("a", "with spaces", "with,comma")
  }
  for (table_name in table_names) {
    test_in <- data.frame(a = 1)
    local_remove_test_table(con, table_name)
    dbWriteTable(con, dbQuoteIdentifier(con, table_name), test_in)
    test_out <- check_df(dbReadTable(con, table_name))
    expect_equal_df(test_out, test_in)
  }
})

test_that("temporary_table", {
  if (!isTRUE(`$`(`$`(ctx, tweaks), temporary_tables))) {
    skip("tweak: temporary_tables")
  }
  table_name <- "dbit08"
  expect_error(dbReadTable(con, table_name))
})

test_that("table_visible_in_other_connection", {
  #' in a pre-existing connection,
  penguins30 <- get_penguins(ctx)

  table_name <- "dbit09"

  expect_equal_df(check_df(dbReadTable(con, table_name)), penguins30)
})

test_that("roundtrip_keywords", {
  #' SQL keywords can be used freely in table names, column names, and data.
  tbl_in <- data.frame(
    select = "unique", from = "join", where = "order",
    stringsAsFactors = FALSE
  )
  test_table_roundtrip(con, tbl_in, name = "exists")
})

test_that("roundtrip_quotes_table_names", {
  if (isTRUE(`$`(`$`(ctx, tweaks), strict_identifier))) {
    skip("tweak: strict_identifier")
  }
  table_names <- c(as.character(dbQuoteIdentifier(con, "")), as.character(dbQuoteString(con, "")), "with space", "a,b", "a\nb", "a\tb", "a\rb", "a\bb", "a\\Nb", "a\\tb", "a\\rb", "a\\bb", "a\\Zb")
  tbl_in <- trivial_df()
  for (table_name in table_names) {
    test_table_roundtrip_one(con, tbl_in, .add_na = "none")
  }
})

test_that("roundtrip_quotes_column_names", {
  if (as.package_version(`$`(`$`(ctx, tweaks), dbitest_version)) < "1.7.2") {
    skip(paste0("tweak: dbitest_version: ", `$`(`$`(ctx, tweaks), dbitest_version)))
  }
  if (isTRUE(`$`(`$`(ctx, tweaks), strict_identifier))) {
    skip("tweak: strict_identifier")
  }
  column_names <- c(as.character(dbQuoteIdentifier(con, "")), as.character(dbQuoteString(con, "")), "with space", "a,b", "a\nb", "a\tb", "a\rb", "a\bb", "a\\nb", "a\\tb", "a\\rb", "a\\bb", "a\\zb")
  tbl_in <- trivial_df(length(column_names), column_names)
  test_table_roundtrip_one(con, tbl_in, .add_na = "none")
})

test_that("roundtrip_integer", {
  #' The following data types must be supported at least,
  #' and be read identically with [dbReadTable()]:
  #' - integer
  tbl_in <- data.frame(a = c(1:5))
  test_table_roundtrip(con, tbl_in)
})

test_that("roundtrip_numeric", {
  #' - numeric
  tbl_in <- data.frame(a = c(seq(1, 3, by = 0.5)))
  test_table_roundtrip(con, tbl_in)
  #'   (the behavior for `Inf` and `NaN` is not specified)
})

test_that("roundtrip_logical", {
  #' - logical
  tbl_in <- data.frame(a = c(TRUE, FALSE, NA))
  tbl_exp <- tbl_in
  tbl_exp$a <- ctx$tweaks$logical_return(tbl_exp$a)
  test_table_roundtrip(con, tbl_in, tbl_exp)
})

test_that("roundtrip_null", {
  tbl_in <- data.frame(a = NA)
  test_table_roundtrip(
    con,
    tbl_in,
    transform = function(tbl_out) {
      `$`(tbl_out, a) <- as.logical(`$`(tbl_out, a))
      tbl_out
    }
  )
})

test_that("roundtrip_64_bit_numeric", {
  tbl_in <- data.frame(a = c(-1e+14, 1e+15))
  test_table_roundtrip(
    con,
    tbl_in,
    transform = function(tbl_out) {
      `$`(tbl_out, a) <- as.numeric(`$`(tbl_out, a))
      tbl_out
    },
    field.types = c(a = "BIGINT")
  )
})

test_that("roundtrip_64_bit_character", {
  tbl_in <- data.frame(a = c(-1e+14, 1e+15))
  tbl_exp <- tbl_in
  `$`(tbl_exp, a) <- format(`$`(tbl_exp, a), scientific = FALSE)
  test_table_roundtrip(
    con,
    tbl_in,
    tbl_exp,
    transform = function(tbl_out) {
      `$`(tbl_out, a) <- as.character(`$`(tbl_out, a))
      tbl_out
    },
    field.types = c(a = "BIGINT")
  )
})

test_that("roundtrip_character", {
  #' - character (in both UTF-8
  tbl_in <- data.frame(
    id = seq_along(get_texts()),
    a = get_texts(),
    stringsAsFactors = FALSE
  )
  test_table_roundtrip(con, tbl_in)
})

test_that("roundtrip_character_native", {
  #'   and native encodings),
  tbl_in <- data.frame(
    a = c(enc2native(get_texts())),
    stringsAsFactors = FALSE
  )
  test_table_roundtrip(con, tbl_in)
})

test_that("roundtrip_character_empty", {
  #'   supporting empty strings
  tbl_in <- data.frame(
    a = c("", "a"),
    stringsAsFactors = FALSE
  )
  test_table_roundtrip(con, tbl_in)
})

test_that("roundtrip_character_empty_after", {
  #'   before and after a non-empty string
  tbl_in <- data.frame(
    a = c("a", ""),
    stringsAsFactors = FALSE
  )
  test_table_roundtrip(con, tbl_in)
})

test_that("roundtrip_factor", {
  #' - factor (returned as character)
  tbl_in <- data.frame(
    a = factor(get_texts())
  )
  tbl_exp <- tbl_in
  tbl_exp$a <- as.character(tbl_exp$a)
  test_table_roundtrip(con, tbl_in, tbl_exp)
})

test_that("roundtrip_raw", {
  if (isTRUE(`$`(`$`(ctx, tweaks), omit_blob_tests))) {
    skip("tweak: omit_blob_tests")
  }
  tbl_in <- data.frame(id = 1L, a = I(list(as.raw(0:10))))
  tbl_exp <- tbl_in
  `$`(tbl_exp, a) <- `::`(blob, as_blob)(unclass(`$`(tbl_in, a)))
  test_table_roundtrip(
    con,
    tbl_in,
    tbl_exp,
    transform = function(tbl_out) {
      `$`(tbl_out, a) <- `::`(blob, as_blob)(`$`(tbl_out, a))
      tbl_out
    }
  )
})

test_that("roundtrip_blob", {
  if (isTRUE(`$`(`$`(ctx, tweaks), omit_blob_tests))) {
    skip("tweak: omit_blob_tests")
  }
  tbl_in <- data.frame(id = 1L, a = `::`(blob, blob)(as.raw(0:10)))
  test_table_roundtrip(
    con,
    tbl_in,
    transform = function(tbl_out) {
      `$`(tbl_out, a) <- `::`(blob, as_blob)(`$`(tbl_out, a))
      tbl_out
    }
  )
})

test_that("roundtrip_date", {
  if (!isTRUE(`$`(`$`(ctx, tweaks), date_typed))) {
    skip("tweak: !date_typed")
  }
  tbl_in <- data.frame(a = as_numeric_date(c(Sys.Date() + 1:5)))
  test_table_roundtrip(
    con,
    tbl_in,
    transform = function(tbl_out) {
      expect_type(unclass(`$`(tbl_out, a)), "double")
      tbl_out
    }
  )
})

test_that("roundtrip_date_extended", {
  if (!isTRUE(`$`(`$`(ctx, tweaks), date_typed))) {
    skip("tweak: !date_typed")
  }
  tbl_in <- data.frame(
    a = as_numeric_date(
      c("1811-11-11", "1899-12-31", "1900-01-01", "1950-05-05", "1969-12-31", "1970-01-01", "2037-01-01", "2038-01-01", "2040-01-01", "2999-09-09")
    )
  )
  test_table_roundtrip(
    con,
    tbl_in,
    transform = function(tbl_out) {
      expect_type(unclass(`$`(tbl_out, a)), "double")
      tbl_out
    }
  )
})

test_that("roundtrip_time", {
  if (!isTRUE(`$`(`$`(ctx, tweaks), time_typed))) {
    skip("tweak: !time_typed")
  }
  tbl_in <- data.frame(a = `::`(hms, hms)(minutes = 1:5))
  `$`(tbl_in, b) <- .difftime(as.numeric(`$`(tbl_in, a)) / 60, "mins")
  tbl_exp <- tbl_in
  `$`(tbl_exp, a) <- `::`(hms, as_hms)(`$`(tbl_exp, a))
  `$`(tbl_exp, b) <- `::`(hms, as_hms)(`$`(tbl_exp, b))
  test_table_roundtrip(
    con,
    tbl_in,
    tbl_exp,
    transform = function(tbl_out) {
      expect_s3_class(`$`(tbl_out, a), "difftime")
      expect_s3_class(`$`(tbl_out, b), "difftime")
      `$`(tbl_out, a) <- `::`(hms, as_hms)(`$`(tbl_out, a))
      `$`(tbl_out, b) <- `::`(hms, as_hms)(`$`(tbl_out, b))
      tbl_out
    }
  )
})

test_that("roundtrip_timestamp", {
  if (!isTRUE(`$`(`$`(ctx, tweaks), timestamp_typed))) {
    skip("tweak: !timestamp_typed")
  }
  local <- round(Sys.time()) + c(1, 60, 3600, 86400, 86400 * 90, 86400 * 180, 86400 * 270, 1e+09, 5e+09)
  attr(local, "tzone") <- ""
  tbl_in <- data.frame(id = seq_along(local))
  `$`(tbl_in, local) <- local
  `$`(tbl_in, gmt) <- `::`(lubridate, with_tz)(local, tzone = "GMT")
  `$`(tbl_in, pst8pdt) <- `::`(lubridate, with_tz)(local, tzone = "PST8PDT")
  `$`(tbl_in, utc) <- `::`(lubridate, with_tz)(local, tzone = "UTC")
  test_table_roundtrip(
    con,
    tbl_in,
    transform = function(out) {
      dates <- vapply(out, inherits, "POSIXt", FUN.VALUE = logical(1L))
      tz <- toupper(names(out))
      tz[tz == "LOCAL"] <- ""
      out[dates] <- Map(`::`(lubridate, with_tz), out[dates], tz[dates])
      out
    }
  )
})

test_that("roundtrip_timestamp_extended", {
  if (!isTRUE(`$`(`$`(ctx, tweaks), timestamp_typed))) {
    skip("tweak: !timestamp_typed")
  }
  local <- as.POSIXct(
    c("1811-11-11", "1899-12-31", "1900-01-01", "1950-05-05", "1969-12-31", "1970-01-01", "2037-01-01", "2038-01-01", "2040-01-01", "2999-09-09")
  )
  attr(local, "tzone") <- ""
  tbl_in <- data.frame(id = seq_along(local))
  `$`(tbl_in, local) <- local
  `$`(tbl_in, gmt) <- `::`(lubridate, with_tz)(local, tzone = "GMT")
  `$`(tbl_in, pst8pdt) <- `::`(lubridate, with_tz)(local, tzone = "PST8PDT")
  `$`(tbl_in, utc) <- `::`(lubridate, with_tz)(local, tzone = "UTC")
  test_table_roundtrip(
    con,
    tbl_in,
    transform = function(out) {
      dates <- vapply(out, inherits, "POSIXt", FUN.VALUE = logical(1L))
      tz <- toupper(names(out))
      tz[tz == "LOCAL"] <- ""
      out[dates] <- Map(`::`(lubridate, with_tz), out[dates], tz[dates])
      out
    }
  )
})

test_that("roundtrip_mixed", {
  data <- list("a", 1L, 1.5)
  data <- lapply(data, c, NA)
  expanded <- expand.grid(a = data, b = data, c = data)
  tbl_in_list <- lapply(
    seq_len(nrow(expanded)),
    function(i) {
      as.data.frame(lapply(expanded[i, ], unlist, recursive = FALSE))
    }
  )
  lapply(tbl_in_list, test_table_roundtrip, con = con)
})

test_that("roundtrip_field_types", {
  #' The `field.types` argument must be a named character vector with at most
  #' one entry for each column.
  #' It indicates the SQL data type to be used for a new column.
  tbl_in <- data.frame(a = numeric(), b = character())
  #' If a column is missed from `field.types`, the type is inferred
  #' from the input data with [dbDataType()].
  tbl_exp <- data.frame(a = integer(), b = character())
  test_table_roundtrip(
    con, tbl_in, tbl_exp,
    field.types = c(a = "INTEGER")
  )

  tbl_in <- data.frame(a = numeric(), b = integer())
  tbl_exp <- data.frame(a = integer(), b = numeric())
  test_table_roundtrip(
    con, tbl_in, tbl_exp,
    field.types = c(b = "REAL", a = "INTEGER")
  )
})

test_that("write_table_row_names_false", {
  for (row.names in list(FALSE, NULL)) {
    table_name <- random_table_name()
    local_remove_test_table(con, table_name)
    mtcars_in <- `::`(datasets, mtcars)
    dbWriteTable(con, table_name, mtcars_in, row.names = row.names)
    mtcars_out <- check_df(dbReadTable(con, table_name, row.names = FALSE))
    expect_false("row_names" %in% names(mtcars_out))
    expect_equal_df(mtcars_out, unrowname(mtcars_in))
  }
})

test_that("list_tables_formals", {
  # <establish formals of described functions>
  expect_equal(names(formals(dbListTables)), c("conn", "..."))
})

test_that("list_tables", {
  #' As soon a table is removed from the database,
  #' it is also removed from the list of database tables.
  table_name <- "dbit07"
  tables <- dbListTables(con)
  expect_false(table_name %in% tables)
})

test_that("list_tables_quote", {
  if (isTRUE(`$`(`$`(ctx, tweaks), strict_identifier))) {
    table_names <- "a"
  } else {
    table_names <- c("a", "with spaces", "with,comma")
  }
  for (table_name in table_names) {
    local_remove_test_table(con, table_name)
    dbWriteTable(con, dbQuoteIdentifier(con, table_name), data.frame(a = 2L))
    tables <- dbListTables(con)
    expect_true(table_name %in% tables)
    expect_true(dbQuoteIdentifier(con, table_name) %in% dbQuoteIdentifier(con, tables))
  }
})

test_that("exists_table_formals", {
  # <establish formals of described functions>
  expect_equal(names(formals(dbExistsTable)), c("conn", "name", "..."))
})

test_that("exists_table", {
  table_name <- "dbit05"
  expect_false(expect_visible(dbExistsTable(con, table_name)))
})

test_that("exists_table_name", {
  if (isTRUE(`$`(`$`(ctx, tweaks), strict_identifier))) {
    table_names <- "a"
  } else {
    table_names <- c("a", "with spaces", "with,comma")
  }
  for (table_name in table_names) {
    local_remove_test_table(con, table_name)
    expect_false(dbExistsTable(con, table_name))
    test_in <- data.frame(a = 1L)
    dbWriteTable(con, table_name, test_in)
    expect_true(dbExistsTable(con, table_name))
    expect_true(dbExistsTable(con, dbQuoteIdentifier(con, table_name)))
  }
})

test_that("remove_table_formals", {
  # <establish formals of described functions>
  expect_equal(names(formals(dbRemoveTable)), c("conn", "name", "..."))
})

test_that("remove_table_name", {
  if (isTRUE(`$`(`$`(ctx, tweaks), strict_identifier))) {
    table_names <- "a"
  } else {
    table_names <- c("a", "with spaces", "with,comma")
  }
  test_in <- data.frame(a = 1L)
  for (table_name in table_names) {
    local_remove_test_table(con, table_name)
    dbWriteTable(con, table_name, test_in)
    expect_true(dbRemoveTable(con, table_name))
  }
})

test_that("remove_table_name_quoted", {
  if (as.package_version(`$`(`$`(ctx, tweaks), dbitest_version)) < "1.7.2") {
    skip(paste0("tweak: dbitest_version: ", `$`(`$`(ctx, tweaks), dbitest_version)))
  }
  if (isTRUE(`$`(`$`(ctx, tweaks), strict_identifier))) {
    table_names <- "a"
  } else {
    table_names <- c("a", "with spaces", "with,comma")
  }
  test_in <- data.frame(a = 1L)
  for (table_name in table_names) {
    local_remove_test_table(con, table_name)
    dbWriteTable(con, table_name, test_in)
    expect_true(dbRemoveTable(con, dbQuoteIdentifier(con, table_name)))
  }
})

test_that("list_objects_formals", {
  # <establish formals of described functions>
  expect_equal(names(formals(dbListObjects)), c("conn", "prefix", "..."))
})

test_that("list_objects", {
  #' As soon a table is removed from the database,
  #' it is also removed from the data frame of database objects.
  table_name <- "dbit06"

  objects <- dbListObjects(con)
  quoted_tables <- vapply(objects$table, dbQuoteIdentifier, conn = con, character(1))
  expect_false(dbQuoteIdentifier(con, table_name) %in% quoted_tables)
})

test_that("list_objects_quote", {
  if (isTRUE(`$`(`$`(ctx, tweaks), strict_identifier))) {
    table_names <- "a"
  } else {
    table_names <- c("a", "with spaces", "with,comma")
  }
  for (table_name in table_names) {
    local_remove_test_table(con, table_name)
    dbWriteTable(con, dbQuoteIdentifier(con, table_name), data.frame(a = 2L))
    objects <- dbListObjects(con)
    quoted_tables <- vapply(`$`(objects, table), dbQuoteIdentifier, conn = con, character(1))
    expect_true(dbQuoteIdentifier(con, table_name) %in% quoted_tables)
  }
})

test_that("list_objects_features", {
  objects <- dbListObjects(con)
  non_prefix_objects <- vapply(`$`(objects, table)[!`$`(objects, is_prefix)], dbQuoteIdentifier, conn = con, character(1))
  all_tables <- dbQuoteIdentifier(con, dbListTables(con))
  expect_equal(sort(non_prefix_objects), sort(as.character(all_tables)))
  sql <- lapply(`$`(objects, table)[!`$`(objects, is_prefix)], dbQuoteIdentifier, conn = con)
  unquoted <- vapply(sql, dbUnquoteIdentifier, conn = con, list(1))
  expect_equal(unquoted, unclass(`$`(objects, table)[!`$`(objects, is_prefix)]))
  if (!any(`$`(objects, is_prefix))) {
    skip("No schemas available")
  }
  for (schema in `::`(utils, head)(`$`(objects, table)[`$`(objects, is_prefix)])) {
    sub_objects <- dbListObjects(con, prefix = schema)
    for (sub_table in `::`(utils, head)(`$`(sub_objects, table)[!`$`(sub_objects, is_prefix)])) {
      if (!identical(sub_table, Id(schema = "information_schema", table = "FILES"))) {
        eval(
          bquote(
            expect_true(dbExistsTable(con, .(sub_table)), label = paste0("dbExistsTable(", dbQuoteIdentifier(con, sub_table), ")"))
          )
        )
      }
    }
  }
})

test_that("list_fields_formals", {
  # <establish formals of described functions>
  expect_equal(names(formals(dbListFields)), c("conn", "name", "..."))
})

test_that("list_fields_wrong_table", {
  #' @section Failure modes:
  #' If the table does not exist, an error is raised.
  name <- "missing"

  expect_false(dbExistsTable(con, name))
  expect_error(dbListFields(con, name))
})

test_that("list_fields_invalid_type", {
  #' Invalid types for the `name` argument
  #' (e.g., `character` of length not equal to one,
  expect_error(dbListFields(con, character()))
  expect_error(dbListFields(con, letters))
  #' or numeric)
  expect_error(dbListFields(con, 1))
  #' lead to an error.
})
