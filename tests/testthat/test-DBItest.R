DBItest::make_context(SQLite(), NULL)
DBItest::test_all(c(
  # getting_started
  "package_dependencies",  # #102

  # driver
  "constructor_strict",    # relaxed constructor check still active
  "get_info_driver",       # #117

  # connection
  "get_info_connection",   # #117

  # result
  "stale_result_warning",  # #120
  "data_logical",          # not an error, no logical data type
  "data_logical_null_.*",     # not an error, no logical data type
  "data_64_bit",           # #65
  "data_64_bit_null_.*",      # #65
  "data_raw_null_.*",         # #115
  "data_date",             # #103
  "data_date_null_.*",        # #111
  "data_time",             # syntax not supported
  "data_time_null_.*",        # syntax not supported
  "data_timestamp",        # syntax not supported
  "data_timestamp_null_.*",   # syntax not supported
  "data_timestamp_utc",    # syntax not supported
  "data_timestamp_utc_null_.*", # syntax not supported
  "data_timestamp_parens", # #104
  "data_timestamp_parens_null_.*", # 111

  # sql
  "append_table_error",    # #112
  "temporary_table",       # #113
  "quote_identifier_not_vectorized", # rstats-db/DBI#24
  "roundtrip_keywords",    # #106
  "roundtrip_quotes",      # #107
  "roundtrip_logical",     # not an error, no logical data type
  "roundtrip_64_bit",      # not an error, loose typing
  "roundtrip_raw",         # #116
  "roundtrip_date",        # #109
  "roundtrip_timestamp",   # #110

  # result_meta
  "bind_logical_.*", # not an error, no logical data type
  "bind_date_.*",  # #114
  "bind_timestamp_.*", # #114
  NULL
))
