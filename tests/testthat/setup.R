options(package_name = "RSQLite")

withr::defer(options(package_name = NULL), teardown_env())
