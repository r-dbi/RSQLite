context("dbConnect")

os <- function() {
  ostype <- .Platform[["OS.type"]]
  if (ostype == "windows") return("windows")
  if (grepl("darwin", R.Version()$os)) return("osx")
  ostype
}

# Specific to RSQLite
test_that("can connect to memory database (#140)", {
  expect_true(
    dbDisconnect(dbConnect(SQLite(), ":memory:"))
  )
})

# Specific to RSQLite
test_that("invalid dbnames throw errors", {
  expect_error(dbConnect(SQLite(), dbname = 1:3))
  expect_error(dbConnect(SQLite(), dbname = c("a", "b")))
  expect_error(dbConnect(SQLite(), dbname = NA))
  expect_error(dbConnect(SQLite(), dbname = as.character(NA)))
})

# Specific to RSQLite
test_that("can get and set vfs values", {
  allowed <- switch(os(),
    osx = c("unix-posix", "unix-afp", "unix-flock", "unix-dotfile", "unix-none"),
    unix = c("unix-dotfile", "unix-none"),
    windows = character(0),
    character(0)
  )

  checkVfs <- function(v) {
    force(v)
    db <- dbConnect(SQLite(), vfs = v)
    on.exit(dbDisconnect(db))
    expect_equal(v, db@vfs)
  }
  for (v in allowed) checkVfs(v)
})

# Specific to RSQLite
test_that("forbidden operations throw errors", {
  tmpFile <- tempfile()
  on.exit(unlink(tmpFile))

  ## error if file does not exist
  expect_error(dbConnect(SQLite(), tmpFile, flags = SQLITE_RO), "unable to open")
  expect_error(dbConnect(SQLite(), tmpFile, flags = SQLITE_RW), "unable to open")

  dbrw <- dbConnect(SQLite(), tmpFile, flags = SQLITE_RWC)
  df <- data.frame(a=letters, b=runif(26L), stringsAsFactors=FALSE)
  expect_true(dbWriteTable(dbrw, "t1", df))
  dbDisconnect(dbrw)

  dbro <- dbConnect(SQLite(), dbname = tmpFile, flags = SQLITE_RO)
  expect_error(dbWriteTable(dbro, "t2", df), "readonly database")
  dbDisconnect(dbro)

  dbrw2 <- dbConnect(SQLite(), dbname = tmpFile, flags = SQLITE_RW)
  expect_true(dbWriteTable(dbrw2, "t2", df))
  dbDisconnect(dbrw2)
})

test_that("querying closed connection throws error", {
  db <- dbConnect(SQLite(), dbname = ":memory:")
  dbDisconnect(db)
  expect_error(
    dbGetQuery(db, "select * from foo"),
    "Invalid or closed connection",
    fixed = TRUE
  )
})

test_that("can connect to same db from multiple connections", {
  dbfile <- tempfile()
  con1 <- dbConnect(SQLite(), dbfile)
  con2 <- dbConnect(SQLite(), dbfile)
  on.exit(dbDisconnect(con2), add = TRUE)
  on.exit(dbDisconnect(con1), add = TRUE)

  dbWriteTable(con1, "airquality", airquality)
  expect_equal(dbReadTable(con2, "airquality"), airquality)
})

test_that("temporary tables are connection local", {
  dbfile <- tempfile()
  con1 <- dbConnect(SQLite(), dbfile)
  con2 <- dbConnect(SQLite(), dbfile)
  on.exit(dbDisconnect(con2), add = TRUE)
  on.exit(dbDisconnect(con1), add = TRUE)

  dbExecute(con1, "CREATE TEMPORARY TABLE temp (a TEXT)")
  expect_true(dbExistsTable(con1, "temp"))
  expect_false(dbExistsTable(con2, "temp"))
})
