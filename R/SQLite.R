##
## $Id$
##
## Copyright (C) 1999-2003 The Omega Project for Statistical Computing.
##
## This library is free software; you can redistribute it and/or
## modify it under the terms of the GNU Lesser General Public
## License as published by the Free Software Foundation; either
## version 2 of the License, or (at your option) any later version.
##
## This library is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
## Lesser General Public License for more details.
##
## You should have received a copy of the GNU Lesser General Public
## License along with this library; if not, write to the Free Software
## Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA

##
## Constants
##

.SQLitePkgName <- "RSQLite"
.SQLitePkgRCS <- "$Id$"
.SQLite.NA.string <- "\\N"  ## on input SQLite interprets \N as NULL (NA)

setOldClass("data.frame")   ## to avoid warnings in setMethod's valueClass arg

## ------------------------------------------------------------------
## Begin DBI extensions: 
##
## generics dbSendPreparedQuery, dbGetPreparedQuery 
## and dbBeginTransaction
##
setGeneric("dbSendPreparedQuery", 
   def = function(conn, statement, bind.data, ...) 
           standardGeneric("dbSendPreparedQuery"),
   valueClass = "DBIResult"
)
setGeneric("dbGetPreparedQuery", 
   def = function(conn, statement, bind.data, ...) 
           standardGeneric("dbGetPreparedQuery")
)
setGeneric("dbBeginTransaction", 
   def = function(conn, ...)
           standardGeneric("dbBeginTransaction"),
   valueClass = "logical"
)
##
## End DBI extensions
## ------------------------------------------------------------------


##
## Class: SQLiteDriver
##

setClass("SQLiteObject", representation("DBIObject", "dbObjectId", "VIRTUAL"))
setClass("SQLiteDriver", representation("DBIDriver", "SQLiteObject"))

"SQLite" <-
function(max.con=16, fetch.default.rec = 500, force.reload=FALSE,
         shared.cache=FALSE)
{
   sqliteInitDriver(max.con, fetch.default.rec, force.reload, shared.cache)
}

setMethod("dbUnloadDriver", "SQLiteDriver",
   def = function(drv, ...) sqliteCloseDriver(drv, ...),
   valueClass = "logical"
)
setMethod("dbGetInfo", "SQLiteDriver",
   def = function(dbObj, ...) sqliteDriverInfo(dbObj, ...),
   valueClass = "list"
)
setMethod("dbListConnections", "SQLiteDriver",
   def = function(drv, ...) {
      cons <- dbGetInfo(drv, what = "connectionIds")[[1]]
      if(!is.null(cons)) cons else list()
   },
   valueClass = "list"
)
setMethod("summary", "SQLiteDriver",
   def = function(object, ...) sqliteDescribeDriver(object, ...)
)

##
## Class: SQLiteConnection
##

setClass("SQLiteConnection", representation("DBIConnection", "SQLiteObject"))

setAs("SQLiteConnection", "SQLiteDriver",
   def = function(from) new("SQLiteDriver", Id = as(from,"integer")[1])
)
setMethod("dbConnect", "SQLiteDriver",
   def = function(drv, ...) sqliteNewConnection(drv, ...),
   valueClass = "SQLiteConnection"
)
setMethod("dbConnect", "character",
   def = function(drv, ...){
      d <- dbDriver(drv)
      dbConnect(d, ...)
   },
   valueClass = "SQLiteConnection"
)
setMethod("dbConnect", "SQLiteConnection",
   def = function(drv, ...){
      con.id <- as(drv, "integer")
      new.id <- .Call("RS_SQLite_cloneConnection", con.id, PACKAGE = .SQLitePkgName)
      new("SQLiteConnection", Id = new.id)
   },
   valueClass = "SQLiteConnection"
)
setMethod("dbDisconnect", "SQLiteConnection",
   def = function(conn, ...) sqliteCloseConnection(conn, ...),
   valueClass = "logical"
)
setMethod("dbGetInfo", "SQLiteConnection",
   def = function(dbObj, ...) sqliteConnectionInfo(dbObj, ...),
   valueClass = "list"
)
setMethod("dbGetException", "SQLiteConnection",
   def = function(conn, ...){
      id <- as(conn, "integer")
      .Call("RS_SQLite_getException", id, PACKAGE = .SQLitePkgName)
   },
   valueClass = "list"    ## TODO: should return a SQLiteException
)
setMethod("dbSendQuery",
   sig = signature(conn = "SQLiteConnection", statement = "character"),
   def = function(conn, statement, ...){
      sqliteExecStatement(conn, statement, ...)
   },
   valueClass = "SQLiteResult"
)
setMethod("dbSendPreparedQuery", 
   sig = signature(conn = "SQLiteConnection", statement = "character",
                   bind.data = "data.frame"),
   def = function(conn, statement, bind.data, ...){
      sqliteExecStatement(conn, statement, bind.data, ...)
   },
   valueClass = "SQLiteResult"
)
setMethod("dbGetQuery",
   sig = signature(conn = "SQLiteConnection", statement = "character"),
   def = function(conn, statement, ...){
      sqliteQuickSQL(conn, statement, ...)
   },
)
setMethod("dbGetPreparedQuery", 
   sig = signature(conn = "SQLiteConnection", statement = "character",
                   bind.data = "data.frame"),
   def = function(conn, statement, bind.data, ...){
      sqliteQuickSQL(conn, statement, bind.data, ...)
   },
   valueClass = "SQLiteResult"
)
setMethod("summary", "SQLiteConnection",
   def = function(object, ...) sqliteDescribeConnection(object, ...)
)

setMethod("dbCallProc", "SQLiteConnection",
   def = function(conn, ...) .NotYetImplemented()
)

