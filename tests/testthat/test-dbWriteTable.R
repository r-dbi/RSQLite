context("dbWriteTable")

test_that("can't override existing table with default options", {
  con <- dbConnect(SQLite())

  x <- data.frame(col1 = 1:10, col2 = letters[1:10])  
  dbWriteTable(con, "t1", x)
  expect_error(dbWriteTable(con, "t1", x), "exists in database")
})

test_that("throws error if constraint violated", {
  con <- dbConnect(SQLite())

  x <- data.frame(col1 = 1:10, col2 = letters[1:10])
  
  dbWriteTable(con, "t1", x)
  dbGetQuery(con, "CREATE UNIQUE INDEX t1_c1_c2_idx ON t1(col1, col2)")
  expect_error(dbWriteTable(con, "t1", x, append = TRUE), 
    "UNIQUE constraint failed")
})

test_that("modifications retrieved by open result set", {
  con <- dbConnect(SQLite(), tempfile())

  x <- data.frame(col1 = 1:10, col2 = letters[1:10])
  dbWriteTable(con, "t1", x)
  
  res <- dbSendQuery(con, "SELECT * FROM t1")
  dbWriteTable(con, "t1", x, append = TRUE)
  expect_equal(nrow(dbFetch(res)), 20)
  dbClearResult(res)
})

test_that("rownames preserved", {
  con <- dbConnect(SQLite())

  df <- data.frame(x = 1:10)
  row.names(df) <- paste(letters[1:10], 1:10, sep="")
  
  dbWriteTable(con, "t1", df)
  t1 <- dbReadTable(con, "t1")
  expect_equal(rownames(t1), rownames(df))  
})

test_that("commas in fields are preserved", {
  con <- dbConnect(SQLite())
  
  df <- data.frame(
    x = c("ABC, Inc.","DEF Holdings"), 
    stringsAsFactors = FALSE
  )
  dbWriteTable(con, "t1", df, row.names = FALSE)
  expect_equal(dbReadTable(con, "t1"), df)
})

test_that("NAs preserved in factors", {
  con <- dbConnect(SQLite())

  df <- data.frame(x = 1:10, y = factor(LETTERS[1:10]))
  df$y[4] <- NA
  
  dbWriteTable(con, "bad_table", df)
  bad_table <- dbReadTable(con, "bad_table")
  expect_equal(bad_table$x, df$x)
  expect_equal(bad_table$y, as.character(df$y))
})

test_that("logical converted to int", {
  con <- dbConnect(SQLite())
  
  local <- data.frame(x = 1:3, y = c(NA, TRUE, FALSE))
  dbWriteTable(con, "t1", local)
  remote <- dbReadTable(con, "t1")
  
  expect_equal(remote$y, as.integer(local$y))
})

test_that("can roundtrip special field names", {
  con <- dbConnect(SQLite())

  local <- data.frame(x = 1:3, select = 1:3, `  ` = 1:3, check.names = FALSE)
  dbWriteTable(con, "torture", local)
  remote <- dbReadTable(con, "torture", check.names = FALSE)
  
  expect_equal(local, remote)
})

test_that("can round-trip utf-8", {
  con <- dbConnect(SQLite())
  
  local <- data.frame(x = "å")
  dbWriteTable(con, "utf8", local)
  remote <- dbReadTable(con, "utf8")
  
  expect_equal(remote$x, enc2utf8("å"))
})

test_that("autoincrement correctly populated by database", {
  con <- dbConnect(SQLite())
  
  ddl <- "CREATE TABLE `tbl` (
    `id`    INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  	`name`  TEXT    NOT NULL UNIQUE,
  	`score` INTEGER NOT NULL
  );"
  ds_local <- data.frame(
    #Notice the 'id' column isn't set locally, only remotely.
    name             = letters,
    score            = 1:26,
    stringsAsFactors = FALSE
  )
  
  dbSendQuery(con, ddl)  
  dbWriteTable(con, name = 'tbl', value = ds_local, append = TRUE, row.names = FALSE)
  
  ds_remote <- dbReadTable(con, "tbl")
  
  expect_equal(ds_remote[, c("name", "score")], ds_local[, c("name", "score")], label = "The two non-autoincrement columns should be correct.")
  expect_equal(ds_remote$id, ds_remote$score, label = "The two autoincrement values should be correct.")
})

test_that("autoincrement populated before database", {
  con <- dbConnect(SQLite())
  
  ddl <- "CREATE TABLE `tbl` (
    `id`    INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  	`name`  TEXT    NOT NULL UNIQUE,
  	`score` INTEGER NOT NULL
  );"
  ds_local <- data.frame(
    #Notice the 'id' column is set locally, which overrides the autoincrement assignment in the DB.
    id               = 126:101,
    name             = letters,
    score            = 1:26,
    stringsAsFactors = FALSE
  )
  
  dbSendQuery(con, ddl)  
  dbWriteTable(con, name = 'tbl', value = ds_local, append = TRUE, row.names = FALSE)
  
  ds_remote <- dbReadTable(con, "tbl")
  
  expect_equal(ds_remote$name,  ds_local$name[26:1],   label = "The two non-autoincrement columns should be correct (and reversed).")
  expect_equal(ds_remote$score, ds_local$score[26:1],  label = "The two non-autoincrement columns should be correct (and reversed).")
  expect_equal(ds_remote$id, rev(100+ds_remote$score), label = "The two autoincrement values should not be assigned by the database.")
})
