library(magrittr)

html <- xml2::read_html("https://www.sqlite.org/download.html")

latest_name <- html %>%
  rvest::html_nodes("a") %>%
  xml2::xml_find_all('//*[(@id = "a1")] | //*[(@id = "a2")]') %>%
  rvest::html_text() %>%
  grep("amalgamation", ., value = TRUE) %>%
  .[1]

latest <- paste0("https://sqlite.org/", Sys.Date() %>% strftime("%Y"), "/", latest_name)
tmp <- tempfile()
download.file(latest, tmp)
unzip(tmp, exdir = "src/vendor/sqlite3", junkpaths = TRUE)
unlink("src/vendor/sqlite3/shell.c")

# Regular expression source code
download.file(
  url = "https://sqlite.org/src/raw?filename=ext/misc/regexp.c&ci=trunk",
  destfile = "src/vendor/sqlite3/regexp.c",
  quiet = TRUE,
  mode = "w")

stopifnot(system2("patch", "-p1", stdin = "data-raw/regexp.patch") == 0)
