DBItest::test_all(c(
  # driver
  "constructor_strict",                         # relaxed constructor check still active
  "get_info_driver",                            # #117

  # connection
  "get_info_connection",                        # #117
  "cannot_disconnect_twice",                    # TODO

  # result
  "fetch_no_return_value",                      # need to warn when fetching statement
  "fetch_n_bad",                                # n argument to dbFetch()
  "fetch_n_good_after_bad",                     # n argument to dbFetch()
  "cannot_clear_result_twice_.*",               # error: need to warn if closing result twice
  "stale_result_warning",                       # #120
  "get_query_n_.*",                             # rstats-db/DBI#76
  "data_raw",                                   #
  "data_logical",                               # not an error, no logical data type
  "data_logical_null_.*",                       # not an error, no logical data type
  "data_64_bit_.*",                             # #65

  # sql
  "append_table_error",                         # #112
  "roundtrip_64_bit",                           # not an error, loose typing
  "roundtrip_raw",                              # #116
  "roundtrip_date",                             # #109
  "roundtrip_timestamp",                        # #110
  "read_table_error",                           #
  "write_table_error",                          #
  "exists_table_error",                         #
  "exists_table_name",                          #

  # meta
  "get_statement_error",                        #
  "get_info_result",                            # rstats-db/DBI#55
  "bind_empty",                                 #
  "bind_logical.*",                             # not an error, no logical data type
  "bind_date.*",                                # #114
  "bind_timestamp.*",                           # #114
  "read_only",                                  # default connection is read-write

  # compliance
  "compliance",                                 # skipping for now because of dbGetInfo()

  NULL
))

# Only read_only and interface compliance test run here
# (opt-in not yet implemented, rstats-db/DBItest#33)
DBItest::test_compliance(
  ctx = DBItest::make_context(
    SQLite(), list(flags = SQLITE_RO), set_as_default = FALSE, name = "RSQLite-RO"),
  skip = c(
    "compliance",                               # skipping for now because of dbGetInfo()
    "ellipsis"                                  # redundant
  )
)
