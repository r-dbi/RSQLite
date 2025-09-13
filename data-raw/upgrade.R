library(magrittr)

html <- xml2::read_html("https://www.sqlite.org/download.html")

latest_name <- html %>%
  rvest::html_nodes("a") %>%
  xml2::xml_find_all('//*[(@id = "a1")] | //*[(@id = "a2")] | //*[(@id = "a3")] | //*[(@id = "a4")]') %>%
  rvest::html_text() %>%
  grep("amalgamation", ., value = TRUE) %>%
  .[1]

stopifnot(length(latest_name) == 1)

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
file.rename("src/vendor/sqlite3/sqlite3ext.h", "src/vendor/extensions/sqlite3ext.h")


# Regular expression source code
register_misc_extension <- function(name) {
  ext_dir <- "src/vendor/extensions/"
  if (!dir.exists(ext_dir))
    dir.create(ext_dir, recursive = TRUE)

  url <- paste0("https://github.com/sqlite/sqlite/raw/refs/heads/master/ext/misc/", name, ".c")
  data <- curl::curl_fetch_memory(url)

  text <- rawToChar(data$content)
  text <- gsub(" +($|\n)|\n$", "\\1", text)
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

for (f in dir("patch", full.names = TRUE)) {
  message("Applying ", f)
  stopifnot(system(paste0("patch -p1 -i ", f)) == 0)
}

version <- sub("^.*-([0-9])([0-9][0-9])(?:0([0-9])|([1-9][0-9]))[0-9]+[.].*$", "\\1.\\2.\\3\\4", latest_name)
descr <- desc::desc_get_field("Description", trim_ws = FALSE)
new_descr <- gsub("version [0-9]+\\.[0-9]+\\.[0-9]+", paste0("version ", version), descr)
desc::desc_set(Description = new_descr)

if (any(grepl("^src/|^DESCRIPTION", gert::git_status()$file))) {
  gert::git_add(c("src", "DESCRIPTION"))

  commit_msg <- paste0("feat: Upgrade bundled SQLite to ", version)
  message("Commit message: ", commit_msg)
  gert::git_commit(commit_msg)
}
