test_NULL_dbname <- function() {
    for (i in 1:20) {
        db <- dbConnect(SQLite(), dbname=NULL)
        checkTrue(dbDisconnect(db))
    }
}

test_invalid_dbname_is_caught <- function()
{
    drv <- SQLite()
    checkException(dbConnect(drv, dbname = 1:3))
    checkException(dbConnect(drv, dbname = c("a", "b")))
    checkException(dbConnect(drv, dbname = NA))
    checkException(dbConnect(drv, dbname = as.character(NA)))
}

