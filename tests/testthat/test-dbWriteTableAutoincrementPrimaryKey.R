context("dbWriteTable Autoincrement with a Primary Key")

# Helper Testing Function
ddl <- "CREATE TABLE `tbl` (
  `id`    INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
	`name`  TEXT    NOT NULL UNIQUE,
	`score` INTEGER NOT NULL
);"

create_populated_table <- function( d_local ) {
  con <- dbConnect(SQLite())
  dbSendQuery(con, ddl)  
  dbWriteTable(con, name = 'tbl', value = d_local, append = TRUE, row.names = FALSE)
  
  ds_remote <- dbReadTable(con, "tbl")
  ds_remote <- ds_remote[order(ds_remote$score), ] #Sort returned data.frame so comparisons are more robust.
  return( ds_remote )
}

test_that("autoincrement correctly populated by database", {
  ds_local <- data.frame(
    #Notice the 'id' column isn't set locally, only remotely.
    name             = letters,
    score            = 1:26,
    stringsAsFactors = FALSE
  )
  
  ds_remote <- create_populated_table(ds_local)

  expect_equal(ds_remote$name,  ds_local$name)
  expect_equal(ds_remote$score, ds_local$score)
  expect_equal(ds_remote$id, ds_remote$score, label = "The autoincrement values should be assigned correctly.")
})

test_that("autoincrement column not present before sending to database", {
  ds_local <- data.frame(
    # Notice the 'id' column is not declared
    # id             = NA_integer_,
    name             = letters,
    score            = 1:26,
    stringsAsFactors = FALSE
  )
  
  ds_remote <- create_populated_table(ds_local)
  
  expect_equal(ds_remote$name,  ds_local$name)
  expect_equal(ds_remote$score, ds_local$score)
  expect_equal(ds_remote$id, ds_local$score, label = "The autoincrement values should be assigned correctly.")
})

test_that("autoincrement populated before database with integers", {
  ds_local <- data.frame(
    #Notice the 'id' column is set locally, which overrides the autoincrement assignment in the DB.
    id               = 126:101,
    name             = letters,
    score            = 1:26,
    stringsAsFactors = FALSE
  )
  
  ds_remote <- create_populated_table(ds_local)
  ds_local  <- ds_local[order(ds_local$score), ]
  
  expect_equal(ds_remote$name,  ds_local$name)
  expect_equal(ds_remote$score, ds_local$score)
  expect_equal(ds_remote$id, 100 + rev(ds_remote$score), label = "The autoincrement values should be assigned correctly.")
})

test_that("autoincrement populated before database with all NAs", {
  ds_local <- data.frame(
    #Notice the 'id' column is set locally, which overrides the autoincrement assignment in the DB.
    id               = NA_integer_,
    name             = letters,
    score            = 1:26,
    stringsAsFactors = FALSE
  )
  
  ds_remote <- create_populated_table(ds_local)
  
  expect_equal(ds_remote$name,  ds_local$name)
  expect_equal(ds_remote$score, ds_local$score)
  expect_equal(ds_remote$id, ds_remote$score, label = "The autoincrement values should be assigned correctly.")
})

test_that("autoincrement populated before database with some NAs in sequential order", {
  ds_local <- data.frame(
    #Notice the 'id' column is set locally, which overrides the autoincrement assignment in the DB.
    id               = c(101, 102, NA_integer_, 204, NA_integer_, 306, NA_integer_),
    name             = letters[1:7],
    score            = 1:7,
    stringsAsFactors = FALSE
  )
  
  ds_remote <- create_populated_table(ds_local)
  expected_ids <- c(101, 102, 103, 204, 205, 306, 307) #Notice the jumps to 204 and to 306.
  
  expect_equal(ds_remote$name,  ds_local$name)
  expect_equal(ds_remote$score, ds_local$score)
  expect_equal(ds_remote$id, expected_ids, label = "The autoincrement values should be assigned correctly.")
})

test_that("autoincrement populated before database with some NAs in reverse order", {
  # The id assignment in the local dataset is (mostly) reverse ordered.
  #   This test verifies the database assignment doesn't duplicate previous ID values.
  ds_local <- data.frame(
    #Notice the 'id' column is set locally, which overrides the autoincrement assignment in the DB.
    id               = c(NA_integer_, 306, NA_integer_, -204, 103, 102, NA_integer_),
    name             = letters[1:7],
    score            = 1:7,
    stringsAsFactors = FALSE
  )
  
  ds_remote <- create_populated_table(ds_local)
  expected_ids <- c(1, 306, 307, -204, 103, 102, 308) #The last value is `308`, not a duplicate `103`.
  
  expect_equal(ds_remote$name,  ds_local$name)
  expect_equal(ds_remote$score, ds_local$score)
  expect_equal(ds_remote$id, expected_ids, label = "The autoincrement values should be assigned correctly.")
})

test_that("autoincrement partially populated before database with some all negative integers", {
  # The id assignment in the local dataset is either a missing number, or a negative number.
  #   This test verifies the database assignment doesn't assign a negative value, even if it would be the next largest value.
  ds_local <- data.frame(
    #Notice the 'id' column is set locally, which overrides the autoincrement assignment in the DB.
    id               = c(-9, -8, NA_integer_, -6, -4, -3, NA_integer_),
    name             = letters[1:7],
    score            = 1:7,
    stringsAsFactors = FALSE
  )
  
  ds_remote <- create_populated_table(ds_local)
  expected_ids <- c(-9, -8, 1, -6, -4, -3, 2)
  
  expect_equal(ds_remote$name,  ds_local$name)
  expect_equal(ds_remote$score, ds_local$score)
  expect_equal(ds_remote$id, expected_ids, label = "The autoincrement values should be assigned correctly.")
})

test_that("autoincrement partially populated with duplicate IDs throws an error", {
  # The id assignment in the local dataset is either a missing number, or duplicated values.
  #   This test verifies the database assignment doesn't implicitly override the duplicates with a unique value.
  con <- dbConnect(SQLite())
  ds_local <- data.frame(
    #Notice the 'id' column is set locally, which overrides the autoincrement assignment in the DB.
    id               = c(1, 1, NA_integer_, NA_integer_, 3, 3, 3),
    name             = letters[1:7],
    score            = 1:7,
    stringsAsFactors = FALSE
  )
  
  dbSendQuery(con, ddl)  
  expect_error(
    dbWriteTable(con, name = 'tbl', value = ds_local, append = TRUE, row.names = FALSE),
    "Error : UNIQUE constraint failed: tbl\\.id\n"
  )
})
