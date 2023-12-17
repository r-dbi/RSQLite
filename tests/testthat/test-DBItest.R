# Also copied into DBI
skip_on_cran()
skip_if_not_installed("DBItest")

DBItest::test_all()
