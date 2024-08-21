library(magrittr)

#### get SQLite amalgamation ####

html <- xml2::read_html("https://www.sqlite.org/download.html")

latest_name <- html %>%
  rvest::html_nodes("a") %>%
  xml2::xml_find_all('//*[(@id = "a1")] | //*[(@id = "a2")]') %>%
  rvest::html_text() %>%
  grep("amalgamation", ., value = TRUE) %>%
  .[1]

tmp <- tempfile()

year <- as.integer(strftime(Sys.Date(), "%Y"))
latest <- paste0("https://sqlite.org/", year, "/", latest_name)

tryCatch(
  download.file(latest, tmp),
  warning = function(e) {
    if (grepl("404", conditionMessage(e))) {
      latest <- paste0("https://sqlite.org/", year - 1, "/", latest_name)
      download.file(latest, tmp)
    }
  }
)

unzip(tmp, exdir = "src/vendor/sqlite3", junkpaths = TRUE)
unlink("src/vendor/sqlite3/shell.c")


#### extensions from SQLite repository ####

file.rename("src/vendor/sqlite3/sqlite3ext.h", "src/vendor/extensions/sqlite3ext.h")

tmp_source_zip <- tempfile()
latest_code <- "https://www.sqlite.org/src/zip/sqlite.zip?r=release"
download.file(latest_code, tmp_source_zip)

tmp_source_dir <- tempdir()
unzip(tmp_source_zip, exdir = tmp_source_dir)

register_misc_extension <- function(name) {
  ext_dir <- "src/vendor/extensions/"
  if (!dir.exists(ext_dir))
    dir.create(ext_dir, recursive = TRUE)

  text <- readLines(paste0(tmp_source_dir, "/sqlite/ext/misc/", name, ".c"))
  text <- gsub(" +$", "", text)
  writeLines(text, paste0(ext_dir, name, ".c"))

  # TODO compile as shared library? see https://www.sqlite.org/loadext.html
  lines <- c(
    "#define SQLITE_CORE",
    "#include <R_ext/Visibility.h>",
    paste0("#define sqlite3_", name, "_init attribute_visible sqlite3_", name, "_init"),
    "",
    paste0('#include "vendor/extensions/', name, '.c"')
  )

  writeLines(lines, paste0("src/ext-", name, ".c"))
}

register_misc_extension("regexp")
register_misc_extension("series")
register_misc_extension("csv")
register_misc_extension("uuid")


#### extensions from other sources ####

## https://github.com/asg017/sqlite-lines/
if (TRUE) {
  #
  ghf <- httr::GET("https://api.github.com/repos/asg017/sqlite-lines/contents/?recursive=1")
  ghf <- jsonlite::fromJSON(httr::content(ghf, as = "text"))
  #
  # define sources and target folders
  files <- read.table(
    header = TRUE,
    text = paste(
      'source target',
      '/main/sqlite-lines.c src/vendor',
      '/main/sqlite-lines.h src/vendor',
      sep = "\n")
  )
  files$name <- sub("^.*/(.+?)$", "\\1", files[, "source"])
  #
  # clean
  for (i in seq_len(nrow(files))) {
    unlink(file.path(files[i, "target"], files[i, "name"]))
  }
  unlink("src/ext-lines.c")
  #
  # get
  for (i in seq_len(nrow(files))) {
    dir.create(
      file.path(files[i, "target"]),
      showWarnings = FALSE,
      recursive = TRUE)
    download.file(
      url = paste0("https://raw.githubusercontent.com/asg017/sqlite-lines", files[i, "source"]),
      destfile = file.path(files[i, "target"], files[i, "name"]),
      quiet = TRUE
    )
  }
  #
  # write include file
  cat(paste0(
    '#define SQLITE_CORE\n',
    '#include <R_ext/Visibility.h>\n',
    'char const SQLITE_LINES_VERSION[] = "',
    httr::content(httr::GET(ghf$download_url[ghf$name == "VERSION"])), '";\n',
    'char const SQLITE_LINES_DATE[] = "',
    Sys.Date(), '";\n',
    'char const SQLITE_LINES_SOURCE[] = "',
    ghf$sha[ghf$name == "VERSION"], '";\n',
    '#include "vendor/sqlite-lines.c"\n'
  ), file = "src/ext-lines.c"
  )
  #
  # tests are in
  # tests/testthat/test-lines.R
}


#### update repo ####

if (any(grepl("^src/", gert::git_status()$file))) {
  branch <- paste0("f-", sub("[.][^.]*$", "", latest_name))
  message("Changes detected, creating branch: ", branch)

  version <- sub("^.*-([0-9])([0-9][0-9])(?:0([0-9])|([1-9][0-9]))[0-9]+[.].*$",
                 "\\1.\\2.\\3\\4", latest_name)

  old_branch <- gert::git_branch()
  message("Old branch: ", old_branch)

  gert::git_branch_create(branch)
  gert::git_add("src")

  commit_msg <- paste0("Upgrade bundled SQLite to ", version)
  message("Commit message: ", commit_msg)
  gert::git_commit(commit_msg)

  title <- paste0("feat: ", commit_msg)

  # Force-pushing: this job is run daily, will give a daily notification
  # and still succeed
  message("Pushing branch")
  gert::git_push(force = TRUE)

  message("Checking if PR exists")
  existing_pr <- gh::gh(
    "/repos/r-dbi/RSQLite/pulls",
    head = paste0("r-dbi:", branch), base = old_branch,
    state = "open"
  )

  if (length(existing_pr) > 0) {
    message("Nudging")
    gh::gh(
      paste0("/repos/r-dbi/RSQLite/issues/", existing_pr[[1]]$number, "/comments"),
      body = "PR updated.",
      .method = "POST"
    )
  } else {
    message("Opening PR")
    pr <- gh::gh(
      "/repos/r-dbi/RSQLite/pulls",
      head = branch, base = old_branch,
      title = title, body = ".",
      .method = "POST"
    )

    message("Tweaking PR body")
    body <- paste0("NEWS entry will be picked up by fledge from the PR title.")

    gh::gh(
      paste0("/repos/r-dbi/RSQLite/pulls/", pr$number),
      body = body,
      .method = "PATCH"
    )

    message("Adding label")
    gh::gh(
      paste0("/repos/r-dbi/RSQLite/issues/", pr$number),
      labels = c("mergequeue", "mergequeue"),
      .method = "PATCH"
    )

    message("Bumping main branch to run CI/CD")
    gert::git_branch_checkout(old_branch)
    system2("git", c("commit", "-m", "'chore: Bump main branch for CI/CD'", "--allow-empty"))
    gert::git_push(force = FALSE)
  }
}
