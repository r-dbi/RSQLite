library("RSQLite")

testCanCloseAfterFailedWriteTable <- function() {
    tf <- tempfile()
    con <- dbConnect(dbDriver("SQLite"), dbname=tf)

    x <- data.frame(col1=1:10, col2=letters[1:10])

    dbWriteTable(con, "t1", x)
    dbGetQuery(con, "create unique index t1_c1_c2_idx on t1(col1, col2)")

    ## uniqueness constraint error/failure
    checkEquals(FALSE, dbWriteTable(con,"t1", x, append=T))

    ## this used to cause an error
    dbDisconnect(con)
    file.remove(tf)
}
