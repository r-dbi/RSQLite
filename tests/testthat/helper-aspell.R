local(
  if (all(dir.exists(file.path("../..", c("R", "man", "tests"))))) {
    withr::local_dir("../..")
    rds_files <- list.files(".aspell", pattern = "\\.rds$", full.names = TRUE)
    stopifnot(length(rds_files) == 1)
    txt_files <- list.files(".aspell", pattern = "\\.txt$", full.names = TRUE)
    if (length(txt_files) == 0) {
      rds <- readRDS(rds_files)
      writeLines(rds, gsub("\\.rds$", ".txt", rds_files))
      message(
        "Created ",
        gsub("\\.rds$", ".txt", rds_files),
        " from ",
        rds_files
      )
    } else {
      stopifnot(length(txt_files) == 1)

      info <- file.info(c(rds_files, txt_files))
      txt_newer <- diff(info$mtime) > 0
      if (txt_newer) {
        txt <- readLines(txt_files)
        saveRDS(txt, rds_files, version = 2)
        message("Updated ", rds_files, " from ", txt_files)
      }
    }
  }
)
