#' @import methods
#' @import DBI
#' @useDynLib RSQLite
#' @export
setClass("SQLiteObject", representation("DBIObject", "dbObjectId", "VIRTUAL"))

#' @export
setMethod("dbDataType", "SQLiteObject",
  definition = function(dbObj, obj, ...) sqliteDataType(obj, ...),
  valueClass = "character"
)

#' @export
sqliteDataType <- function(obj, ...) {
  rs.class <- data.class(obj)
  rs.mode <- storage.mode(obj)
  switch(rs.class,
    numeric = if (rs.mode=="integer") "INTEGER" else "REAL",
    character = "TEXT",
    logical = "INTEGER",
    factor = "TEXT",
    ordered = "TEXT",
    ## list maps to BLOB. Although not checked, the list must
    ## either be empty or contain only raw vectors or NULLs.
    list = "BLOB",
    ## attempt to store obj according to its storage mode if it has
    ## an unrecognized class.
    switch(rs.mode,
      integer = "INTEGER",
      double = "REAL",
      ## you'll get this if class is AsIs for a list column
      ## within a data.frame
      list = if (rs.class == "AsIs") "BLOB" else "TEXT",
      "TEXT"))
}


#' @export
setMethod("make.db.names",
  signature(dbObj="SQLiteObject", snames = "character"),
  definition = function(dbObj, snames, keywords, unique, allow.keywords, ...){
    make.db.names.default(snames, keywords, unique, allow.keywords)
  },
  valueClass = "character"
)

#' @export
setMethod("SQLKeywords", "SQLiteObject",
  definition = function(dbObj, ...) .SQL92Keywords,
  valueClass = "character"
)

#' @export
setMethod("isSQLKeyword",
  signature(dbObj="SQLiteObject", name="character"),
  definition = function(dbObj, name, keywords, case, ...){
    isSQLKeyword.default(name, keywords = .SQL92Keywords, case)
  },
  valueClass = "character"
)
