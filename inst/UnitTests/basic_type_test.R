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

basicDf <- data.frame(name=c("Alice", "Bob", "Carl", "NA", NA),
                      fldInt=as.integer(c(as.integer(1:4), NA)),
                      fldDbl=as.double(c(1.1, 2.2, 3.3, 4.4, NA)),
                      stringsAsFactors=FALSE)


testBasicTypeConversion <- function() {
    db <- DATA$db
    schema = "create table t1 (name text, fldInt integer, fldDbl float)"
    dbGetQuery(db, schema)
    dbBeginTransaction(db)
    dbGetPreparedQuery(db, "insert into t1 values (?, ?, ?)", bind.data=basicDf)
    dbCommit(db)
    expected_types <- c(name="character", fldInt="integer", fldDbl="double")
    gotdf <- dbGetQuery(db, "select * from t1")

    checkEquals(dim(basicDf), dim(gotdf))
    checkEquals(expected_types, sapply(gotdf, typeof))
    expect_na <- c(rep(FALSE, 4), TRUE)
    for (j in ncol(gotdf)) {
        checkEquals(expect_na, is.na(gotdf[, j]))
    }
}

testNAInFirstRow <- function() {
    db <- DATA$db
    basicDf <- data.frame(name=c(NA, "Alice", "Bob", "Cody", NA),
                          id=as.integer(c(NA, 10:12, NA)),
                          rate=c(NA, 1:3 * pi, NA), stringsAsFactors=FALSE)
    basicTableSql <- ('create table t1 (name text, id integer, rate real)')
    values <- c("(:name, :id, :rate)")
    dbGetQuery(db, basicTableSql)
    sql <- paste("insert into t1 values", values)
    tryCatch({
        dbBeginTransaction(db)
        rs <- dbSendPreparedQuery(db, sql, bind.data=basicDf)
        dbClearResult(rs)
    }, error=function(e) {
        dbRollBack(db)
        signalCondition(e)
    })
    dbCommit(db)
    got <- dbGetQuery(db, "select * from t1")
    checkEquals(basicDf, got)
}

testUnitFetch <- function() {
    db <- DATA$db
    ## Create table by hand
    schema = "create table t1 (name text, fldInt integer, fldDbl float)"
    dbGetQuery(db, schema)
    dbBeginTransaction(db)
    dbGetPreparedQuery(db, "insert into t1 values (?, ?, ?)", bind.data=basicDf)
    dbCommit(db)
    expected_types <- c(name="character", fldInt="integer", fldDbl="double")
    rs <- dbSendQuery(db, "select * from t1")
    on.exit(dbClearResult(rs))
    for (i in seq_len(nrow(basicDf))) {
        gotdf <- fetch(rs, n=1)
        checkEquals(1:1, nrow(gotdf))
        checkEquals(ncol(basicDf), ncol(gotdf))
        checkEquals(expected_types, sapply(gotdf, typeof))
        checkEquals(basicDf[i, ], gotdf)
    }
    ## In this case, you can't know there are no more records:
    checkTrue(!dbHasCompleted(rs))
    checkEquals(0, nrow(fetch(rs, n=1)))
    checkTrue(dbHasCompleted(rs))
}

testFetchByTwo <- function() {
    db <- DATA$db
    ## Create table by hand
    schema = "create table t1 (name text, fldInt integer, fldDbl float)"
    dbGetQuery(db, schema)
    dbBeginTransaction(db)
    dbGetPreparedQuery(db, "insert into t1 values (?, ?, ?)", bind.data=basicDf)
    dbCommit(db)
    expected_types <- c(name="character", fldInt="integer", fldDbl="double")
    rs <- dbSendQuery(db, "select * from t1")
    on.exit(dbClearResult(rs))
    N <- nrow(basicDf)
    if (N %% 2 != 0)
      N <- N + 1
    N <- N / 2
    for (i in seq(1, N)) {
        gotdf <- fetch(rs, n=2)
        checkEquals(ncol(basicDf), ncol(gotdf))
        checkEquals(expected_types, sapply(gotdf, typeof))
        if (i < 3) {
            checkEquals(2, nrow(gotdf))
        }
    }
    checkTrue(dbHasCompleted(rs))
}


testWriteTableBasicTypeConversion <- function() {
    db <- DATA$db
    dbWriteTable(db, "t1", basicDf, row.names=FALSE)

    expected_types <- c(name="character", fldInt="integer", fldDbl="double")
    gotdf <- dbGetQuery(db, "select * from t1")

    checkEquals(dim(basicDf), dim(gotdf))
    checkEquals(expected_types, sapply(gotdf, typeof))
    checkTrue(all(is.na(gotdf[5, ])))
}

testFirstResultRowIsNull <- function() {
    db <- DATA$db
    data(USArrests)
    dbWriteTable(db, "t1", USArrests)
    a1 <- dbGetQuery(db, "select Murder/(Murder - 8.1) from t1 limit 10")
    checkEquals("double", typeof(a1[[1]]))
    ## This isn't ideal, but for now, if the first row of a result set
    ## contains a NULL, then that column is forced to be character.
    a2 <- dbGetQuery(db,
                     "select Murder/(Murder - 8.1) from t1 limit 10 offset 2")
    checkEquals("character", typeof(a2[[1]]))
}

test_no_rows_preserves_column_count <- function()
{
    db <- DATA$db
    want_dim <- c(1L, 2L)
    ans <- dbGetQuery(db, "select 1 as a, 2 as b where 1")
    checkEquals(want_dim, dim(ans))

    want_dim <- c(0L, 2L)
    ans <- dbGetQuery(db, "select 1 as a, 2 as b where 0")
    checkEquals(want_dim, dim(ans))
}
