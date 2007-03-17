##
## $Id$
## 
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
##

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

setClass("dbObjectId", representation(Id = "integer", "VIRTUAL"))

## coercion methods 
setAs("dbObjectId", "integer", 
   def = function(from) as(slot(from,"Id"), "integer")
)
setAs("dbObjectId", "numeric",
   def = function(from) as(slot(from, "Id"), "integer")
)
setAs("dbObjectId", "character",
   def = function(from) as(slot(from, "Id"), "character")
)   

## formating, showing, printing,...
setMethod("format", "dbObjectId", 
   def = function(x, ...) {
      paste("(", paste(as(x, "integer"), collapse=","), ")", sep="")
   },
   valueClass = "character"
)

setMethod("show", "dbObjectId",
   def = function(object) {
      expired <- if(isIdCurrent(object)) "" else "Expired "
      str <- paste("<", expired, class(object), ":", format(object), ">", sep="")
      cat(str, "\n")
      invisible(NULL)
   }
)

"isIdCurrent" <- 
function(obj)
## verify that obj refers to a currently open/loaded database
{ 
   obj <- as(obj, "integer")
   .Call("RS_DBI_validHandle", obj, PACKAGE = .SQLitePkgName)
}
