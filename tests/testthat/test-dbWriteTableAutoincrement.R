context("dbWriteTable autoincrement")

# Helper variable and function
sql_ddl <- "CREATE TABLE `tbl` (
  `id`    INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
	`name`  TEXT    NOT NULL UNIQUE,
	`score` INTEGER NOT NULL);"

create_and_compare_table <- function( d_local, expected_remote_id ) {
  #Create a connection, create a table, and populate the table.
  con <- dbConnect(SQLite())
  on.exit(dbDisconnect(con), add = TRUE)

  dbExecute(con, sql_ddl)
  write_successful <- dbWriteTable(con, name = 'tbl', value = d_local, append = TRUE, row.names = FALSE)
  expect_true(write_successful)

  #Reads from the database and sort so comparisons are more robust.
  d_remote <- dbReadTable(con, "tbl")
  d_remote <- d_remote[order(d_remote$score), ]

  #Compares actual to expected values.
  expect_equal(d_remote$id,    expected_remote_id, label = "The autoincrement values should be assigned correctly.")
  expect_equal(d_remote$name,  d_local$name)
  expect_equal(d_remote$score, d_local$score)
  # rm(d_remote, d_local)
}

test_that("autoincrement column not present before sending to database", {
  #The column is created and populated in the DB.
  ds_local <- data.frame(
    # id             = <not created>, # The 'id' column is not declared in R.
    name             = letters,
    score            = 1:26,
    stringsAsFactors = FALSE
  )
  expected_ids <- 1:26
  create_and_compare_table(ds_local, expected_ids)
})

test_that("autoincrement populated before database with integers", {
  #The id column is set locally, which prevents/overrides the autoincrement assignment in the DB.
  ds_local <- data.frame(
    id               = 126:101,
    name             = letters,
    score            = 1:26,
    stringsAsFactors = FALSE
  )
  expected_ids <- 126:101
  create_and_compare_table(ds_local, expected_ids)
})

test_that("autoincrement populated before database with all NAs", {
  #The id column is set to NAs, and replaced by an incremented value in the DB.
  ds_local <- data.frame(
    id               = NA_integer_,
    name             = letters,
    score            = 1:26,
    stringsAsFactors = FALSE
  )
  expected_ids <- 1:26
  create_and_compare_table(ds_local, expected_ids)
})

test_that("autoincrement populated before database with some NAs in sequential order", {
  #The NA holes are assigned an autoincrementing value in the DB.
  ds_local <- data.frame(
    id               = c(101, 102, NA_integer_, 204, NA_integer_, 306, NA_integer_),
    name             = letters[1:7],
    score            = 1:7,
    stringsAsFactors = FALSE
  )
  expected_ids <- c(101, 102, 103, 204, 205, 306, 307) #Notice the jumps to 204 and to 306.
  create_and_compare_table(ds_local, expected_ids)
})

test_that("autoincrement populated before database with some NAs in reverse order", {
  # The id assignment in the local dataset is (mostly) reverse ordered.
  #   This test verifies the database assignment doesn't duplicate previous ID values.
  ds_local <- data.frame(
    id               = c(NA_integer_, 306, NA_integer_, -204, 103, 102, NA_integer_),
    name             = letters[1:7],
    score            = 1:7,
    stringsAsFactors = FALSE
  )
  expected_ids <- c(1, 306, 307, -204, 103, 102, 308) #The last value is `308`, not a duplicate `103`.
  create_and_compare_table(ds_local, expected_ids)
})

test_that("autoincrement partially populated before database with some all negative integers", {
  # The id assignment in the local dataset is either a missing number, or a negative number.
  #   This test verifies the database assignment doesn't assign a negative value, even if it would be the next largest value.
  ds_local <- data.frame(
    id               = c(-9, -8, NA_integer_, -6, -4, -3, NA_integer_),
    name             = letters[1:7],
    score            = 1:7,
    stringsAsFactors = FALSE
  )
  expected_ids <- c(-9, -8, 1, -6, -4, -3, 2)
  create_and_compare_table(ds_local, expected_ids)
})

test_that("autoincrement partially populated with duplicate IDs throws an error", {
  # The id assignment in the local dataset is either a missing number, or duplicated values.
  #   This test verifies the database assignment doesn't implicitly/silently override the duplicates with a unique value.
  ds_local <- data.frame(
    id               = c(1, 1, NA_integer_, NA_integer_, 3, 3, 3),
    name             = letters[1:7],
    score            = 1:7,
    stringsAsFactors = FALSE
  )

  con <- dbConnect(SQLite())
  on.exit(dbDisconnect(con), add = TRUE)

  dbExecute(con, sql_ddl)
  expect_error(
    dbWriteTable(con, name = 'tbl', value = ds_local, append = TRUE, row.names = FALSE),
    "UNIQUE constraint failed: tbl[.]id"
  )
})