setMethod("dbCommit", "SQLiteConnection",
   def = function(conn, ...) sqliteTransactionStatement(conn, "COMMIT")
)

setMethod("dbRollback", "SQLiteConnection",
   def = function(conn, ...) {
       rsList <- dbListResults(conn)
       if (length(rsList))
         dbClearResult(rsList[[1]])
       sqliteTransactionStatement(conn, "ROLLBACK")
   }
)

setMethod("dbBeginTransaction", "SQLiteConnection",
   def = function(conn, ...) sqliteTransactionStatement(conn, "BEGIN")
)

##
## Convenience methods
##

setMethod("dbExistsTable",
   sig = signature(conn = "SQLiteConnection", name = "character"),
   def = function(conn, name, ...){
      lst <- dbListTables(conn)
      match(tolower(name), tolower(lst), nomatch = 0) > 0
   },
   valueClass = "logical"
)
setMethod("dbReadTable",
   sig = signature(conn = "SQLiteConnection", name = "character"),
   def = function(conn, name, ...) sqliteReadTable(conn, name, ...),
   valueClass = "data.frame"
)
setMethod("dbWriteTable",
   sig = signature(conn = "SQLiteConnection", name = "character",
                   value="data.frame"),
   def = function(conn, name, value, ...)
      sqliteWriteTable(conn, name, value, ...),
   valueClass = "logical"
)

## create/load table from a file via dbWriteTable (the argument
## value specifies a file name).  TODO, value a connection.
setMethod("dbWriteTable",
   sig = signature(conn = "SQLiteConnection", name = "character",
                   value="character"),
   def = function(conn, name, value, ...)
      sqliteImportFile(conn, name, value, ...),
   valueClass = "logical"
)
setMethod("dbRemoveTable",
   sig = signature(conn = "SQLiteConnection", name = "character"),
   def = function(conn, name, ...){
      rc <- try(dbGetQuery(conn, paste("drop table", name)))
      !inherits(rc, ErrorClass)
   },
   valueClass = "logical"
)
setMethod("dbListResults", "SQLiteConnection",
   def = function(conn, ...) {
      rs <- dbGetInfo(conn, "rsId")[[1]]
      if(length(rs)>0) rs else list()
   },
   valueClass = "list"
)

##
## Class: SQLiteResult
##

setClass("SQLiteResult", representation("DBIResult", "SQLiteObject"))

setAs("SQLiteResult", "SQLiteConnection",
   def = function(from) new("SQLiteConnection", Id = as(from,"integer")[1:2])
)
setMethod("fetch", "SQLiteResult",
   def = function(res, n = 0, ...) sqliteFetch(res, n = n, ...),
   valueClass = "data.frame"
)
setMethod("dbClearResult", "SQLiteResult",
   def = function(res, ...) sqliteCloseResult(res, ...),
   valueClass = "logical"
)
setMethod("dbGetInfo", "SQLiteResult",
   def = function(dbObj, ...) sqliteResultInfo(dbObj, ...),
   valueClass = "list"
)
setMethod("dbGetStatement", "SQLiteResult",
   def = function(res, ...) dbGetInfo(res, "statement")[[1]],
   valueClass = "character"
)
setMethod("dbColumnInfo", "SQLiteResult",
   def = function(res, ...){
      out <- dbGetInfo(res, "fields")[[1]]
      if(!is.null(out)) out else data.frame(out)
   },
   valueClass = "data.frame"
)
setMethod("dbGetRowsAffected", "SQLiteResult",
   def = function(res, ...) dbGetInfo(res, "rowsAffected")[[1]],
   valueClass = "integer"
)
setMethod("dbGetRowCount", "SQLiteResult",
   def = function(res, ...) dbGetInfo(res, "rowCount")[[1]],
   valueClass = "integer"
)
setMethod("dbHasCompleted", "SQLiteResult",
   def = function(res, ...){
      out <- dbGetInfo(res, "completed")[[1]]
      if(out<0)
         NA
      else ifelse(out==0, FALSE, TRUE)
   },
   valueClass = "logical"
)

setMethod("dbListTables", "SQLiteConnection",
   def = function(conn, ...){
      out <- dbGetQuery(conn,
         "select name from sqlite_master where type='table' or type='view' order by name",
         ...)
      if (is.null(out) || nrow(out) == 0)
        out <- character(0)
      else
        out <- out[, 1]
      out
   },
   valueClass = "character"
)
setMethod("dbListFields",
   sig = signature(conn = "SQLiteConnection", name = "character"),
   def = function(conn, name, ...) sqliteTableFields(conn, name, ...),
   valueClass = "character"
)

setMethod("summary", "SQLiteResult",
   def = function(object, ...) sqliteDescribeResult(object, ...)
)

##
## Utilities
##

setMethod("dbDataType", "SQLiteObject",
   def = function(dbObj, obj, ...) sqliteDataType(obj, ...),
   valueClass = "character"
)


setMethod("make.db.names",
   signature(dbObj="SQLiteObject", snames = "character"),
   def = function(dbObj, snames, keywords, unique, allow.keywords, ...){
      make.db.names.default(snames, keywords, unique, allow.keywords)
   },
   valueClass = "character"
)

setMethod("SQLKeywords", "SQLiteObject",
   def = function(dbObj, ...) .SQL92Keywords,
   valueClass = "character"
)

setMethod("isSQLKeyword",
   signature(dbObj="SQLiteObject", name="character"),
   def = function(dbObj, name, keywords, case, ...){
        isSQLKeyword.default(name, keywords = .SQL92Keywords, case)
   },
   valueClass = "character"
)
