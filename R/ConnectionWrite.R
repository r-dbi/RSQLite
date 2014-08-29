#' Write a local data frame or file to the database.
#' 
#' @export
#' @rdname dbWriteTable
#' @param conn,con a \code{\linkS4class{SQLiteConnection}} object, produced by
#'   \code{\link[DBI]{dbConnect}}
#' @param name a character string specifying a table name. SQLite table names 
#'   are \emph{not} case sensitive, e.g., table names \code{ABC} and \code{abc} 
#'   are considered equal.
#' @param value a data.frame (or coercible to data.frame) object or a 
#'   file name (character).  In the first case, the data.frame is
#'   written to a temporary file and then imported to SQLite; when \code{value}
#'   is a character, it is interpreted as a file name and its contents imported
#'   to SQLite.
#' @param ... Passed on to \code{sqliteWriteTable}.
#' @export
setMethod("dbWriteTable",
  signature = signature("SQLiteConnection"),
  definition = function(conn, name, value, ...)
    sqliteWriteTable(conn, name, value, ...),
  valueClass = "logical"
)

#' @param row.names A logical specifying whether the \code{row.names} should be 
#'   output to the output DBMS table; if \code{TRUE}, an extra field whose name 
#'   will be whatever the R identifier \code{"row.names"} maps to the DBMS (see
#'   \code{\link[DBI]{make.db.names}}).
#' @param overwrite a logical specifying whether to overwrite an existing table 
#'   or not. Its default is \code{FALSE}. (See the BUGS section below)
#' @param append a logical specifying whether to append to an existing table 
#'   in the DBMS.  Its default is \code{FALSE}.
#' @param field.types character vector of named  SQL field types where
#'   the names are the names of new table's columns. If missing, types inferred
#'   with \code{\link[DBI]{dbDataType}}).
#' @export
#' @rdname dbWriteTable
sqliteWriteTable <- function(con, name, value, row.names = TRUE, 
                             overwrite = FALSE, append = FALSE, 
                             field.types = NULL, ...) {
  if (overwrite && append)
    stop("overwrite and append cannot both be TRUE")
  
  ## Do we need to clone the connection (ie., if it is in use)?
  if (length(dbListResults(con))){
    new.con <- dbConnect(con)              # there's pending work, so clone
    on.exit(dbDisconnect(new.con))
  } else {
    new.con <- con
  }
  
  foundTable <- dbExistsTable(con, name)
  new.table <- !foundTable
  createTable <- (new.table || foundTable && overwrite)
  removeTable <- (foundTable && overwrite)
  success <- dbBeginTransaction(con)
  if (!success) {
    warning("unable to begin transaction")
    return(FALSE)
  }
  ## sanity check
  if (foundTable && !removeTable && !append) {
    warning(paste("table", name,
      "exists in database: aborting dbWriteTable"))
    success <- FALSE
  }
  
  if (removeTable) {
    success <- tryCatch({
      if (dbRemoveTable(con, name)) {
        TRUE
      } else {
        warning(paste("table", name, "couldn't be overwritten"))
        FALSE
      }
    }, error=function(e) {
      warning(conditionMessage(e))
      FALSE
    })
  }
  
  if (!success) {
    dbRollback(con)
    return(FALSE)
  }
  
  if (row.names) {
    ## Need to handle row.names at this level
    ## for the bind.data to work correctly.
    ##
    ## FIXME: for R >= 2.5, we should check
    ## for numeric row.names and not convert
    ## to character.
    value <- cbind(row.names(value), value, stringsAsFactors=FALSE)
    names(value)[1] <- "row.names"
  }
  
  if (createTable) {
    sql <- dbBuildTableDefinition(new.con, name, value,
      field.types=field.types,
      row.names=FALSE)
    success <- tryCatch({
      dbGetQuery(new.con, sql)
      TRUE
    }, error=function(e) {
      warning(conditionMessage(e))
      FALSE
    })
    if (!success) {
      dbRollback(con)
      return(FALSE)
    }
  }
  
  valStr <- paste(rep("?", ncol(value)), collapse=",")
  sql <- sprintf("insert into %s values (%s)",
    name, valStr)
  success <- tryCatch({
    ## The 'finally' expression will have access to
    ## this frame, not that of 'error'.  We want ret
    ## to be defined even if an error occurs.
    ret <- FALSE
    rs <- dbSendPreparedQuery(new.con, sql, bind.data=value)
    ret <- TRUE
  }, error=function(e) {
    warning(conditionMessage(e))
    ret <- FALSE
  }, finally={
    if (exists("rs"))
      dbClearResult(rs)
    ret
  })
  if (!success)
    dbRollback(con)
  else {
    success <- dbCommit(con)
    if (!success) {
      warning(dbGetException(con)[["errorMsg"]])
      dbRollback(con)
    }
  }
  success
}


