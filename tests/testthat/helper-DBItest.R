# Also copied into DBI
tryCatch(skip = function(e) message(conditionMessage(e)), {
  skip_on_cran()
  skip_if_not_installed("DBItest")

  DBItest::make_context(
    RSQLite::SQLite(),
    list(dbname = tempfile("DBItest", fileext = ".sqlite")),
    tweaks = DBItest::tweaks(
      dbitest_version = "1.7.2",
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
