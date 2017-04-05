context("affinity")

check_affinity <- function(affinity, type, real_type = "numeric") {
  con <- memory_db()
  on.exit(dbDisconnect(con))

  dbExecute(con, paste0("CREATE TABLE a (a ", affinity, ")"))
  dbWriteTable(con, "a", data.frame(a = NA_integer_), append = TRUE)
  dbWriteTable(con, "a", data.frame(a = 1L), append = TRUE)
  dbWriteTable(con, "a", data.frame(a = 2), append = TRUE)
  dbWriteTable(con, "a", data.frame(a = 3.5), append = TRUE)
  dbWriteTable(con, "a", data.frame(a = 4L), append = TRUE)
  dbWriteTable(con, "a", data.frame(a = "5"), append = TRUE)
  dbWriteTable(con, "a", data.frame(a = 6.5), append = TRUE)
  dbWriteTable(con, "a", data.frame(a = 7L), append = TRUE)
  dbWriteTable(con, "a", list_df(a = list(as.raw(8))), append = TRUE)
  dbWriteTable(con, "a", data.frame(a = 9L), append = TRUE)

  expect_equal(class(dbGetQuery(con, "SELECT * FROM a LIMIT 0")$a), type)
  expect_equal(class(dbGetQuery(con, "SELECT * FROM a LIMIT 1")$a), type)
  expect_equal(class(dbGetQuery(con, "SELECT * FROM a LIMIT 2")$a), type)
  expect_equal(class(dbGetQuery(con, "SELECT * FROM a LIMIT 3")$a), type)
  expect_equal(class(dbGetQuery(con, "SELECT * FROM a LIMIT 4")$a), real_type)
  expect_equal(class(dbGetQuery(con, "SELECT * FROM a LIMIT 5")$a), real_type)
  expect_equal(class(dbGetQuery(con, "SELECT * FROM a LIMIT 6")$a), real_type)
  expect_equal(class(dbGetQuery(con, "SELECT * FROM a LIMIT 7")$a), real_type)
  expect_equal(class(dbGetQuery(con, "SELECT * FROM a LIMIT 8")$a), real_type)
  expect_warning(
    expect_equal(class(dbGetQuery(con, "SELECT * FROM a LIMIT 9")$a), real_type),
    if (type == "blob") NA else "coercing"
  )
  expect_warning(
    expect_equal(class(dbGetQuery(con, "SELECT * FROM a LIMIT 10")$a), real_type),
    if (type == "blob") NA else "coercing"
  )

  rs <- dbSendQuery(con, "SELECT * FROM a")
  expect_equal(class(dbFetch(rs, 0)$a), type)
  expect_equal(class(dbFetch(rs, 1)$a), type)
  expect_equal(class(dbFetch(rs, 1)$a), type)
  expect_equal(class(dbFetch(rs, 1)$a), type)
  expect_equal(class(dbFetch(rs, 1)$a), real_type)
  expect_equal(class(dbFetch(rs, 1)$a), real_type)
  expect_equal(class(dbFetch(rs, 1)$a), real_type)
  expect_equal(class(dbFetch(rs, 1)$a), real_type)
  expect_equal(class(dbFetch(rs, 1)$a), real_type)
  expect_warning(
    expect_equal(class(dbFetch(rs, 1)$a), real_type),
    if (type == "blob") NA else "coercing"
  )
  expect_equal(class(dbFetch(rs, 1)$a), real_type)
  dbClearResult(rs)
}

test_that("affinity checks", {
  check_affinity("INTEGER", "integer")
  check_affinity("TEXT", "character", "character")
  check_affinity("REAL", "numeric")
  check_affinity("INT", "integer")
  check_affinity("CHAR", "character", "character")
  check_affinity("CLOB", "character", "character")
  check_affinity("FLOA", "numeric")
  check_affinity("DOUB", "numeric")
  check_affinity("NUMERIC", "numeric")
  check_affinity("BLOB", "blob", "integer")
})

test_that("affinity checks for inline queries", {
  skip("NYI")
})

test_that("affinity of untyped NULL with repeated fetch", {
  conn <- dbConnect(SQLite(), ":memory:")
  res <- dbSendQuery(conn, "SELECT NULL UNION ALL SELECT NULL")
  expect_identical(dbFetch(res, 1)[[1]], NA)
  expect_identical(dbFetch(res, 1)[[1]], NA)
  dbClearResult(res)
  dbDisconnect(conn)
})
