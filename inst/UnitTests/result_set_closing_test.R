library("RSQLite")

DATA <- new.env(parent=emptyenv(), hash=TRUE)

.setUp <- function() {
    DATA$p1 <- tempfile()
    DATA$p2 <- tempfile()
    db1 <- dbConnect(SQLite(), DATA$p1)
    data(USArrests)
    dbWriteTable(db1, "ua", USArrests, row.names=FALSE)
    dbDisconnect(db1)
}

.tearDown <- function() {
    file.remove(c(DATA$p1, DATA$p2))
}

test_dbGetQuery_auto_close <- function() {
    db <- dbConnect(SQLite(), DATA$p2)
    res <- dbSendQuery(db, "CREATE TABLE t1 (b integer, bb text)")

    checkEquals(TRUE, dbHasCompleted(res))

    sql <- sprintf("ATTACH '%s' AS db1", DATA$p1)
    checkEquals(NULL, dbGetQuery(db, sql))
    df <- dbGetQuery(db, "select * from db1.ua limit 3")
    checkEquals(3, nrow(df))
    dbDisconnect(db)
}

test_dbGetQuery_warn_on_new_connection <- function() {
    db <- dbConnect(SQLite(), DATA$p2)
    res <- dbSendQuery(db, "CREATE TABLE t1 (b integer, bb text)")
    dbClearResult(res)
    res <- dbSendQuery(db, "SELECT * from t1")
    checkEquals(FALSE, dbHasCompleted(res))
    ans <- tryCatch({
        dbGetQuery(db, "CREATE TABLE t2 (foo text)")
        FALSE
        }, warning=function(w) {
                 TRUE
             })
    checkEquals(TRUE, ans)
    dbClearResult(res)
    dbDisconnect(db)
}
