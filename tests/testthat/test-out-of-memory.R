# A heap limit of 16 MB above what SQLite uses lets the step succeed,
# but not the conversion of the large value to UTF-8.
# Those sizes depend on how SQLite allocates, so CRAN skips these tests.

test_that("dbFetch() raises out of memory for a text value it cannot convert", {
  skip_on_cran()

  for (check_utf8 in c(FALSE, TRUE)) {
    local({
      con <- local_utf16_large_text_con(check_utf8 = check_utf8)
      local_sqlite_heap_limit(16e6)

      expect_error(
        dbGetQuery(con, "SELECT id, s FROM t"),
        "Cannot read column 2: out of memory",
        fixed = TRUE,
        info = paste("check_utf8 =", check_utf8)
      )
    })
  }
})

test_that("dbFetch() raises out of memory for a date it cannot convert", {
  skip_on_cran()

  con <- local_utf16_large_text_con(extended_types = TRUE)
  local_sqlite_heap_limit(16e6)

  expect_error(
    dbGetQuery(con, "SELECT id, d FROM t"),
    "Cannot read column 2: out of memory",
    fixed = TRUE
  )
})

test_that("a fetch after out of memory does not blame an empty blob", {
  skip_on_cran()

  for (check_utf8 in c(FALSE, TRUE)) {
    local({
      con <- dbConnect(SQLite(), ":memory:", check_utf8 = check_utf8)
      on.exit(dbDisconnect(con))
      dbExecute(con, "PRAGMA encoding = 'UTF-16le'")
      dbExecute(con, "CREATE TABLE t (b TEXT, s TEXT)")
      dbExecute(
        con,
        "INSERT INTO t VALUES ('a', 'a'), (X'', ?)",
        params = list(strrep("x", 4e6))
      )
      res <- dbSendQuery(con, "SELECT b, s FROM t")
      on.exit(dbClearResult(res), add = TRUE, after = FALSE)
      expect_identical(dbFetch(res, n = 1)$b, "a")

      local({
        local_sqlite_heap_limit(16e6)
        expect_error(
          suppressWarnings(dbFetch(res, n = 1)),
          "Cannot read column 2: out of memory",
          fixed = TRUE,
          info = paste("check_utf8 =", check_utf8)
        )
      })

      # The same row is read again, with SQLITE_NOMEM still on the connection
      err <- expect_error(suppressWarnings(dbFetch(res, n = 1)))
      expect_identical(
        conditionMessage(err),
        "out of memory",
        info = paste("check_utf8 =", check_utf8)
      )
    })
  }
})

test_that("the large text value reads in full without a heap limit", {
  con <- local_utf16_large_text_con(check_utf8 = TRUE)

  out <- dbGetQuery(con, "SELECT id, s FROM t")
  expect_identical(nchar(out$s), c(1L, 4000000L))
})

test_that("empty text and blobs read as empty strings in UTF-16 databases", {
  for (check_utf8 in c(FALSE, TRUE)) {
    local({
      con <- dbConnect(SQLite(), ":memory:", check_utf8 = check_utf8)
      on.exit(dbDisconnect(con))
      dbExecute(con, "PRAGMA encoding = 'UTF-16le'")
      dbExecute(con, "CREATE TABLE t (x TEXT)")
      dbExecute(con, "INSERT INTO t VALUES (''), (X''), (zeroblob(0)), ('a')")

      # The blobs raise the warning for a column of mixed types
      out <- suppressWarnings(dbGetQuery(con, "SELECT x FROM t"))
      expect_identical(
        out$x,
        c("", "", "", "a"),
        info = paste("check_utf8 =", check_utf8)
      )
    })
  }
})
