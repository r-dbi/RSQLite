# dbConnect(arrow = TRUE): data frames travel through Arrow

local_arrow_con <- function(..., envir = parent.frame()) {
  con <- dbConnect(SQLite(), ":memory:", arrow = TRUE, ...)
  withr::defer(dbDisconnect(con), envir = envir)
  con
}

test_that("the arrow argument is validated and recorded", {
  con <- local_arrow_con()
  expect_true(con@arrow)

  con2 <- dbConnect(SQLite(), ":memory:")
  on.exit(dbDisconnect(con2))
  expect_false(con2@arrow)

  expect_error(dbConnect(SQLite(), ":memory:", arrow = NA), "arrow")
  expect_error(dbConnect(SQLite(), ":memory:", arrow = "yes"), "arrow")
})

test_that("dbFetch() converts Arrow chunks to the same data frames", {
  con <- local_arrow_con()
  df <- data.frame(
    i = c(1L, NA, 3L),
    d = c(1.5, NA, 3.5),
    s = c("a", NA, "c"),
    l = c(TRUE, NA, FALSE),
    stringsAsFactors = FALSE
  )
  df$b <- blob::blob(as.raw(1:2), NULL, as.raw(3))
  dbWriteTable(con, "t", df)

  out <- dbReadTable(con, "t")
  expected <- df
  expected$l <- as.integer(expected$l)
  expect_equal(out, expected)

  rs <- dbSendQuery(con, "SELECT * FROM t")
  on.exit(dbClearResult(rs))
  expect_equal(dbFetch(rs, n = 0), expected[0, ])
  expect_equal(dbFetch(rs, n = 2), expected[1:2, ])
  expect_false(dbHasCompleted(rs))
  last <- expected[3, ]
  rownames(last) <- NULL
  expect_equal(dbFetch(rs, n = -1), last)
  expect_true(dbHasCompleted(rs))
  expect_equal(nrow(dbFetch(rs)), 0L)
})

test_that("64-bit integers follow bigint on the Arrow path", {
  df <- data.frame(small = 1:2)
  df$big <- bit64::as.integer64(c("1099511627776", "2"))

  con <- local_arrow_con()
  dbWriteTable(con, "t", df)
  out <- dbReadTable(con, "t")
  expect_type(out$small, "integer")
  expect_s3_class(out$big, "integer64")
  expect_equal(out, df)

  con_num <- local_arrow_con(bigint = "numeric")
  dbWriteTable(con_num, "t", df)
  out <- dbReadTable(con_num, "t")
  expect_type(out$small, "integer")
  expect_equal(out$big, c(1099511627776, 2))

  con_chr <- local_arrow_con(bigint = "character")
  dbWriteTable(con_chr, "t", df)
  expect_equal(dbReadTable(con_chr, "t")$big, c("1099511627776", "2"))

  con_int <- local_arrow_con(bigint = "integer")
  dbWriteTable(con_int, "t", df)
  expect_equal(dbReadTable(con_int, "t")$big, c(NA, 2L))
})

test_that("extended types come back as Date, hms and POSIXct on the Arrow path", {
  con <- local_arrow_con(extended_types = TRUE)
  df <- data.frame(d = as.Date("2020-01-02") + 0:1)
  df$t <- hms::hms(c(61.5, NA))
  df$ts <- as.POSIXct(c("2020-01-02 03:04:05.5", NA), tz = "UTC")
  dbWriteTable(con, "t", df)

  out <- dbReadTable(con, "t")
  expect_equal(out, df)

  rs <- dbSendQuery(con, "SELECT * FROM t")
  on.exit(dbClearResult(rs))
  expect_equal(dbFetch(rs, n = 1), df[1, ])
})

test_that("untyped NULL columns are logical on the Arrow path", {
  con <- local_arrow_con()
  expect_equal(dbGetQuery(con, "SELECT NULL AS a"), data.frame(a = NA))
  expect_equal(dbGetQuery(con, "SELECT 1 AS a WHERE 0"), data.frame(a = logical()))
})

test_that("dbAppendTable() writes through Arrow", {
  con <- local_arrow_con()
  dbExecute(con, "CREATE TABLE t (a INTEGER, f TEXT, b BLOB, d REAL)")

  df <- data.frame(a = 1:2, f = factor(c("x", "y")))
  df$b <- I(list(as.raw(1), NULL))
  df$d <- as.Date("2020-01-02") + 0:1
  expect_warning(
    expect_equal(dbAppendTable(con, "t", df), 2L),
    "Factors converted to character"
  )

  out <- dbReadTable(con, "t")
  expect_equal(out$a, 1:2)
  expect_equal(out$f, c("x", "y"))
  expect_equal(out$b, blob::blob(as.raw(1), NULL))
  expect_equal(out$d, as.numeric(df$d))

  expect_error(dbAppendTable(con, "t", data.frame(a = I(list(1)))), "raw vectors")
  expect_error(dbAppendTable(con, "t", data.frame(a = 1L), row.names = TRUE), "row.names")
})

test_that("dbWriteTable() and row names work through Arrow", {
  con <- local_arrow_con()
  dbWriteTable(con, "mtcars", mtcars, row.names = TRUE)
  out <- dbReadTable(con, "mtcars", row.names = TRUE)
  expect_equal(out, mtcars)

  dbWriteTable(con, "mtcars", mtcars[1:2, ], overwrite = TRUE)
  expect_equal(nrow(dbReadTable(con, "mtcars")), 2L)
  dbWriteTable(con, "mtcars", mtcars[3:4, ], append = TRUE)
  expect_equal(nrow(dbReadTable(con, "mtcars")), 4L)
})

test_that("dbGetQuery() with parameters works through Arrow", {
  con <- local_arrow_con()
  dbWriteTable(con, "t", data.frame(a = 1:5))
  expect_equal(
    dbGetQuery(con, "SELECT a FROM t WHERE a > ? ORDER BY a", params = list(3L)),
    data.frame(a = 4:5)
  )
  expect_equal(
    dbGetQuery(con, "SELECT a FROM t WHERE a = ? ORDER BY a", params = list(c(1L, 2L))),
    data.frame(a = 1:2)
  )
})
