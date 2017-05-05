context("dbWriteTable")

# Not generic enough for DBItest
test_that("throws error if constraint violated", {
  con <- dbConnect(SQLite())
  on.exit(dbDisconnect(con), add = TRUE)

  x <- data.frame(col1 = 1:10, col2 = letters[1:10])

  dbWriteTable(con, "t1", x)
  dbExecute(con, "CREATE UNIQUE INDEX t1_c1_c2_idx ON t1(col1, col2)")
  expect_error(dbWriteTable(con, "t1", x, append = TRUE),
    "UNIQUE constraint failed")
})


# In memory --------------------------------------------------------------------

test_that("can't override existing table with default options", {
  con <- dbConnect(SQLite())
  on.exit(dbDisconnect(con))

  x <- data.frame(col1 = 1:10, col2 = letters[1:10])
  dbWriteTable(con, "t1", x)
  expect_error(dbWriteTable(con, "t1", x), "exists in database")
})

test_that("throws error if constrainted violated", {
  con <- dbConnect(SQLite())
  on.exit(dbDisconnect(con))

  x <- data.frame(col1 = 1:10, col2 = letters[1:10])

  dbWriteTable(con, "t1", x)
  dbExecute(con, "CREATE UNIQUE INDEX t1_c1_c2_idx ON t1(col1, col2)")
  expect_error(dbWriteTable(con, "t1", x, append = TRUE),
    "UNIQUE constraint failed")
})

test_that("can't add table when result set open", {
  # This needs to fail because cloning a temporary file or in memory
  # database creates new database
  con <- dbConnect(SQLite(), tempfile())
  on.exit(dbDisconnect(con))

  x <- data.frame(col1 = 1:10, col2 = letters[1:10])
  dbWriteTable(con, "t1", x)

  res <- dbSendQuery(con, "SELECT * FROM t1")
  expect_warning(dbWriteTable(con, "t2", x), "pending rows")
  expect_warning(dbClearResult(res), "Expired")
})

test_that("rownames not preserved by default", {
  con <- dbConnect(SQLite())
  on.exit(dbDisconnect(con))

  df <- data.frame(x = 1:10)
  row.names(df) <- paste(letters[1:10], 1:10, sep="")

  dbWriteTable(con, "t1", df)
  t1 <- dbReadTable(con, "t1")
  expect_identical(.row_names_info(t1), -10L)
})

test_that("rownames preserved with row.names = TRUE", {
  con <- dbConnect(SQLite())
  on.exit(dbDisconnect(con))

  df <- data.frame(x = 1:10)
  row.names(df) <- paste(letters[1:10], 1:10, sep="")

  dbWriteTable(con, "t1", df, row.names = TRUE)
  t1 <- dbReadTable(con, "t1", row.names = TRUE)
  expect_equal(rownames(t1), rownames(df))
})

test_that("commas in fields are preserved", {
  con <- dbConnect(SQLite())
  on.exit(dbDisconnect(con))

  df <- data.frame(
    x = c("ABC, Inc.","DEF Holdings"),
    stringsAsFactors = FALSE
  )
  dbWriteTable(con, "t1", df, row.names = FALSE)
  expect_equal(dbReadTable(con, "t1"), df)
})

test_that("NAs preserved in factors", {
  con <- dbConnect(SQLite())
  on.exit(dbDisconnect(con))

  df <- data.frame(x = 1:10, y = factor(LETTERS[1:10]))
  df$y[4] <- NA

  dbWriteTable(con, "bad_table", df)
  bad_table <- dbReadTable(con, "bad_table")
  expect_equal(bad_table$x, df$x)
  expect_equal(bad_table$y, as.character(df$y))
})

test_that("logical converted to int", {
  con <- dbConnect(SQLite())
  on.exit(dbDisconnect(con))

  local <- data.frame(x = 1:3, y = c(NA, TRUE, FALSE))
  dbWriteTable(con, "t1", local)
  remote <- dbReadTable(con, "t1")

  expect_equal(remote$y, as.integer(local$y))
})

test_that("can roundtrip special field names", {
  con <- dbConnect(SQLite())
  on.exit(dbDisconnect(con))

  local <- data.frame(x = 1:3, select = 1:3, `  ` = 1:3, check.names = FALSE)
  dbWriteTable(con, "torture", local)
  remote <- dbReadTable(con, "torture", check.names = FALSE)

  expect_equal(local, remote)
})

# From file -------------------------------------------------------------------

