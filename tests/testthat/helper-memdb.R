memory_db <- function() {
  dbConnect(SQLite(), ":memory:")
}
