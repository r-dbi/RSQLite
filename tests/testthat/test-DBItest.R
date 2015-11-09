DBItest::make_context(SQLite(), NULL)
DBItest::test_all(c(
  "package_dependencies",  # #102
  "constructor_strict",    # relaxed constructor check still active
  "show",                  # rstats-db/RPostgres#49
  "get_info",              # to be discussed
  "data_integer_null",     # not an error, no logical data type
  "data_logical",          # not an error, no logical data type
  "data_64_bit",           # rstats-db/RPostgres#51
  "data_64_bit_null",      # rstats-db/RPostgres#51
  "data_date",             # #103
  "data_date_null",        # #111
  "data_time",             # syntax not supported
  "data_time_null",        # syntax not supported
  "data_timestamp",        # syntax not supported
  "data_timestamp_null",   # syntax not supported
  "data_timestamp_utc",    # syntax not supported
  "data_timestamp_utc_null", # syntax not supported
  "data_timestamp_parens", # #104
  "data_timestamp_parens_null", # 111
  "append_table_error",    # #112
  "temporary_table",       # #113
  "roundtrip_keywords",    # #106
  "roundtrip_quotes",      # #107
  "roundtrip_logical",     # not an error, no logical data type
  "roundtrip_64_bit",      # not an error, loose typing
  "roundtrip_date",        # #109
  "roundtrip_timestamp",   # #110
  "bind_logical_positional", # not an error, no logical data type
  "bind_logical_named_colon", # not an error, no logical data type
  "bind_logical_named_dollar", # not an error, no logical data type
  "bind_date_positional",  # #114
  "bind_timestamp_positional", # #114
  "bind_date_named_colon", # #114
  "bind_timestamp_named_colon", # #114
  "bind_date_named_dollar", # #114
  "bind_timestamp_named_dollar", # #114
  NULL
))
