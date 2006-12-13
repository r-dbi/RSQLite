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

