# The DBI conformance suite, with data frames travelling through Arrow and
# character columns left as views into their arrays

skip_on_cran()
skip_if_not_installed("DBItest")

test_arrow_dbitest(arrow_dbitest_context("RSQLite (arrow, lazy strings)", lazy_strings = TRUE))
