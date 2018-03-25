get_stage("after_success") %>%
  add_step(step_run_code(
    covr::codecov(
      exclusions = c(
        "src/vendor/sqlite3/sqlite3.c",
        "src/vendor/sqlite3/extension-functions.c"
      )
    )
  ))

if (Sys.getenv("id_rsa") != "" && Sys.getenv("BUILD_PKGDOWN") != "") {
  get_stage("before_deploy") %>%
    add_step(step_install_ssh_keys()) %>%
    add_step(step_test_ssh())

  get_stage("deploy") %>%
    add_step(step_build_pkgdown()) %>%
    add_step(step_push_deploy())
}
