context("affinity")

create_affinity_test_table <- function(con, affinity) {
  dbExecute(con, paste0("CREATE TABLE a (a ", affinity, ")"))
  dbWriteTable(con, "a", data.frame(a = NA_integer_), append = TRUE)
  dbWriteTable(con, "a", data.frame(a = 2L), append = TRUE)
  dbWriteTable(con, "a", data.frame(a = 3), append = TRUE)
  dbWriteTable(con, "a", data.frame(a = 4.5), append = TRUE)
  dbWriteTable(con, "a", data.frame(a = 5L), append = TRUE)
  dbWriteTable(con, "a", data.frame(a = "6"), append = TRUE)
  dbWriteTable(con, "a", data.frame(a = 7.5), append = TRUE)
  dbWriteTable(con, "a", data.frame(a = 8L), append = TRUE)
  dbWriteTable(con, "a", list_df(a = list(as.raw(9))), append = TRUE)
  dbWriteTable(con, "a", data.frame(a = 10L), append = TRUE)
}

check_affinity_get <- function(affinity, type,
                              real_type = "numeric", integer_type = type,
                              blob_integer_type = integer_type) {
  con <- memory_db()
  on.exit(dbDisconnect(con))

  create_affinity_test_table(con, affinity)

  expect_equal(class(dbGetQuery(con, "SELECT * FROM a LIMIT 0")$a), type)
  expect_equal(class(dbGetQuery(con, "SELECT * FROM a LIMIT 1")$a), type)
  expect_equal(class(dbGetQuery(con, "SELECT * FROM a LIMIT 2")$a), integer_type)
  expect_equal(class(dbGetQuery(con, "SELECT * FROM a LIMIT 3")$a), blob_integer_type)
  expect_equal(class(dbGetQuery(con, "SELECT * FROM a LIMIT 4")$a), real_type)
  expect_equal(class(dbGetQuery(con, "SELECT * FROM a LIMIT 5")$a), real_type)
  expect_equal(class(dbGetQuery(con, "SELECT * FROM a LIMIT 6")$a), real_type)
  expect_equal(class(dbGetQuery(con, "SELECT * FROM a LIMIT 7")$a), real_type)
  expect_equal(class(dbGetQuery(con, "SELECT * FROM a LIMIT 8")$a), real_type)
  expect_warning(
    expect_equal(class(dbGetQuery(con, "SELECT * FROM a LIMIT 9")$a), real_type),
    "coercing"
  )
  expect_warning(
    expect_equal(class(dbGetQuery(con, "SELECT * FROM a LIMIT 10")$a), real_type),
    "coercing"
  )
}

check_affinity_fetch <- function(affinity, type,
                                 real_type = "numeric", integer_type = type,
                                 blob_type = real_type) {
  con <- memory_db()
  on.exit(dbDisconnect(con))

  create_affinity_test_table(con, affinity)

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

test_that("affinity checks for dbGetQuery()", {
  check_affinity_get("INTEGER", "integer")
  check_affinity_get("TEXT", "character", "character")
  check_affinity_get("REAL", "numeric")
  check_affinity_get("INT", "integer")
  check_affinity_get("CHAR", "character", "character")
  check_affinity_get("CLOB", "character", "character")
  check_affinity_get("FLOA", "numeric")
  check_affinity_get("DOUB", "numeric")
  check_affinity_get("NUMERIC", "numeric", "numeric", "integer")
  expect_warning(
    check_affinity_get("BLOB", "blob", "numeric", "integer", "numeric"),
    "coercing"
  )
})

test_that("affinity checks for dbFetch()", {
  check_affinity_fetch("INTEGER", "integer")
  check_affinity_fetch("TEXT", "character", "character")
  check_affinity_fetch("REAL", "numeric")
  check_affinity_fetch("INT", "integer")
  check_affinity_fetch("CHAR", "character", "character")
  check_affinity_fetch("CLOB", "character", "character")
  check_affinity_fetch("FLOA", "numeric")
  check_affinity_fetch("DOUB", "numeric")
  check_affinity_fetch("NUMERIC", "numeric", "numeric", "integer")
  expect_warning(
    check_affinity_fetch("BLOB", "blob", "blob"),
    "coercing"
  )
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
