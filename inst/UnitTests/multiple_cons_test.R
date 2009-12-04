library("RSQLite")

DATA <- new.env(parent=emptyenv(), hash=TRUE)

.setUp <- function() {
    DATA$dbfile <- tempfile()
    DATA$db1 <- dbConnect(dbDriver("SQLite"), dbname = DATA$dbfile)
    DATA$db2 <- dbConnect(dbDriver("SQLite"), dbname = DATA$dbfile)
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

testSchemaChangeDuringQuery <- function() {
    rs1 <- dbSendQuery(DATA$db1, "select * from t1")
    junk <- fetch(rs1, n=1)
    checkEquals("a", junk[["a"]])
    ## This should cause an error because the DB is locked
    ## by the active select.
    checkException(dbGetQuery(DATA$db2,
                              "create table t2 (x text, y integer)"),
                   silent=TRUE)
    dbClearResult(rs1)

    ## if we haven't started fetching, it is ok on unix,
    ## but not on Windows
    ## rs1 <- dbSendQuery(DATA$db1, "select * from t1")
    ## dbGetQuery(DATA$db2,
    ##            "create table t2 (x text, y integer)")
    ## junk <- fetch(rs1, n=2)
    ## checkEquals(c("a", "b"), junk[["a"]])
}

testSimultaneousSelects <- function() {
    dbfile <- tempfile()
    db1 <- dbConnect(dbDriver("SQLite"), dbfile)
    df <- data.frame(a=letters, b=LETTERS, c=1:26,
                     stringsAsFactors=FALSE)
    dbGetQuery(db1, "create table t1 (a text, b text, c integer)")
    rs <- dbSendPreparedQuery(db1,
                              "insert into t1 values (:a, :b, :c)", df)
    dbClearResult(rs)
    ## here we wait to open the 2nd con till after table created
    db2 <- dbConnect(dbDriver("SQLite"), dbfile)
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
    db1 <- dbConnect(dbDriver("SQLite"), dbfile)
    db2 <- dbConnect(dbDriver("SQLite"), dbfile)
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

testSchemaChangeDuringWriteTable <- function() {
    if (.Platform[["OS.type"]] == "windows") {
        cat("skipping test, schema change on write table on Windows\n")
        return(TRUE)
    }
    rs1 <- dbSendQuery(DATA$db1, "select * from t1")
    junk <- fetch(rs1, n=1)
    checkEquals("a", junk[["a"]])
    x <- data.frame(col1=1:10, col2=letters[1:10])
    ## This fails because the active select locks the DB
    checkEquals(FALSE,
                suppressWarnings(dbWriteTable(DATA$db2, "tablex", x)))
    dbClearResult(rs1)
    checkEquals(TRUE, dbWriteTable(DATA$db2, "tablex", x))
    checkTrue("tablex" %in% dbListTables(DATA$db2))

    dbGetQuery(DATA$db1, "create table foobar (a text)")
    dbWriteTable(DATA$db2, "tabley", x)
    checkTrue("tabley" %in% dbListTables(DATA$db2))
}
