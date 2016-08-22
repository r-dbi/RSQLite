library("devtools")

revdep_check(threads = 3, bioconductor = TRUE)
revdep_check_save_summary()
