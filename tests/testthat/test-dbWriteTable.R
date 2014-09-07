context("dbWriteTable")

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
  dbGetQuery(con, "CREATE UNIQUE INDEX t1_c1_c2_idx ON t1(col1, col2)")
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
  expect_error(dbClearResult(res), "Expired")
})

test_that("rownames preserved", {
  con <- dbConnect(SQLite())
  on.exit(dbDisconnect(con))
  
  df <- data.frame(x = 1:10)
  row.names(df) <- paste(letters[1:10], 1:10, sep="")
  
  dbWriteTable(con, "t1", df)
  t1 <- dbReadTable(con, "t1")
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
  on.exit(dbDisconnect(con))
  
  tmp_file <- tempfile()
  cat('A,B,C\n11,2#2,33\n', file = tmp_file)
  on.exit(file.remove(tmp_file), add = TRUE)
  
  dbWriteTable(con, "t1", tmp_file, header = TRUE, sep = ",")
  remote <- dbReadTable(con, "t1")
  expect_equal(remote$B, "2#2")
})

test_that("colclasses overridden by argument", {
  con <- dbConnect(SQLite())
  on.exit(dbDisconnect(con))
  
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