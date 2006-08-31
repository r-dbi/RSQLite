## $Id$
##
## DBI.S  Database Interface Definition
## For full details see http://www.omegahat.org
##
## Copyright (C) 1999,2000 The Omega Project for Statistical Computing.
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
## Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
##

## Define all the classes and methods to be used by an implementation
## of the RS-DataBase Interface.  All these classes are virtual
## and each driver should extend them to provide the actual implementation.
## See the files Oracle.S and MySQL.S for the Oracle and MySQL 
## S implementations, respectively.  The support files (they have "support"
## in their names) for code that is R-friendly and may be easily ported
## to R. 

## Class: dbManager 
## This class identifies the DataBase Management System (oracle, informix, etc)

dbManager <- function(obj, ...)
{
  do.call(as.character(obj), list(...))
}
load <- function(mgr, ...)
{
  UseMethod("load")
}
unload <- function(mgr, ...)
{
  UseMethod("unload")
}
getManager <- function(obj, ...)
{
  UseMethod("getManager")
}
getConnections <- function(mgr, ...)
{
  UseMethod("getConnections")
}
## Class: dbConnection

dbConnect <- function(mgr, ...)
{
  UseMethod("dbConnect")
}
dbExecStatement <- function(con, statement, ...)
{
  UseMethod("dbExecStatement")
}
dbExec <- function(con, statement, ...)
{
  UseMethod("dbExec")
}
commit <- function(con, ...)
{
  UseMethod("commit")
}
rollback <- function(con, ...)
{
  UseMethod("rollback")
}
callProc <- function(con, ...)
{
  UseMethod("callProc")
}
close.dbConnection <- function(con, ...)
{
  stop("close for dbConnection objects needs to be written")
}

getResultSets <- function(con, ...)
{
   UseMethod("getResultSets")
}
getException <- function(con, ...)
{
   UseMethod("getException")
}

## close is already a generic function in R

## Class: dbResult
## This is the base class for arbitrary results from TDBSM (INSERT,
## UPDATE, RELETE, etc.)  SELECT's (and SELECT-lie) statements produce
## "dbResultSet" objects, which extend dbResult.

## Class: dbResultSet
fetch <- function(res, n, ...)
{
  UseMethod("fetch")
}
setDataMappings <- function(res, ...)
{
  UseMethod("setDataMappings")
}
close.resultSet <- function(con, ...)
{
  stop("close method for dbResultSet objects need to be written")
}

## Need to elevate the current load() to the load.default
if(!exists("load.default")){
  if(exists("load", mode = "function", where = match("package:base",
search())))
    load.default <- get("load", mode = "function", 
                                 pos = match("package:base", search()))
  else
    load.default <- function(file, ...) stop("method must be overriden")
}

## Need to elevate the current getConnection to a default method,
## and define getConnection to be a generic

if(!exists("getConnection.default")){
  if(exists("getConnection", mode="function", where=match("package:base",search())))
    getConnection.default <- get("getConnection", mode = "function",
                                 pos=match("package:base", search()))
  else
    getConnection.default <- function(what, ...) 
      stop("method must be overriden")
}
if(!usingR(1,2.1)){
  close <- function(con, ...) UseMethod("close")
}
getConnection <- function(what, ...)
{
  UseMethod("getConnection")
}
getFields <- function(res, ...)
{
  UseMethod("getFields")
}
getStatement <- function(res, ...)
{
  UseMethod("getStatement")
}
getRowsAffected <- function(res, ...)
{
  UseMethod("getRowsAffected")
}
getRowCount <- function(res, ...)
{
  UseMethod("getRowCount")
}
getNullOk <- function(res, ...)
{
  UseMethod("getNullOk")
}
hasCompleted <- function(res, ...)
{
  UseMethod("hasCompleted")
}
## these next 2 are meant to be used with tables (not general purpose
## result sets) thru connections
getNumRows <- function(con, name, ...)
{
   UseMethod("getNumRows")
}
getNumCols <- function(con, name, ...)
{
   UseMethod("getNumCols")
}
getNumCols.default <- function(con, name, ...)
{
   nrow(getFields(con, name))
}
## (I don't know how to efficiently and portably get num of rows of a table)

