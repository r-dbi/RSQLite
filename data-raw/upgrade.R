library(magrittr)

do_upgrade <- function() {

html <- xml2::read_html("https://www.sqlite.org/download.html")

latest_name <- html %>%
  rvest::html_nodes("a") %>%
  xml2::xml_find_all('//*[(@id = "a1")] | //*[(@id = "a2")]') %>%
  rvest::html_text() %>%
  grep("amalgamation", ., value = TRUE) %>%
  .[1]

old_branch <- gert::git_branch()
message("Old branch: ", old_branch)

stopifnot(NROW(gert::git_status()) == 0)

message("Branch name: ", branch)
tryCatch(
  gert::git_branch_checkout(branch),
  error = function(e) {
    message("Creating new branch ", branch)
    gert::git_branch_create(branch)
  }
)

withr::defer(gert::git_branch_checkout(old_branch))

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

# Regular expression source code
download.file(
  url = "https://sqlite.org/src/raw?filename=ext/misc/regexp.c&ci=trunk",
  destfile = "src/vendor/sqlite3/regexp.c",
  quiet = TRUE,
  mode = "w"
)

stopifnot(system2("patch", "-p1", stdin = "data-raw/regexp.patch") == 0)

gert::git_add("src")
if (NROW(gert::git_status(staged = TRUE)) == 0) {
  message("No changes detected")
} else {
  message("Changes detected")

  version <- sub("^.*-([0-9])([0-9][0-9])(?:0([0-9])|([1-9][0-9]))[0-9]+[.].*$", "\\1.\\2.\\3\\4", latest_name)

  title <- paste0("Upgrade bundled SQLite to ", version)
  message("Commit message: ", title)
  gert::git_commit(title)

  message("Pushing branch")
  gert::git_push()

  # PR will fail to open if an existing branch is pushed to,
  # this is a feature

  message("Opening PR")
  pr <- gh::gh(
    "/repos/r-dbi/RSQLite/pulls",
    head = branch, base = old_branch,
    title = title, body = ".",
    .method = "POST"
  )

  message("Tweaking PR body")
  body <- paste0("NEWS entry:\n\n```\n- Upgrade bundled SQLite to version ", version, " (#", pr$number, ").\n```")

  gh::gh(
    paste0("/repos/r-dbi/RSQLite/pulls/", pr$number),
    body = body,
    .method = "PATCH"
  )
}

}

do_upgrade()
