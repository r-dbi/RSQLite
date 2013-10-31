#' Summary methods
#' 
#' @keywords internal
#' @name summary
NULL

#' @export
#' @rdname summary
setMethod("summary", "SQLiteDriver",
  definition = function(object, ...) sqliteDescribeDriver(object, ...)
)

#' @export
#' @rdname summary
sqliteDescribeDriver <- function(obj, verbose = FALSE, ...) {
  if(!isIdCurrent(obj)){
    show(obj)
    invisible(return(NULL))
  }
  info <- dbGetInfo(obj)
  show(obj)
  cat("  Driver name: ", info$drvName, "\n")
  cat("  Max  connections:", info$length, "\n")
  cat("  Conn. processed:", info$counter, "\n")
  cat("  Default records per fetch:", info$"fetch_default_rec", "\n")
  if(verbose){
    cat("  SQLite client version: ", info$clientVersion, "\n")
    cat("  DBI version: ", dbGetDBIVersion(), "\n")
  }
  cat("  Open connections:", info$"num_con", "\n")
  if(verbose && !is.null(info$connectionIds)){
    for(i in seq(along.with = info$connectionIds)){
      cat("   ", i, " ")
      show(info$connectionIds[[i]])
    }
  }
  cat("  Shared Cache:", info$"shared_cache", "\n")
  invisible(NULL)
}

#' @export
#' @rdname summary
setMethod("summary", "SQLiteConnection",
  definition = function(object, ...) sqliteDescribeConnection(object, ...)
)

#' @export
#' @rdname summary
sqliteDescribeConnection <- function(obj, verbose = FALSE, ...) {
  if(!isIdCurrent(obj)){
    show(obj)
    invisible(return(NULL))
  }
  info <- dbGetInfo(obj)
  show(obj)
  cat("  Database name:", info$dbname, "\n")
  cat("  Loadable extensions:", info$loadableExtensions, "\n")
  cat("  File open flags:", info$falgs, "\n")
  cat("  Virtual File System:", info$vfs, "\n")
  cat("  SQLite engine version: ", info$serverVersion, "\n")
  cat("  Results Sets:\n")
  if(length(info$rsId)>0){
    for(i in seq(along.with = info$rsId)){
      cat("   ", i, " ")
      show(info$rsId[[i]])
    }
  } else
    cat("   No open result sets\n")
  invisible(NULL)
}

#' @export
#' @rdname summary
setMethod("summary", "SQLiteResult",
  definition = function(object, ...) sqliteDescribeResult(object, ...)
)

#' @export
#' @rdname summary
sqliteDescribeResult <- function(obj, verbose = FALSE, ...) {
  if(!isIdCurrent(obj)){
    show(obj)
    invisible(return(NULL))
  }
  show(obj)
  cat("  Statement:", dbGetStatement(obj), "\n")
  cat("  Has completed?", if(dbHasCompleted(obj)) "yes" else "no", "\n")
  cat("  Affected rows:", dbGetRowsAffected(obj), "\n")
  hasOutput <- as.logical(dbGetInfo(obj, "isSelect")[[1]])
  flds <- dbColumnInfo(obj)
  if(hasOutput){
    cat("  Output fields:", nrow(flds), "\n")
    if(verbose && length(flds)>0){
      cat("  Fields:\n")
      out <- print(flds)
    }
  }
  invisible(NULL)
}
