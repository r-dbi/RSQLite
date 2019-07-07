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
  default_skip = c(
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
  )
)
