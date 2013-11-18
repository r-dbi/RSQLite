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


#' Check whether an SQLite object is valid or not
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
