# The DBItest contexts for the data frame path through Arrow, and the groups
# that exercise it: the driver group checks `bigint` with dbGetQuery(), the
# transaction group writes and reads tables inside transactions, and the
# getting started, connection, compliance and stress groups never fetch or
# write a data frame

arrow_dbitest_context <- function(name, ...) {
  DBItest::make_context(
    RSQLite::SQLite(),
    list(dbname = tempfile(name, fileext = ".sqlite"), arrow = TRUE, ...),
    set_as_default = FALSE,
    tweaks = DBItest::tweaks(
      dbitest_version = "1.8.3.6",
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
    name = name
  )
}

test_arrow_dbitest <- function(ctx) {
  skip <- c(
    if (getRversion() < "4.0") "stream_bind_too_many",
    # See helper-DBItest.R
    ARROW_ROUNDTRIP_SKIPS
  )
  DBItest::test_driver(skip = skip, ctx = ctx)
  DBItest::test_result(skip = skip, ctx = ctx)
  DBItest::test_sql(skip = skip, ctx = ctx)
  DBItest::test_meta(skip = skip, ctx = ctx)
  DBItest::test_transaction(skip = skip, ctx = ctx)
  DBItest::test_arrow(skip = skip, ctx = ctx)
}
