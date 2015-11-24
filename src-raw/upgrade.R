html <- xml2::read_html("https://www.sqlite.org/download.html")

latest_name <- html %>%
  rvest::html_nodes("a") %>%
  xml2::xml_find_all('//*[(@id = "a1")]') %>% 
  rvest::html_text

latest <- paste0("http://www.sqlite.org/2015/", latest_name)
tmp <- tempfile()
download.file(latest, tmp)
unzip(tmp, exdir = "src/", junkpaths = TRUE)
unlink("src/shell.c")
