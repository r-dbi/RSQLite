DBItest::test_all(c(
  # enable to test a particular test only
  #"(?!data_timestamp_current).*$",

  # driver
  "constructor_strict",                         # relaxed constructor check still active
  "get_info_driver",                            # #117

  # connection
  "get_info_connection",                        # #117
  "cannot_disconnect_twice",                    # TODO
  "cannot_forget_disconnect",

  # result
  "fetch_no_return_value",                      # need to warn when fetching statement
  "fetch_n_bad",                                # n argument to dbFetch()
  "fetch_n_good_after_bad",                     # n argument to dbFetch()
  "fetch_n_more_rows",                          #
  "cannot_clear_result_twice_.*",               # error: need to warn if closing result twice
  "get_query_n_.*",                             # rstats-db/DBI#76
  "data_raw",                                   #
  "data_logical",                               # not an error, no logical data type
  "data_logical_null_.*",                       # not an error, no logical data type
  "bind_blob",

  # sql
  "append_table_error",                         # #112
  "roundtrip_date",                             # #109
  "roundtrip_timestamp",                        # #110
  "read_table_error",                           #
  "write_table_error",                          #
  "exists_table_error",                         #
  "exists_table_name",                          #

  # meta
  "get_statement_error",                        #
  "get_info_result",                            # rstats-db/DBI#55
  "read_only",                                  # default connection is read-write

  # transactions
  "begin_write_disconnect",                     #

  # compliance
  "compliance",                                 # skipping for now because of dbGetInfo()

  NULL
))