#' @export
#' @rdname dbWriteTable
#' @param header is a logical indicating whether the first data line (but see
#'   \code{skip}) has a header or not.  If missing, it value is determined
#'   following \code{\link{read.table}} convention, namely, it is set to TRUE if
#'   and only if the first row has one fewer field that the number of columns.
#' @param sep The field separator, defaults to \code{','}.
#' @param eol The end-of-line delimiter, defaults to \code{'\n'}.
#' @param skip number of lines to skip before reading the data. Defaults to 0.
#' @param nrows Number of rows to read to determine types 
sqliteImportFile <- function(con, name, value, field.types = NULL, 
                             overwrite = FALSE, append = FALSE, header, 
                             row.names, nrows = 50, sep = ",", eol="\n", 
                             skip = 0, ...) {
  if(overwrite && append)
    stop("overwrite and append cannot both be TRUE")
  
  ## Do we need to clone the connection (ie., if it is in use)?
  if(length(dbListResults(con))!=0){
    new.con <- dbConnect(con)              ## there's pending work, so clone
    on.exit(dbDisconnect(new.con))
  }
  else
    new.con <- con
  
  if(dbExistsTable(con,name)){
    if(overwrite){
      if(!dbRemoveTable(con, name)){
        warning(paste("table", name, "couldn't be overwritten"))
        return(FALSE)
      }
    }
    else if(!append){
      warning(paste("table", name, "exists in database: aborting dbWriteTable"))
      return(FALSE)
    }
  }
  
  ## compute full path name (have R expand ~, etc)
  fn <- file.path(dirname(value), basename(value))
  if(missing(header) || missing(row.names)){
    f <- file(fn, open="r")
    if(skip>0)
      readLines(f, n=skip)
    txtcon <- textConnection(readLines(f, n=2))
    flds <- count.fields.wrapper(file = txtcon, sep = sep, ...)
    close(txtcon)
    close(f)
    nf <- length(unique(flds))
  }
  if(missing(header)){
    header <- nf==2
  }
  if(missing(row.names)){
    if(header)
      row.names <- if(nf==2) TRUE else FALSE
    else
      row.names <- FALSE
  }
  
  new.table <- !dbExistsTable(con, name)
  if(new.table){
    ## need to init table, say, with the first nrows lines
    d <- read.table(fn, sep=sep, header=header, skip=skip, nrows=nrows,
      na.strings=.SQLite.NA.string,
      stringsAsFactors=FALSE, ...)
    sql <-
      dbBuildTableDefinition(new.con, name, d, field.types = field.types,
        row.names = row.names)
    rs <- try(dbSendQuery(new.con, sql))
    if(inherits(rs, ErrorClass)){
      warning("could not create table: aborting sqliteImportFile")
      return(FALSE)
    }
    else
      dbClearResult(rs)
  }
  else if(!append){
    warning(sprintf("table %s already exists -- use append=TRUE?", name))
  }
  rc <-
    try({
      skip <- skip + as.integer(header)
      conId <- con@Id
      .Call("RS_SQLite_importFile", conId, name, fn, sep, eol,
        as.integer(skip), PACKAGE = .SQLitePkgName)
    })
  if(inherits(rc, ErrorClass)){
    if(new.table) dbRemoveTable(new.con, name)
    return(FALSE)
  }
  TRUE
}

## wrapper for count.fields that accepts and ignores additional
## arguments passed via '...'. Note that this duplicates the default
## values of count.fields and will need to be updated if that function's
## defaults change.
count.fields.wrapper <- function(file, sep = "", quote = "\"'", skip = 0,
  blank.lines.skip = TRUE,
  comment.char = "#", ...) {
  
  count.fields(file, sep, quote, skip, blank.lines.skip, comment.char)
}
