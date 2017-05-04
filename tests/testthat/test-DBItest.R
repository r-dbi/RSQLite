DBItest::test_all(c(
  # enable to test a particular test only
  #"(?!data_timestamp_current).*",

  # driver
  "get_info_driver",                            # #117

  # connection
  "get_info_connection",                        # #117

  # sql
  "roundtrip_date",                             # #109
  "roundtrip_timestamp",                        # #110
  "read_table_error",                           #
  "write_table_error",                          #
  "exists_table_error",                         #
  "exists_table_name",                          #

  # meta
  "get_statement_error",                        #
  "get_info_result",                            # rstats-db/DBI#55

  # transactions
  "begin_write_disconnect",                     #

  # compliance
  "compliance",                                 # skipping for now because of dbGetInfo()

  NULL
))
