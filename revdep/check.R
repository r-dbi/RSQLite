library("devtools")

revdep_check(threads = parallel::detectCores(), bioconductor = TRUE)
revdep_check_save_summary()