## Meta-data: 
## The approach in the current implementation is to have .Call()
##  functions return named lists with all the known features for
## the various objects (dbManager, dbConnection, dbResultSet, 
## etc.) and then each meta-data function (e.g., getVersion) extract 
## the appropriate field from the list.  Of course, there are meta-data
## elements that need to access to DBMS data dictionaries (e.g., list
## of databases, priviledges, etc) so they better be implemented using 
## the SQL inteface itself, say thru quickSQL.
## 
## It may be possible to get some of the following meta-data from the
## dbManager object iteslf, or it may be necessary to get it from a
## dbConnection because the dbManager does not talk itself to the
## actual DBMS.  The implementation will be driver-specific.  
##
## TODO: what to do about permissions? privileges? users? Some 
## databses, e.g., mSQL, do not support multiple users.  Can we get 
## away without these?  The basis for defining the following meta-data 
## is to provide the basics for writing methods for attach(db) and 
## related methods (objects, exist, assign, remove) so that we can even
## abstract from SQL and the RS-Database interface itself.

getInfo <- function(obj, ...)
{
  UseMethod("getInfo")
}
describe <- function(obj, verbose = F, ...)
{
  UseMethod("describe")
}
getVersion <- function(obj, ...)
{
  UseMethod("getVersion")
}
getCurrentDatabase <- function(obj, ...)
{
  UseMethod("getCurrentDatabase")
}
getDatabases <- function(obj, ...)
{
  UseMethod("getDatabases")
}
getTables <- function(obj, dbname, row.names, ...) 
{
  UseMethod("getTables")
}
getTableFields <- function(res, table, dbname, ...)
{
  UseMethod("getTableFields")
}
getTableIndices <- function(res, table, dbname, ...) 
{
  UseMethod("getTableIndices")
}

## Class: dbObjectId
##
## This helper class is *not* part of the database interface definition,
## but it is extended by both the Oracle and MySQL implementations to
## MySQLObject and OracleObject to allow us to conviniently implement 
## all database foreign objects methods (i.e., methods for show(), 
## print() format() the dbManger, dbConnection, dbResultSet, etc.) 
## A dbObjectId is an  identifier into an actual remote database objects.  
## This class and its derived classes <driver-manager>Object need to 
## be VIRTUAL to avoid coercion (green book, p.293) during method dispatching.

##setClass("dbObjectId", representation(Id = "integer", VIRTUAL))

new.dbObjectId <- function(Id, ...)
{
  new("dbObjectId", Id = Id)
}
## Coercion: the trick as(dbObject, "integer") is very useful
## (in R this needs to be define for each of the "mixin" classes -- Grr!)
as.integer.dbObjectId <- 
function(object)
{
  as.integer(object$Id)
}

"isIdCurrent" <- 
function(obj)
## verify that obj refers to a currently open/loaded database
{ 
  obj <- as(obj, "integer")
  .Call("RS_DBI_validHandle", obj)
}

"format.dbObjectId" <- 
function(x, ...)
{
  id <- as(x, "integer")
  paste("(", paste(id, collapse=","), ")", sep="")
}
"print.dbObjectId" <- 
function(x, ...)
{
  str <- paste(class(x), " id = ", format(x), sep="")
  if(isIdCurrent(x))
    cat(str, "\n")
  else
    cat("Expired", str, "\n")
  invisible(NULL)
}

## These are convenience functions that mimic S database access methods 
## get(), assign(), exists(), and remove().

"getTable" <-  function(con, name, ...)
{
  UseMethod("getTable")
}

