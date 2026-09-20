# Also copied into DBI
tryCatch(skip = function(e) message(conditionMessage(e)), {
  skip_on_cran()
  skip_if_not_installed("DBItest")

  DBItest::make_context(
    RSQLite::SQLite(),
    list(dbname = tempfile("DBItest", fileext = ".sqlite")),
    tweaks = DBItest::tweaks(
      dbitest_version = "1.8.1",
      constructor_relax_args = TRUE,
      placeholder_pattern = c("?", "$1", "$name", ":name"),
      date_cast = function(x) paste0("'", x, "'"),
      time_cast = function(x) paste0("'", x, "'"),
      timestamp_cast = function(x) paste0("'", x, "'"),
      logical_return = function(x) as.integer(x),
      date_typed = FALSE,
      time_typed = FALSE,
      timestamp_typed = FALSE
    ),
    name = "RSQLite"
  )
})

# SQLite integers are 64-bit, so an R integer column written to SQLite comes back
# as Arrow int64, which nanoarrow converts to double by default.
# These specs compare the round trip with expect_identical() against R integer
# columns, which no faithful Arrow mapping of SQLite can satisfy; DuckDB and ADBC
# map SQLite integers to 64 bits as well.
ARROW_ROUNDTRIP_SKIPS <- c(
  "arrow_read_table_arrow",
  "arrow_read_table_arrow_empty",
  "arrow_write_table_arrow_roundtrip_integer",
  "arrow_write_table_arrow_roundtrip_logical",
  "arrow_write_table_arrow_roundtrip_character",
  "arrow_write_table_arrow_roundtrip_blob",
  "arrow_write_table_arrow_roundtrip_mixed",
  "arrow_append_table_arrow_roundtrip_integer",
  "arrow_append_table_arrow_roundtrip_logical",
  "arrow_append_table_arrow_roundtrip_character",
  "arrow_append_table_arrow_roundtrip_blob",
  "arrow_append_table_arrow_roundtrip_mixed",
  NULL
)
