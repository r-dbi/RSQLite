if (identical(Sys.getenv("NOT_CRAN"), "true")) {

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

  # meta
  "get_info_result",                            # rstats-db/DBI#55

  # transactions

  # compliance
  "compliance",                                 # skipping for now because of dbGetInfo()

  NULL
))

}
