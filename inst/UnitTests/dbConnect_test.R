.getOS <- function()
{
    ostype <- .Platform[["OS.type"]]
    if (ostype == "windows") return("windows")
    if (grepl("darwin", R.Version()$os)) return("osx")
    ostype
}

test_NULL_dbname <- function() {
    for (i in 1:20) {
        db <- dbConnect(SQLite(), dbname=NULL)
        checkTrue(dbDisconnect(db))
    }
}

test_invalid_dbname_is_caught <- function()
{
    drv <- SQLite()
    checkException(dbConnect(drv, dbname = 1:3))
    checkException(dbConnect(drv, dbname = c("a", "b")))
    checkException(dbConnect(drv, dbname = NA))
    checkException(dbConnect(drv, dbname = as.character(NA)))
}

test_invalid_vfs_is_caught <- function()
{
    if (.getOS() == "windows") {
        cat("Skipping test: vfs customization not available on Windows\n")
        return(TRUE)
    }
    drv <- SQLite()
    checkException(dbConnect(drv, dbname = "", vfs = ""))
    checkException(dbConnect(drv, dbname = "", vfs = "notvfs"))
    checkException(dbConnect(drv, dbname = "", vfs = NA))
    checkException(dbConnect(drv, dbname = "", vfs = as.character(NA)))
    checkException(dbConnect(drv, dbname = "", vfs = 1L))
    checkException(dbConnect(drv, dbname = "",
                             vfs = c("unix-none", "unix-posix")))
}

test_valid_vfs <- function()
{
    allowed <- switch(.getOS(),
                      osx = c("unix-posix", "unix-afp", "unix-flock",
                              "unix-dotfile", "unix-none"),
                      unix = c("unix-dotfile", "unix-none"),
                      windows = character(0),
                      character(0))
    drv <- SQLite()
    checkVfs <- function(v)
    {
        db <- dbConnect(drv, dbname = "", vfs = v)
        on.exit(dbDisconnect(db))
        checkEquals(v, dbGetInfo(db)[["vfs"]])
    }
    for (v in allowed) checkVfs(v)
}

test_open_flags <- function()
{
    drv <- SQLite()
    tmpFile <- tempfile()
    on.exit(file.remove(tmpFile))

    ## error if file does not exist
    checkException(dbConnect(drv, dbname = tmpFile, flags = SQLITE_RO))
    checkException(dbConnect(drv, dbname = tmpFile, flags = SQLITE_RW))

    dbrw <- dbConnect(drv, dbname = tmpFile, flags = SQLITE_RWC)
    df <- data.frame(a=letters, b=runif(26L), stringsAsFactors=FALSE)
    checkTrue(dbWriteTable(dbrw, "t1", df))

    dbro <- dbConnect(drv, dbname = tmpFile, flags = SQLITE_RO)
    checkTrue(!suppressWarnings(dbWriteTable(dbro, "t2", df)))

    dbrw2 <- dbConnect(drv, dbname = tmpFile, flags = SQLITE_RW)
    checkTrue(dbWriteTable(dbrw2, "t2", df))

    dbDisconnect(dbrw)
    dbDisconnect(dbro)
    dbDisconnect(dbrw2)
}

test_query_closed_connection <- function()
{
    db <- dbConnect(SQLite(), dbname = ":memory:")
    dbDisconnect(db)
    checkException(dbGetQuery(db, "select * from foo"))
}

