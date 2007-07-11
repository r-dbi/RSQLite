test_NULL_dbname <- function() {
    for (i in 1:20) {
        db <- dbConnect(SQLite(), dbname=NULL)
        checkTrue(dbDisconnect(db))
    }
}
