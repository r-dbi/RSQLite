library("RSQLite")

DATA <- new.env(parent=emptyenv(), hash=TRUE)

.setUp <- function() {
    DATA$dbfile <- tempfile()
    DATA$db <- dbConnect(dbDriver("SQLite"), DATA$dbfile)
}

.tearDown <- function() {
    lapply(dbListResults(DATA$db), dbClearResult)
    dbDisconnect(DATA$db)
    file.remove(DATA$dbfile)
}

basicTableSql <- ('
create table t1 (name text, id integer, rate real)
')

basicDf <- data.frame(name=c("Alice", "Bob", "Cody", NA),
                      id=as.integer(c(10:12, NA)),
                      rate=c(1:3 * pi, NA), stringsAsFactors=FALSE)

testSimpleBindPositional <- function() {
    db <- DATA$db
    dbGetQuery(db, basicTableSql)
    values <- "(?, ?, ?)"
    sql <- paste("insert into t1 values", values)
    dbBeginTransaction(db)
    rs <- dbSendPreparedQuery(db, sql, bind.data=basicDf)
    dbClearResult(rs)
    dbCommit(db)

    got <- dbGetQuery(db, "select * from t1")
    checkEquals(basicDf, got)
}

testSimpleBindNamed <- function() {
    db <- DATA$db
    dbGetQuery(db, basicTableSql)
    values <- "(:name, :id, :rate)"
    sql <- paste("insert into t1 values", values)
    rs <- dbSendPreparedQuery(db, sql, bind.data=basicDf)
    dbClearResult(rs)
    got <- dbGetQuery(db, "select * from t1")
    checkEquals(basicDf, got)
}

testBindNamedMissing <- function() {
    db <- DATA$db
    dbGetQuery(db, basicTableSql)
    values <- "(:name, :id, :rate)"
    sql <- paste("insert into t1 values", values)
    colnames(basicDf)[2] <- "garbled"
    Got <- tryCatch({
        dbSendPreparedQuery(db, sql, bind.data=basicDf)
        FALSE
    },
             error = function(e) {
                 checkTrue(grepl("unable to bind data for parameter",
                                 conditionMessage(e)))
                 TRUE
             })
    checkTrue(Got)                      # verify exception
}

testBindNamedReordered <- function() {
    db <- DATA$db
    dbGetQuery(db, basicTableSql)
    values <- "(:name, :id, :rate)"
    sql <- paste("insert into t1 values", values)
    newOrd <- c("id", "rate", "name")
    basicDf <- basicDf[ , newOrd]
    rs <- dbSendPreparedQuery(db, sql, bind.data=basicDf)
    dbClearResult(rs)
    got <- dbGetQuery(db, "select * from t1")
    checkEquals(basicDf, got[ , newOrd])
}

testBindNamedReorderExtraCols <- function() {
    db <- DATA$db
    dbGetQuery(db, basicTableSql)
    values <- "(:name, :id, :rate)"
    sql <- paste("insert into t1 values", values)
    basicDf$foo <- 1:1
    basicDf$bar <- 0:0
    basicDf$baz <- "a"
    newOrd <- c("foo", "id", "bar", "rate", "name", "baz")
    basicDf <- basicDf[ , newOrd]

    ## This raises the following error:
##     Error in sqliteExecStatement(conn, statement, bind.data, ...) :
## 	RS-DBI driver: (attempted to re-bind column [name] to positional
## 	parameter 1)

    rs <- dbSendPreparedQuery(db, sql, bind.data=basicDf)
    dbClearResult(rs)

    got <- dbGetQuery(db, "select * from t1")
    checkEquals(basicDf[ , c("name", "id", "rate")], got)
}

test_bind_data_has_zero_dim <- function()
{
    db <- DATA$db
    dbGetQuery(db, basicTableSql)
    values <- "(:name, :id, :rate)"
    sql <- paste("insert into t1 values", values)
    df <- basicDf[0, ]
    checkException(dbSendPreparedQuery(db, sql, bind.data = df))
}

bind_select_setup <- function(db) {
    df <- data.frame(id = letters[1:5],
                     score = 1:5,
                     size = c(1L, 1L, 2L, 2L, 3L),
                     stringsAsFactors = FALSE)

    dbWriteTable(db, "t1", df, row.names = FALSE)
    df
}

test_bind_select_one_per <- function()
{
    db <- DATA$db
    df <- bind_select_setup(db)
    q <- "select * from t1 where id = ?"
    got <- dbGetPreparedQuery(db, q, data.frame(id = c("e", "a", "c")))
    checkEquals(c("e", "a", "c"), got$id)
    checkEquals(c(5L, 1L, 3L), got$score)

    res <- dbSendPreparedQuery(db, q, data.frame(id = c("e", "a", "c")))
    checkEquals("e", fetch(res, n = 1)[["id"]])
    checkEquals("a", fetch(res, n = 1)[["id"]])
    checkEquals("c", fetch(res, n = 1)[["id"]])
    checkEquals(0L, nrow(fetch(res, n = 1)))
    checkTrue(dbGetInfo(res)$completed == 1L)
    dbClearResult(res)
}

test_bind_select_no_matches <- function()
{
    db <- DATA$db
    df <- bind_select_setup(db)
    q <- "select * from t1 where id = ?"

    ## no result 1
    got <- dbGetPreparedQuery(db, q, data.frame(id = "X"))
    checkEquals(c(0L, 3L), dim(got))
    checkEquals(names(df), names(got))

    ## no result many
    got <- dbGetPreparedQuery(db, q, data.frame(id = c("X", "Y", "Z")))
    checkEquals(c(0L, 3L), dim(got))
    checkEquals(names(df), names(got))

    # no results when mixed in
    got <- dbGetPreparedQuery(db, q,
                              data.frame(id = c("X", "b", "e", "Y", "a")))
    checkEquals(c("b", "e", "a"), got$id)
}

test_bind_select_multi_match <- function()
{
    db <- DATA$db
    df <- bind_select_setup(db)
    q <- "select * from t1 where size = ?"

    got <- dbGetPreparedQuery(db, q,
                              data.frame(size=c(1L, 2L, 3L)))
    checkEquals(df, got)

    ## with non-match
    got <- dbGetPreparedQuery(db, q,
                              data.frame(size=c(1L, -100L, 2L, 3L)))
    checkEquals(df, got)

    ## as result set using incremental fetch
    res <- dbSendPreparedQuery(db, q,
                               data.frame(size=c(3L, 2L)))
    checkEquals("e", fetch(res, n = 1L)[["id"]])
    checkEquals("c", fetch(res, n = 1L)[["id"]])
    checkEquals("d", fetch(res, n = 1L)[["id"]])
    checkEquals(c(0L, 3L), dim(fetch(res, n = 1L)))
    checkTrue(dbGetInfo(res)$completed == 1L)
}

test_bind_select_NA <- function()
{
    db <- DATA$db
    df <- bind_select_setup(db)
    dbGetQuery(db, "insert into t1 values ('x', NULL, NULL)")

    got <- dbGetPreparedQuery(db, "select id from t1 where score is :v",
                              data.frame(v=as.integer(NA)))
    checkEquals(c(1L, 1L), dim(got))
    checkEquals("x", got$id)
}