"getTable.dbConnection" <- 
function(con, name, row.names = "row.names", check.names = T, ...)
## Should we also allow row.names to be a character vector (as in read.table)?
## is it "correct" to set the row.names of output data.frame?
## Use NULL, "", or 0 as row.names to prevent using any field as row.names.
{
  out <- quickSQL(con, paste("SELECT * from", name))
  if(check.names)
     names(out) <- make.names(names(out), unique = T)
  ## should we set the row.names of the output data.frame?
  nms <- names(out)
  j <- switch(mode(row.names),
         "character" = if(row.names=="") 0 else
                       match(tolower(row.names), tolower(nms), 
                             nomatch = if(missing(row.names)) 0 else -1),
         "numeric" = row.names,
         "NULL" = 0,
         0)
  if(j==0) 
     return(out)
  if(j<0 || j>ncol(out)){
     warning("row.names not set on output data.frame (non-existing field)")
     return(out)
  }
  rnms <- as.character(out[,j])
  if(all(!duplicated(rnms))){
      out <- out[,-j, drop = F]
      row.names(out) <- rnms
  } else warning("row.names not set on output (duplicate elements in field)")
  out
} 

"existsTable" <- function(con, name, ...)
{
  UseMethod("existsTable")
}
"existsTable.dbConnection" <- function(con, name, ...)
{
    ## name is an SQL (not an R/S!) identifier.
    match(name, getTables(con), nomatch = 0) > 0
}
"removeTable" <- function(con, name, ...)
{
  UseMethod("removeTable")
}
"removeTable.dbConnection" <- function(con, name, ...)
{
  if(existsTable(con, name, ...)){
    rc <- try(quickSQL(con, paste("DROP TABLE", name)))
    !inherits(rc, "Error")
  } 
  else  FALSE
}

"assignTable" <- function(con, name, value, row.names, ...)
{
  UseMethod("assignTable")
}

## The following generic returns the closest data type capable 
## of representing an R/S object in a DBMS.  
## TODO:  Lots! We should have a base SQL92 method that individual
## drivers extend?  Currently there is no default.  Should
## we also allow data type mapping from SQL -> R/S?

"SQLDataType" <- function(mgr, obj, ...)
{
  UseMethod("SQLDataType")
}
SQLDataType.default <- function(mgr, obj, ...)
{
   ## should we supply an SQL89/SQL92 default implementation?
   stop("must be implemented by a specific driver")
}
"make.SQL.names" <- 
function(snames, unique = T, allow.keywords = T)
## produce legal SQL identifiers from strings in a character vector
## unique, in this function, means unique regardless of lower/upper case
{
   makeUnique <- function(x, sep="_"){
     out <- x
     lc <- make.names(tolower(x), unique=F)
     i <- duplicated(lc)
     lc <- make.names(lc, unique = T)
     out[i] <- paste(out[i], substring(lc[i], first=nchar(out[i])+1), sep=sep)
     out
   }
   snames  <- make.names(snames, unique=F)
   if(unique) 
     snames <- makeUnique(snames)
   if(!allow.keywords){
     snames <- makeUnique(c(.SQLKeywords, snames))
     snames <- snames[-seq(along = .SQLKeywords)]
   } 
   .Call("RS_DBI_makeSQLNames", snames)
}

