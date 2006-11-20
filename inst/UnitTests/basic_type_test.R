library("RSQLite")

DATA <- new.env(parent=emptyenv(), hash=TRUE)

.setUp <- function() {
    DATA$dbfile <- tempfile()
    DATA$db <- dbConnect(dbDriver("SQLite"), DATA$dbfile)
}

.tearDown <- function() {
    dbDisconnect(DATA$db)
    file.remove(DATA$dbfile)
}

testBasicTypeConversion <- function() {
    db <- DATA$db
    df <- data.frame(name=c("Alice", "Bob", "Carl", "Diane", NA),
                     fldInt=as.integer(c(as.integer(1:4), NA)),
                     fldDbl=as.double(c(1.1, 2.2, 3.3, 4.4, NA)),
                     stringsAsFactors=FALSE)

    ## Create table by hand
    schema = "create table t1 (name text, fldInt integer, fldDbl float)"
    dbGetQuery(db, schema)
    dbBeginTransaction(db)
    dbGetPreparedQuery(db, "insert into t1 values (?, ?, ?)", bind.data=df)
    dbCommit(db)
    expected_types <- c(name="character", fldInt="integer", fldDbl="double")
    gotdf <- dbGetQuery(db, "select * from t1")

    checkEquals(dim(df), dim(gotdf))
    checkEquals(expected_types, sapply(gotdf, typeof))
    checkTrue(all(is.na(gotdf[5, ])))
}

testWriteTableBasicTypeConversion <- function() {
    db <- DATA$db
    df <- data.frame(name=c("Alice", "Bob", "Carl", "Diane", NA),
                     fldInt=as.integer(c(as.integer(1:4), NA)),
                     fldDbl=as.double(c(1.1, 2.2, 3.3, 4.4, NA)),
                     stringsAsFactors=FALSE)

    dbWriteTable(db, "t1", df, row.names=FALSE)

    expected_types <- c(name="character", fldInt="integer", fldDbl="double")
    gotdf <- dbGetQuery(db, "select * from t1")

    checkEquals(dim(df), dim(gotdf))
    checkEquals(expected_types, sapply(gotdf, typeof))
    checkTrue(all(is.na(gotdf[5, ])))
}
