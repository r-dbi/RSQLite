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
    drv <- SQLite()
    allowed <- c("unix-posix", "unix-afp", "unix-flock", "unix-dotfile",
                 "unix-none")
    checkVfs <- function(v)
    {
        db <- dbConnect(drv, dbname = "", vfs = v)
        on.exit(dbDisconnect(db))
        checkEquals(v, dbGetInfo(db)[["vfs"]])
    }
    for (v in allowed) checkVfs(v)
}
