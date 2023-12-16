if (rlang::is_installed("DBItest")) {
  default_skip <-
    c(
      if (packageVersion("DBItest") < "1.7.1.9004") "column_info_consistent",                     # https://github.com/r-dbi/DBItest/issues/181

      NULL
    )

  if (packageVersion("DBItest") >= "1.6.0") {
    DBItest::make_context(
      SQLite(),
      list(dbname = tempfile("DBItest", fileext = ".sqlite")),
      tweaks = DBItest::tweaks(
        dbitest_version = "1.7.2",
        constructor_relax_args = TRUE,
        placeholder_pattern = c("?", "$1", "$name", ":name"),
        date_cast = function(x) paste0("'", x, "'"),
        time_cast = function(x) paste0("'", x, "'"),
        timestamp_cast = function(x) paste0("'", x, "'"),
        logical_return = function(x) as.integer(x),
        allow_na_rows_affected = TRUE,
        date_typed = FALSE,
        time_typed = FALSE,
        timestamp_typed = FALSE
      ),
      name = "RSQLite",
      default_skip = default_skip
    )
  } else {
    DBItest::make_context(
      SQLite(),
      list(dbname = tempfile("DBItest", fileext = ".sqlite")),
      tweaks = DBItest::tweaks(
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
  }
}
