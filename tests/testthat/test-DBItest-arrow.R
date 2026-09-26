# The DBI conformance suite, with data frames travelling through Arrow

skip_on_cran()
skip_if_not_installed("DBItest")

ctx <- DBItest::make_context(
  RSQLite::SQLite(),
  list(dbname = tempfile("DBItest-arrow", fileext = ".sqlite"), arrow = TRUE),
  set_as_default = FALSE,
  tweaks = DBItest::tweaks(
    dbitest_version = "1.8.1",
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
  name = "RSQLite (arrow)"
)

DBItest::test_all(
  skip = c(
    if (getRversion() < "4.0") "stream_bind_too_many",
    ARROW_ROUNDTRIP_SKIPS
  ),
  ctx = ctx
)
