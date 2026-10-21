# The DBI conformance suite, with data frames travelling through Arrow:
# the groups that fetch or write data frames

skip_on_cran()
skip_if_not_installed("DBItest")

test_arrow_dbitest(arrow_dbitest_context("RSQLite (arrow)"))