test_that("comments are preserved", {
  con <- dbConnect(SQLite())
  on.exit(dbDisconnect(con), add = TRUE)

  tmp_file <- tempfile()
  cat('A,B,C\n11,2#2,33\n', file = tmp_file)
  on.exit(file.remove(tmp_file), add = TRUE)

  dbWriteTable(con, "t1", tmp_file, header = TRUE, sep = ",")
  remote <- dbReadTable(con, "t1")
  expect_equal(remote$B, "2#2")
})

test_that("colclasses overridden by argument", {
  con <- dbConnect(SQLite())
  on.exit(dbDisconnect(con), add = TRUE)

  tmp_file <- tempfile()
  cat('A,B,C\n1,2,3\n4,5,6\na,7,8\n', file = tmp_file)
  on.exit(file.remove(tmp_file), add = TRUE)

  dbWriteTable(con, "t1", tmp_file, header = TRUE, sep = ",",
    colClasses = c("character", "integer", "double"))

  remote <- dbReadTable(con, "t1")
  expect_equal(sapply(remote, class),
    c(A="character", B="integer", C="numeric"))
})

test_that("options work", {
  con <- dbConnect(SQLite())
  on.exit(dbDisconnect(con))

  expected <- data.frame(
    a = c(1:3, NA),
    b = c("x", "y", "z", "E"),
    stringsAsFactors = FALSE
  )

  dbWriteTable(con, "dat", "dat-n.txt", sep="|", eol="\n", overwrite = TRUE)
  expect_equal(dbReadTable(con, "dat"), expected)

  dbWriteTable(con, "dat", "dat-rn.txt", sep="|", eol="\r\n", overwrite = TRUE)
  expect_equal(dbReadTable(con, "dat"), expected)
})

test_that("temporary works", {
  db_file <- tempfile(fileext = ".sqlite")
  con <- dbConnect(SQLite(), db_file)
  on.exit(dbDisconnect(con), add = TRUE)

  dbWriteTable(con, "prm", "dat-n.txt", sep="|", eol="\n", overwrite = TRUE)
  dbWriteTable(con, "tmp", "dat-n.txt", sep="|", eol="\n", overwrite = TRUE, temporary = TRUE)
  expect_true(dbExistsTable(con, "prm"))
  expect_true(dbExistsTable(con, "tmp"))

  con2 <- dbConnect(SQLite(), db_file)
  on.exit(dbDisconnect(con2), add = TRUE)

  expect_true(dbExistsTable(con2, "prm"))
  expect_false(dbExistsTable(con2, "tmp"))
})


# Append ------------------------------------------------------------------

test_that("appending to table ignores column order and column names", {
  con <- dbConnect(SQLite())
  on.exit(dbDisconnect(con), add = TRUE)

  dbWriteTable(con, "a", data.frame(a = 1, b = 2))
  expect_error(
    dbWriteTable(con, "a", data.frame(b = 1, a = 2), append = TRUE),
    "mismatch"
  )
  expect_error(
    dbWriteTable(con, "a", data.frame(c = 1, d = 2), append = TRUE),
    "mismatch"
  )
})

test_that("appending to table gives error if fewer columns", {
  con <- dbConnect(SQLite())
  on.exit(dbDisconnect(con), add = TRUE)

  dbWriteTable(con, "a", data.frame(a = 1, b = 2))
  dbWriteTable(con, "a", data.frame(b = 1), append = TRUE)
  expect_error(dbWriteTable(con, "a", data.frame(c = 1), append = TRUE))

  a <- dbReadTable(con, "a")
  expect_identical(a, data.frame(a = c(1, NA), b = c(2, 1)))
})

test_that("appending to table gives error if more columns", {
  con <- dbConnect(SQLite())
  on.exit(dbDisconnect(con), add = TRUE)

  dbWriteTable(con, "a", data.frame(a = 1, b = 2))
  expect_error(dbWriteTable(con, "a", data.frame(a = 1, b = 2, c = 3), append = TRUE))
  expect_error(dbWriteTable(con, "a", data.frame(d = 1, e = 2, f = 3), append = TRUE))

  a <- dbReadTable(con, "a")
  expect_identical(a, data.frame(a = 1, b = 2))
})


# Row names ---------------------------------------------------------------

test_that("dbWriteTable(row.names = 0)", {
  con <- dbConnect(SQLite())
  on.exit(dbDisconnect(con), add = TRUE)

  expect_warning(dbWriteTable(con, "mtcars", mtcars, row.names = 0))
  res <- dbReadTable(con, "mtcars")

  expect_equal(rownames(res), as.character(seq_len(nrow(mtcars))))
  rownames(res) <- rownames(mtcars)
  expect_identical(res, mtcars)
})

