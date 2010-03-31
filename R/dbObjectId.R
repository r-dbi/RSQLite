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

setClass("dbObjectId", representation(Id = "externalptr", "VIRTUAL"))

setMethod("show", "dbObjectId",
   definition = function(object) {
      expired <- if(isIdCurrent(object)) "" else "Expired "
      id <- .Call("DBI_handle_to_string", object@Id, PACKAGE = .SQLitePkgName)
      str <- paste("<", expired, class(object), ": ", id, ">", sep="")
      cat(str, "\n")
      invisible(NULL)
   }
)

"isIdCurrent" <- 
function(obj)
## verify that obj refers to a currently open/loaded database
{ 
   .Call("RS_DBI_validHandle", obj@Id, PACKAGE = .SQLitePkgName)
}
