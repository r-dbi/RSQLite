test_dbGetInfo_connection <- function()
{
    db <- dbConnect(SQLite(), dbname = ":memory:")
    on.exit(dbDisconnect(db))

    info <- dbGetInfo(db)
    checkEquals(6L, length(info))
    checkEquals(":memory:", info[["dbname"]])
    checkEquals("3.7.17", info[["serverVersion"]])
    checkEquals(integer(0), info[["rsId"]])
    checkEquals("on", info[["loadableExtensions"]])
    checkEquals(SQLITE_RWC, info[["flags"]])
    checkEquals("", info[["vfs"]])
}

test_dbGetInfo_connection_vfs <- function()
{
    if (.Platform[["OS.type"]] == "windows") {
        cat("Skipping test: vfs customization not available on Windows\n")
        return(TRUE)
    }
    db <- dbConnect(SQLite(), dbname = "", vfs = "unix-none")
    on.exit(dbDisconnect(db))
    info <- dbGetInfo(db)
    checkEquals("", info[["dbname"]])
    checkEquals("unix-none", info[["vfs"]])
}

test_dbGetInfo_extensions <- function()
{
    db <- dbConnect(SQLite(), dbname = "", loadable.extensions = FALSE)
    on.exit(dbDisconnect(db))
    info <- dbGetInfo(db)
    checkEquals("off", info[["loadableExtensions"]])
}
