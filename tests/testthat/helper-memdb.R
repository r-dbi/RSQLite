memory_db <- function() {
  DBI::dbConnect(SQLite(), ":memory:")
}
