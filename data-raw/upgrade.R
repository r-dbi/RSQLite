library(magrittr)

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

# Regular expression source code
download.file(
  url = "https://sqlite.org/src/raw?filename=ext/misc/regexp.c&ci=trunk",
  destfile = "src/vendor/sqlite3/regexp.c",
  quiet = TRUE,
  mode = "w")

stopifnot(system2("patch", "-p1", stdin = "data-raw/regexp.patch") == 0)

branch <- paste0("f-", sub("[.][^.]*$", "", latest_name))
version <- sub("^.*-([0-9])([0-9][0-9])[0-9]+[.].*$", "\\1.\\2", latest_name)

if (any(grepl("^src/", gert::git_status()$file))) {
  old_branch <- gert::git_branch()

  gert::git_branch_create(branch)
  gert::git_add("src")

  title <- paste0("Upgrade bundled SQLite to ", version)

  gert::git_commit(title)
  gert::git_push()

  message("Opening PR")
  pr <- gh::gh(
    "/repos/r-dbi/RSQLite/pulls", head = branch, base = old_branch,
    title = title, body = ".",
    .method = "POST"
  )

  body <- paste0("NEWS entry:\n\n```\n- Upgrade bundled SQLite to version ", version, " (#", pr$number, ").\n```")

  gh::gh(
    paste0("/repos/r-dbi/RSQLite/pulls/", pr$number),
    body = body,
    .method = "PATCH"
  )
}