test_that("dbWriteTable(row.names = 1)", {
  memoise::forget(warning_once)
  con <- dbConnect(SQLite())
  on.exit(dbDisconnect(con), add = TRUE)

  expect_warning(dbWriteTable(con, "mtcars", mtcars, row.names = 1))
  res <- dbReadTable(con, "mtcars", row.names = TRUE)

  expect_identical(res, mtcars)
})

test_that("dbWriteTable(row.names = FALSE)", {
  con <- dbConnect(SQLite())
  on.exit(dbDisconnect(con), add = TRUE)

  dbWriteTable(con, "mtcars", mtcars, row.names = FALSE)
  res <- dbReadTable(con, "mtcars")

  expect_equal(rownames(res), as.character(seq_len(nrow(mtcars))))
  rownames(res) <- rownames(mtcars)
  expect_identical(res, mtcars)
})

test_that("dbWriteTable(row.names = TRUE)", {
  con <- dbConnect(SQLite())
  on.exit(dbDisconnect(con), add = TRUE)

  dbWriteTable(con, "mtcars", mtcars, row.names = TRUE)
  res <- dbReadTable(con, "mtcars", row.names = TRUE)

  expect_identical(res, mtcars)
})

test_that("dbWriteTable(iris, row.names = NA)", {
  con <- dbConnect(SQLite())
  on.exit(dbDisconnect(con), add = TRUE)

  dbWriteTable(con, "iris", iris, row.names = NA)
  res <- dbReadTable(con, "iris", row.names = NA)

  expect_equal(rownames(res), as.character(seq_len(nrow(iris))))
  res$Species = factor(res$Species)
  expect_identical(res, iris)
})

test_that("dbWriteTable(mtcars, row.names = NA)", {
  con <- dbConnect(SQLite())
  on.exit(dbDisconnect(con), add = TRUE)

  dbWriteTable(con, "mtcars", mtcars, row.names = NA)
  res <- dbReadTable(con, "mtcars", row.names = NA)

  expect_identical(res, mtcars)
})

test_that("dbWriteTable(iris, row.names = 'rn')", {
  con <- dbConnect(SQLite())
  on.exit(dbDisconnect(con), add = TRUE)

  dbWriteTable(con, "iris", iris, row.names = "rn")
  res <- dbReadTable(con, "iris", row.names = "rn")

  expect_equal(rownames(res), as.character(seq_len(nrow(iris))))
  res$Species = factor(res$Species)

  # Original row names are numeric, RSQLite returns them as character
  # for simplicity
  attr(res, "row.names") <- attr(iris, "row.names")
  expect_identical(res, iris)
})

test_that("dbWriteTable(mtcars, row.names = 'rn')", {
  con <- dbConnect(SQLite())
  on.exit(dbDisconnect(con), add = TRUE)

  dbWriteTable(con, "mtcars", mtcars, row.names = "rn")
  res <- dbReadTable(con, "mtcars", row.names = "rn")

  expect_identical(res, mtcars)
})


# AsIs --------------------------------------------------------------------

test_that("dbWriteTable with AsIs character fields", {
  con <- dbConnect(SQLite())
  on.exit(dbDisconnect(con))

  dbWriteTable(con, "a", data.frame(a = I(letters)))
  res <- dbReadTable(con, "a")

  expect_identical(res, data.frame(a = letters, stringsAsFactors = FALSE))
})

test_that("dbWriteTable with AsIs numeric fields", {
  con <- dbConnect(SQLite())
  on.exit(dbDisconnect(con))

  dbWriteTable(con, "a", data.frame(a = I(1:3)))
  res <- dbReadTable(con, "a")

  expect_identical(res, data.frame(a = 1:3))
})

test_that("dbWriteTable with AsIs list fields", {
  con <- dbConnect(SQLite())
  on.exit(dbDisconnect(con))

  dbWriteTable(con, "a", data.frame(a = I(list(as.raw(1:3), as.raw(4:5)))))
  res <- dbReadTable(con, "a")

  expected <- data.frame(a = 1:2)
  expected$a <- blob::blob(as.raw(1:3), as.raw(4:5))
  expect_identical(res, expected)
})

test_that("dbWriteTable with AsIs raw fields", {
  con <- dbConnect(SQLite())
  on.exit(dbDisconnect(con))

  expect_warning(dbWriteTable(con, "a", data.frame(a = I(as.raw(1:3)))),
                 " raw ")
  res <- dbReadTable(con, "a")

  expected <- data.frame(a = 1:3)
  expected$a <- as.character(as.raw(1:3))
  expect_identical(res, expected)
})
