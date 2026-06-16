# See tests/testthat/helper-aspell.R for the logic that creates the .rds file
# (mentioned in the `dictionaries` argument) from the corresponding .txt file.
Rd_files <- vignettes <- R_files <- description <-
    list(encoding = "UTF-8",
         language = "en",
         dictionaries = c("en_stats", "DBI"))
