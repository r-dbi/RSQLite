# Character columns as views into their Arrow arrays: `lazy_strings = TRUE`

# Whether a character vector is one of nanoarrow's views
is_lazy <- function(x) {
  any(grepl("altrep_chr", capture.output(.Internal(inspect(x)))))
}

test_that("lazy_strings is validated and recorded", {
  expect_error(dbConnect(SQLite(), lazy_strings = TRUE), "requires `arrow = TRUE`", fixed = TRUE)
  expect_error(dbConnect(SQLite(), arrow = TRUE, lazy_strings = NA), "must be `TRUE` or `FALSE`", fixed = TRUE)

  con <- local_arrow_con()
  expect_false(con@lazy_strings)
  con <- local_arrow_con(lazy_strings = TRUE)
  expect_true(con@lazy_strings)

  # Cloning keeps the option
  path <- withr::local_tempfile(fileext = ".sqlite")
  con <- dbConnect(SQLite(), path, arrow = TRUE, lazy_strings = TRUE)
  withr::defer(dbDisconnect(con))
  clone <- dbConnect(con)
  withr::defer(dbDisconnect(clone))
  expect_true(clone@lazy_strings)
})

test_that("lazy strings give the same data frames", {
  path <- withr::local_tempfile(fileext = ".sqlite")
  eager <- dbConnect(SQLite(), path, arrow = TRUE)
  withr::defer(dbDisconnect(eager))
  lazy <- dbConnect(SQLite(), path, arrow = TRUE, lazy_strings = TRUE)
  withr::defer(dbDisconnect(lazy))

  n <- 70000L # more than one chunk of a full fetch
  df_in <- data.frame(
    a = seq_len(n),
    s = c(letters, NA)[seq_len(n) %% 27 + 1],
    t = ifelse(seq_len(n) %% 5 == 0, NA_character_, paste0("value ", seq_len(n))),
    x = seq_len(n) / 7,
    stringsAsFactors = FALSE
  )
  dbWriteTable(eager, "t", df_in)

  df_eager <- dbReadTable(eager, "t")
  df_lazy <- dbReadTable(lazy, "t")
  expect_equal(df_eager, df_in)
  expect_equal(df_lazy, df_in)
  expect_false(is_lazy(df_eager$s))
  expect_true(is_lazy(df_lazy$s))
  expect_true(is_lazy(df_lazy$t))
  expect_type(df_lazy$a, "integer")

  # Chunks, an empty tail, and a zero-row result
  rs <- dbSendQuery(lazy, "SELECT * FROM t")
  chunk <- dbFetch(rs, 3)
  expect_equal(chunk, df_in[1:3, ])
  expect_true(is_lazy(chunk$s))
  rest <- dbFetch(rs)
  expect_equal(nrow(rest), n - 3L)
  expect_equal(dbFetch(rs, 3), df_in[0, ])
  dbClearResult(rs)
  expect_equal(dbGetQuery(lazy, "SELECT * FROM t WHERE 0"), df_in[0, ])

  # The view outlives the result and the connection
  con <- dbConnect(SQLite(), path, arrow = TRUE, lazy_strings = TRUE)
  df <- dbGetQuery(con, "SELECT s, t FROM t")
  dbDisconnect(con)
  gc()
  expect_equal(df$s, df_in$s)
  expect_equal(df$t, df_in$t)
})

test_that("lazy strings follow ptype", {
  con <- local_arrow_con(lazy_strings = TRUE)
  dbExecute(con, "CREATE TABLE t (id, txt, b)")
  dbExecute(con, "INSERT INTO t VALUES (1, 'a', X'0102'), (2, 'b', NULL)")

  df <- dbGetQuery(con, "SELECT * FROM t", ptype = list(id = character(), txt = factor(), b = blob::blob()))
  expect_true(is_lazy(df$id))
  expect_equal(df$id, c("1", "2"))
  expect_equal(df$txt, factor(c("a", "b")))
  expect_equal(df$b, blob::blob(as.raw(c(1, 2)), NULL))

  df <- dbGetQuery(con, "SELECT txt FROM t", ptype = list(txt = factor(levels = c("b", "a"))))
  expect_equal(df$txt, factor(c("a", "b"), levels = c("b", "a")))
})
