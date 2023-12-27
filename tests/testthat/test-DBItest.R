# Also copied into DBI
skip_on_cran()
skip_if_not_installed("DBItest")

DBItest::test_all(
  skip = c(
    if (getRversion() < "4.0") "stream_bind_too_many"
  )
)
