test_that("dbListObjects returns schemas as prefixes and tables directly", {
  con <- memory_db()
  on.exit(dbDisconnect(con), add = TRUE)

  # No tables yet
  result <- dbListObjects(con)
  expect_s3_class(result, "data.frame")
  expect_named(result, c("table", "is_prefix"))
  # Should include at least "main" as a schema prefix
  schema_names <- vapply(result$table[result$is_prefix], function(x) x@name[["schema"]], character(1))
  expect_true("main" %in% schema_names)

  # Add a table
  dbWriteTable(con, "mytable", data.frame(a = 1))
  result2 <- dbListObjects(con)
  table_names <- vapply(result2$table[!result2$is_prefix], function(x) x@name[["table"]], character(1))
  expect_true("mytable" %in% table_names)
})

test_that("dbListObjects snapshot - empty memory db", {
  con <- memory_db()
  on.exit(dbDisconnect(con), add = TRUE)

  expect_snapshot(dbListObjects(con))
})

test_that("dbListObjects snapshot - with prefix", {
  con <- memory_db()
  on.exit(dbDisconnect(con), add = TRUE)

  dbWriteTable(con, "foo", data.frame(x = 1))
  dbWriteTable(con, "bar", data.frame(y = 2))

  expect_snapshot(dbListObjects(con, prefix = Id(schema = "main")))
})

test_that("dbListObjects with schema prefix lists objects in that schema", {
  db1 <- tempfile(fileext = ".sqlite")
  db2 <- tempfile(fileext = ".sqlite")
  on.exit(
    {
      unlink(c(db1, db2), force = TRUE)
    },
    add = TRUE
  )

  # Create db2 with a table and view
  con2 <- dbConnect(SQLite(), db2)
  dbExecute(con2, "CREATE TABLE attached_table (id INTEGER, name TEXT)")
  dbExecute(con2, "CREATE VIEW attached_view AS SELECT * FROM attached_table")
  dbDisconnect(con2)

  # Connect to db1 and attach db2 as "mydb"
  con1 <- dbConnect(SQLite(), db1)
  on.exit(dbDisconnect(con1), add = TRUE)
  dbExecute(con1, "CREATE TABLE main_table (id INTEGER)")
  dbExecute(con1, paste0("ATTACH DATABASE '", db2, "' AS mydb"))

  # Without prefix: schemas are listed as prefixes
  result <- dbListObjects(con1)
  schema_names <- vapply(result$table[result$is_prefix], function(x) x@name[["schema"]], character(1))
  expect_true("mydb" %in% schema_names)
  expect_true("main" %in% schema_names)

  # With schema prefix: lists tables/views in attached database
  result_schema <- dbListObjects(con1, prefix = Id(schema = "mydb"))
  expect_s3_class(result_schema, "data.frame")
  expect_named(result_schema, c("table", "is_prefix"))
  expect_false(any(result_schema$is_prefix))

  obj_names <- vapply(result_schema$table, function(x) x@name[["table"]], character(1))
  expect_setequal(obj_names, c("attached_table", "attached_view"))

  # Verify schema is set in returned Ids
  obj_schemas <- vapply(result_schema$table, function(x) x@name[["schema"]], character(1))
  expect_true(all(obj_schemas == "mydb"))
})

test_that("dbListObjects with main schema prefix lists main tables", {
  con <- memory_db()
  on.exit(dbDisconnect(con), add = TRUE)

  dbWriteTable(con, "foo", data.frame(x = 1))
  dbWriteTable(con, "bar", data.frame(y = 2))

  result <- dbListObjects(con, prefix = Id(schema = "main"))
  expect_false(any(result$is_prefix))
  obj_names <- vapply(result$table, function(x) x@name[["table"]], character(1))
  expect_setequal(obj_names, c("foo", "bar"))
  obj_schemas <- vapply(result$table, function(x) x@name[["schema"]], character(1))
  expect_true(all(obj_schemas == "main"))
})

test_that("dbListObjects returns empty data frame for empty schema", {
  db1 <- tempfile(fileext = ".sqlite")
  db2 <- tempfile(fileext = ".sqlite")
  on.exit(unlink(c(db1, db2), force = TRUE), add = TRUE)

  # Create empty db2
  con2 <- dbConnect(SQLite(), db2)
  dbDisconnect(con2)

  con1 <- dbConnect(SQLite(), db1)
  on.exit(dbDisconnect(con1), add = TRUE)
  dbExecute(con1, paste0("ATTACH DATABASE '", db2, "' AS emptydb"))

  result <- dbListObjects(con1, prefix = Id(schema = "emptydb"))
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 0L)
})
