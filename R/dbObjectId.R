## Copyright (C) 1999-2002 The Omega Project for Statistical Computing.
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

## Class: dbObjectId
##
## This mixin helper class is NOT part of the database interface definition,
## but it is extended by the Oracle, MySQL, and SQLite implementations to
## MySQLObject and OracleObject to allow us to conviniently (and portably) 
## implement all database foreign objects methods (i.e., methods for show(), 
## print() format() the dbManger, dbConnection, dbResultSet, etc.) 
## A dbObjectId is an  identifier into an actual remote database objects.  
## This class and its derived classes <driver-manager>Object need to 
## be VIRTUAL to avoid coercion (green book, p.293) during method dispatching.
##
## TODO: Convert the Id slot to be an external object (as per Luke Tierney's
## implementation), even at the expense of S-plus compatibility?

#' Class dbObjectId.
#' 
#' A helper (mixin) class to provide external references in an R/S-Plus
#' portable way.
#' 
#' @note A cleaner mechanism would use external references, but historically
#' this class has existed mainly for R/S-Plus portability.
#' @section Objects from the Class: A virtual Class: No objects may be created
#' from it.
#' @examples
#' con <- dbConnect(SQLite(), ":memory:")
#' is(sqlite, "dbObjectId")   ## True
#' is(con, "dbObjectId")  ## True
#' isIdCurrent(con)       ## True
#' dbDisconnect(con)
#' isIdCurrent(con)       ## False
#' @export
setClass("dbObjectId", representation(Id = "externalptr", "VIRTUAL"))

#' @export
#' @rdname dbObjectId-class
#' @param object of class \code{dbObjectId}
setMethod("show", "dbObjectId",
   definition = function(object) {
      expired <- if(isIdCurrent(object)) "" else "Expired "
      id <- .Call("DBI_handle_to_string", object@Id, PACKAGE = .SQLitePkgName)
      str <- paste("<", expired, class(object), ": ", id, ">", sep="")
      cat(str, "\n")
      invisible(NULL)
   }
)



#' Check whether an dbObjectId handle object is valid or not
#' 
#' Support function that verifies that an dbObjectId holding a reference to a
#' foreign object is still valid for communicating with the RDBMS
#' 
#' \code{dbObjectId} are R/S-Plus remote references to foreign (C code)
#' objects. This introduces differences to the object's semantics such as
#' persistence (e.g., connections may be closed unexpectedly), thus this
#' function provides a minimal verification to ensure that the foreign object
#' being referenced can be contacted.
#' 
#' @param obj any \code{dbObjectId} (e.g., \code{dbDriver},
#' \code{dbConnection}, \code{dbResult}).
#' @return a logical scalar.
#' @examples
#' \dontrun{
#' cursor <- dbSendQuery(con, sql.statement)
#' isIdCurrent(cursor)
#' }
#' 
#' @export isIdCurrent
"isIdCurrent" <- 
function(obj)
## verify that obj refers to a currently open/loaded database
{ 
   .Call("RS_DBI_validHandle", obj@Id, PACKAGE = .SQLitePkgName)
}
