default_skip <-
  c(
    # enable to test a particular test only
    #"(?!data_timestamp_current).*",

    # sql
    "roundtrip_date",                             # #109
    "roundtrip_timestamp",                        # #110

    "column_info_consistent",                     # #259

    NULL
  )

if (packageVersion("DBItest") >= "1.6.0") {
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
