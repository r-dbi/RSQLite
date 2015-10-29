DBItest::make_context(SQLite(), NULL)
DBItest::test_all(c(
  "package_dependencies",  # #102
  "constructor_strict",    # relaxed constructor check still active
  "show",                  # rstats-db/RPostgres#49
  "get_info",              # to be discussed
  "data_logical",          # not an error, no logical data type
  "data_64_bit",           # rstats-db/RPostgres#51
  "data_date",             # #103
  "data_time",             # syntax not supported
  "data_timestamp",        # syntax not supported
  "data_timestamp_utc",    # syntax not supported
  "data_timestamp_parens", # #104
  "roundtrip_keywords",    # #106
  "roundtrip_quotes",      # #107
  NULL
))