"isSQLKeyword" <-
function(x, keywords = .SQLKeywords, case = c("lower", "upper", "any")[3])
{
   n <- pmatch(case, c("lower", "upper", "any"), nomatch=0)
   if(n==0)
     stop('case must be one of "lower", "upper", or "any"')
   kw <- switch(c("lower", "upper", "any")[n],
           lower = tolower(keywords),
           upper = toupper(keywords),
           any = toupper(keywords))
   if(n==3)
     x <- toupper(x)
   match(x, keywords, nomatch=0) > 0
}
## SQL ANSI 92 (plus ISO's) keywords --- all 220 of them!
## (See pp. 22 and 23 in X/Open SQL and RDA, 1994, isbn 1-872630-68-8)
".SQLKeywords" <- 
c("ABSOLUTE", "ADD", "ALL", "ALLOCATE", "ALTER", "AND", "ANY", "ARE", "AS",
  "ASC", "ASSERTION", "AT", "AUTHORIZATION", "AVG", "BEGIN", "BETWEEN",
  "BIT", "BIT_LENGTH", "BY", "CASCADE", "CASCADED", "CASE", "CAST", 
  "CATALOG", "CHAR", "CHARACTER", "CHARACTER_LENGTH", "CHAR_LENGTH",
  "CHECK", "CLOSE", "COALESCE", "COLLATE", "COLLATION", "COLUMN", 
  "COMMIT", "CONNECT", "CONNECTION", "CONSTRAINT", "CONSTRAINTS", 
  "CONTINUE", "CONVERT", "CORRESPONDING", "COUNT", "CREATE", "CURRENT",
  "CURRENT_DATE", "CURRENT_TIMESTAMP", "CURRENT_TYPE", "CURSOR", "DATE",
  "DAY", "DEALLOCATE", "DEC", "DECIMAL", "DECLARE", "DEFAULT", 
  "DEFERRABLE", "DEFERRED", "DELETE", "DESC", "DESCRIBE", "DESCRIPTOR",
  "DIAGNOSTICS", "DICONNECT", "DICTIONATRY", "DISPLACEMENT", "DISTINCT",
  "DOMAIN", "DOUBLE", "DROP", "ELSE", "END", "END-EXEC", "ESCAPE", 
  "EXCEPT", "EXCEPTION", "EXEC", "EXECUTE", "EXISTS", "EXTERNAL", 
  "EXTRACT", "FALSE", "FETCH", "FIRST", "FLOAT", "FOR", "FOREIGN", 
  "FOUND", "FROM", "FULL", "GET", "GLOBAL", "GO", "GOTO", "GRANT", 
  "GROUP", "HAVING", "HOUR", "IDENTITY", "IGNORE", "IMMEDIATE", "IN",
  "INCLUDE", "INDEX", "INDICATOR", "INITIALLY", "INNER", "INPUT", 
  "INSENSITIVE", "INSERT", "INT", "INTEGER", "INTERSECT", "INTERVAL",
  "INTO", "IS", "ISOLATION", "JOIN", "KEY", "LANGUAGE", "LAST", "LEFT",
  "LEVEL", "LIKE", "LOCAL", "LOWER", "MATCH", "MAX", "MIN", "MINUTE",
  "MODULE", "MONTH", "NAMES", "NATIONAL", "NCHAR", "NEXT", "NOT", "NULL",
  "NULLIF", "NUMERIC", "OCTECT_LENGTH", "OF", "OFF", "ONLY", "OPEN",
  "OPTION", "OR", "ORDER", "OUTER", "OUTPUT", "OVERLAPS", "PARTIAL",
  "POSITION", "PRECISION", "PREPARE", "PRESERVE", "PRIMARY", "PRIOR",
  "PRIVILEGES", "PROCEDURE", "PUBLIC", "READ", "REAL", "REFERENCES",
  "RESTRICT", "REVOKE", "RIGHT", "ROLLBACK", "ROWS", "SCHEMA", "SCROLL",
  "SECOND", "SECTION", "SELECT", "SET", "SIZE", "SMALLINT", "SOME", "SQL",
  "SQLCA", "SQLCODE", "SQLERROR", "SQLSTATE", "SQLWARNING", "SUBSTRING",
  "SUM", "SYSTEM", "TABLE", "TEMPORARY", "THEN", "TIME", "TIMESTAMP",
  "TIMEZONE_HOUR", "TIMEZONE_MINUTE", "TO", "TRANSACTION", "TRANSLATE",
  "TRANSLATION", "TRUE", "UNION", "UNIQUE", "UNKNOWN", "UPDATE", "UPPER",
  "USAGE", "USER", "USING", "VALUE", "VALUES", "VARCHAR", "VARYING",
  "VIEW", "WHEN", "WHENEVER", "WHERE", "WITH", "WORK", "WRITE", "YEAR",
  "ZONE"
)

