.SQLitePkgName <- "RSQLite"
.SQLite.NA.string <- "\\N"  ## on input SQLite interprets \N as NULL (NA)

setOldClass("data.frame")   ## to avoid warnings in setMethod's valueClass arg
