require("RSQLite") || stop("unable to load RSQLite")

DATA <- new.env(parent=emptyenv())

.setUp <- function() {
    DATA$db <- dbConnect(dbDriver("SQLite"), dbname=":memory:")
}

.tearDown <- function() {
    lapply(dbListResults(DATA$db), dbClearResult)
    dbDisconnect(DATA$db)
}

testBadFilenameArg <- function()
{
    tmpfiles <- tempfile(letters[1:3])
    badFilenameArgs <- list(
                            1:5,
                            character(0),
                            as.character(NA),
                            "",
                            tmpfiles)
    for (badFile in badFilenameArgs) {
        checkException(sqliteCopyDatabase(DATA$db, badFile))
    }
    for (f in tmpfiles) checkTrue(!file.exists(f))
}

test_backup_to_file <- function()
{
    backup <- tempfile()
    checkTrue(!file.exists(backup))
    df <- data.frame(foo=1:5, bar=letters[1:5], stringsAsFactors = FALSE)
    checkTrue(dbWriteTable(DATA$db, "t1", df, row.names = FALSE))
    sqliteCopyDatabase(DATA$db, backup)
    checkTrue(file.exists(backup))
    db2 <- dbConnect(SQLite(), dbname = backup)
    on.exit(dbDisconnect(db2))
    on.exit(unlink(backup), add = TRUE)
    backupDf <- dbReadTable(db2, "t1")
    checkEquals(df, backupDf)
}

test_backup_to_connection <- function()
{
    df <- data.frame(foo=1:5, bar=letters[1:5], stringsAsFactors = FALSE)
    checkTrue(dbWriteTable(DATA$db, "t1", df, row.names = FALSE))

    db2 <- dbConnect(SQLite(), dbname = ":memory:")
    on.exit(dbDisconnect(db2))

    sqliteCopyDatabase(DATA$db, db2)
    got <- dbReadTable(db2, "t1")
    checkEquals(df, got)
}
