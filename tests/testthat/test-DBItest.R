if (identical(Sys.getenv("NOT_CRAN"), "true")) {

  if (packageVersion("DBItest") >= "1.6.0") {
    DBItest::test_all()
  } else {
    DBItest::test_all(skip = c(default_skip, "roundtrip_raw", "roundtrip_blob"))
  }

}
