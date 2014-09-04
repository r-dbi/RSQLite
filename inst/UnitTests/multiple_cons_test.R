library("RSQLite")

DATA <- new.env(parent=emptyenv(), hash=TRUE)

.setUp <- function() {
    DATA$dbfile <- tempfile()
    DATA$db1 <- dbConnect(SQLite(), dbname = DATA$dbfile)
    DATA$db2 <- dbConnect(SQLite(), dbname = DATA$dbfile)
    DATA$df <- data.frame(a=letters, b=LETTERS, c=1:26,
                          stringsAsFactors=FALSE)
    dbGetQuery(DATA$db1, "create table t1 (a text, b text, c integer)")
    rs <- dbSendPreparedQuery(DATA$db1,
                              "insert into t1 values (:a, :b, :c)",
                              DATA$df)
    dbClearResult(rs)
}

.tearDown <- function() {
    lapply(dbListResults(DATA$db1), dbClearResult)
    lapply(dbListResults(DATA$db2), dbClearResult)
    dbDisconnect(DATA$db1)
    dbDisconnect(DATA$db2)
    file.remove(DATA$dbfile)
}

testSimultaneousSelects <- function() {
    dbfile <- tempfile()
    db1 <- dbConnect(SQLite(), dbname = dbfile)
    df <- data.frame(a=letters, b=LETTERS, c=1:26,
                     stringsAsFactors=FALSE)
    dbGetQuery(db1, "create table t1 (a text, b text, c integer)")
    rs <- dbSendPreparedQuery(db1,
                              "insert into t1 values (:a, :b, :c)", df)
    dbClearResult(rs)
    dbListTables(db1)
    ## here we wait to open the 2nd con till after table created
    db2 <- dbConnect(SQLite(), dbfile)
    rs1 <- dbSendQuery(db1, "select * from t1")
    rs2 <- dbSendQuery(db2, "select a, c from t1")
    junk <- fetch(rs1, n=1)
    junk <- fetch(rs2, n=1)
    dbClearResult(rs1)
    dbClearResult(rs2)
    dbDisconnect(db1)
    dbDisconnect(db2)
}


testSimultaneousSelects2 <- function() {
    dbfile <- tempfile()
    db1 <- dbConnect(SQLite(), dbfile)
    db2 <- dbConnect(SQLite(), dbfile)
    df <- data.frame(a=letters, b=LETTERS, c=1:26,
                     stringsAsFactors=FALSE)
    dbGetQuery(db1, "create table t1 (a text, b text, c integer)")
    rs <- dbSendPreparedQuery(db1,
                              "insert into t1 values (:a, :b, :c)", df)
    dbClearResult(rs)

    ## TODO: investigate why this works on Unix and fails on Windows
    if (.Platform[["OS.type"]] == "windows") {
        cat("skipping test, simultaneous selects not working on Windows\n")
        return(TRUE)
    }
    rs1 <- dbSendQuery(db1, "select * from t1")
    rs2 <- dbSendQuery(db2, "select a, c from t1")
    junk <- fetch(rs1, n=1)
    junk <- fetch(rs2, n=1)
    dbClearResult(rs1)
    dbClearResult(rs2)
    dbDisconnect(db1)
    dbDisconnect(db2)
}

testTemporaryTables <- function() {
  dbGetQuery(DATA$db1, "create temporary table tabletemp (a text)")
  checkTrue("tabletemp" %in% dbListTables(DATA$db1))
  checkEquals("tabletemp" %in% dbListTables(DATA$db2), FALSE)
}
