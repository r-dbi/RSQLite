SQLITE_RWC <- 6L
SQLITE_RW <- 2L
SQLITE_RO <- 1L

.SQLitePkgName <- "RSQLite"
.SQLite.NA.string <- "\\N"  ## on input SQLite interprets \N as NULL (NA)

setOldClass("data.frame")   ## to avoid warnings in setMethod's valueClass arg
