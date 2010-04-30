test_connections_are_finalized <- function()
{
    drv <- SQLite()
    dbs <- lapply(1:50, function(x) {
        dbConnect(drv, dbname = ":memory:")
    })
    checkEquals(50L, dbGetInfo(SQLite())$num_con)
    rm(dbs)
    gc(verbose = FALSE)
    checkEquals(0L, dbGetInfo(SQLite())$num_con)
}

test_connections_are_held_by_result_set <- function()
{
    db <- dbConnect(SQLite(), dbname = ":memory:")
    res <- dbSendQuery(db, "create table t1 (a text, b text)")
    rm(db)
    gc(verbose = FALSE)
    checkEquals(1L, dbGetInfo(SQLite())$num_con)
    dbClearResult(res)
    ## clearing a result set means that result set no loner
    ## protects the connection
    gc(verbose = FALSE)
    checkEquals(0L, dbGetInfo(SQLite())$num_con)
}
