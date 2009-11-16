test_dbGetInfo_connection <- function()
{
    db <- dbConnect(SQLite(), dbname = ":memory:")
    on.exit(dbDisconnect(db))

    info <- dbGetInfo(db)
    checkEquals(5, length(info))
    checkEquals(":memory:", info[["dbname"]])
    checkEquals("3.6.19", info[["serverVersion"]])
    checkEquals(integer(0), info[["rsId"]])
    checkEquals("off", info[["loadableExtensions"]])
    checkEquals("", info[["vfs"]])
}

test_dbGetInfo_connection_vfs <- function()
{
    db <- dbConnect(SQLite(), dbname = "", vfs = "unix-none")
    on.exit(dbDisconnect(db))
    info <- dbGetInfo(db)
    checkEquals("", info[["dbname"]])
    checkEquals("unix-none", info[["vfs"]])
}

test_dbGetInfo_extensions <- function()
{
    db <- dbConnect(SQLite(), dbname = "", loadable.extensions = TRUE)
    on.exit(dbDisconnect(db))
    info <- dbGetInfo(db)
    checkEquals("on", info[["loadableExtensions"]])
}
