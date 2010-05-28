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

"sqliteInitDriver" <-
function(max.con = 16, fetch.default.rec = 500, force.reload=FALSE,
         shared.cache=FALSE)
## return a manager id
{
  config.params <- as.integer(c(max.con, fetch.default.rec))
  force <- as.logical(force.reload)
  cache <- as.logical(shared.cache)
  id <- .Call("RS_SQLite_init", config.params, force, cache, PACKAGE = .SQLitePkgName)
  new("SQLiteDriver", Id = id)
}

"sqliteCloseDriver" <-
function(drv, ...)
{
  .Call("RS_SQLite_closeManager", drv@Id, PACKAGE = .SQLitePkgName)
}

"sqliteDescribeDriver" <-
function(obj, verbose = FALSE, ...)
## Print out nicely a brief description of the connection Manager
{
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

"sqliteDriverInfo" <-
function(obj, what="", ...)
{
  if(!isIdCurrent(obj))
    stop(paste("expired", class(obj)))
  drvId <- obj@Id
  info <- .Call("RS_SQLite_managerInfo", drvId, PACKAGE = .SQLitePkgName)
  info$managerId <- obj
  ## connection IDs are no longer tracked by the manager.
  info$connectionIds <- list()
  if(!missing(what))
    info[what]
  else
    info
}

## note that dbname may be a database name, an empty string "", or NULL.
## The distinction between "" and NULL is that "" is interpreted by
## the SQLite API as the default database (SQLite config specific)
## while NULL means "no database".
"sqliteNewConnection"<-
function(drv, dbname = "", loadable.extensions = TRUE, cache_size = NULL,
         synchronous = 0, flags = NULL, vfs = NULL)
{
  if (is.null(dbname))
    dbname <- ""
  ## path.expand converts as.character(NA) => "NA"
  if (any(is.na(dbname)))
      stop("'dbname' must not be NA")
  dbname <- path.expand(dbname)
  loadable.extensions <- as.logical(loadable.extensions)
  if (!is.null(vfs)) {
      if (.Platform[["OS.type"]] == "windows") {
          warning("vfs customization not available on this platform.",
                  " Ignoring value: vfs = ", vfs)
      } else {
          if (length(vfs) != 1L)
              stop("'vfs' must be NULL or a character vector of length one")
          allowed <- c("unix-posix", "unix-afp", "unix-flock", "unix-dotfile",
                       "unix-none")
          if (!(vfs %in% allowed)) {
              stop("'vfs' must be one of ",
                   paste(allowed, collapse=", "),
                   ". See http://www.sqlite.org/compile.html")
          }
      }
  }
  flags <- if (is.null(flags)) SQLITE_RWC else flags
  drvId <- drv@Id
  conId <- .Call("RS_SQLite_newConnection", drvId,
                 dbname, loadable.extensions, flags, vfs, PACKAGE ="RSQLite")
  con <- new("SQLiteConnection", Id = conId)

  ## experimental PRAGMAs
  try({
    if(!is.null(cache_size))
      dbGetQuery(con, sprintf("PRAGMA cache_size=%d", as.integer(cache_size)))
    if(is.numeric(synchronous))
      nsync <- as.integer(synchronous)
    else if(is.character(synchronous))
      nsync <-
        pmatch(tolower(synchronous), c("off", "normal", "full"), nomatch = 1) - 1
    else nsync <- 0
    dbGetQuery(con, sprintf("PRAGMA synchronous=%d", as.integer(nsync)))
   }, silent = TRUE)

  con
}

"sqliteDescribeConnection" <-
function(obj, verbose = FALSE, ...)
{
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

"sqliteCloseConnection" <-
function(con, ...)
{
  if(!isIdCurrent(con)){
     warning(paste("expired SQLiteConnection"))
     return(TRUE)
  }
  .Call("RS_SQLite_closeConnection", con@Id, PACKAGE = .SQLitePkgName)
}

"sqliteConnectionInfo" <-
function(obj, what="", ...)
{
  if(!isIdCurrent(obj))
    stop(paste("expired", class(obj)))
  id <- obj@Id
  info <- .Call("RSQLite_connectionInfo", id, PACKAGE = .SQLitePkgName)
  if(length(info$rsId)){
    rsId <- vector("list", length = length(info$rsId))
    for(i in seq(along.with = info$rsId))
      rsId[[i]] <- new("SQLiteResult",
                       Id = .Call("DBI_newResultHandle",
                       id, info$rsId[i], PACKAGE = .SQLitePkgName))
    info$rsId <- rsId
  }
  if(!missing(what))
    info[what]
  else
    info
}


"sqliteQuickColumn" <- function(con, table, column)
{
    .Call("RS_SQLite_quick_column", con@Id, as.character(table),
          as.character(column), PACKAGE="RSQLite")
}


sqliteTransactionStatement <-
function(con, statement)
## checks for any open resultsets, and closes them if completed.
## the statement is then executed on the connection, and returns
## whether it executed without an error or not.
{
  ## are there resultSets pending on con?
  if(length(dbListResults(con)) > 0){
    res <- dbListResults(con)[[1]]
    if(!dbHasCompleted(res)){
      stop("connection with pending rows, close resultSet before continuing")
    }
    dbClearResult(res)
  }

  rc <- try(dbGetQuery(con, statement), silent = TRUE)
  !inherits(rc, ErrorClass)
}


"sqliteExecStatement" <-
function(con, statement, bind.data=NULL)
## submits the sql statement to SQLite and creates a
## dbResult object if the SQL operation does not produce
## output, otherwise it produces a resultSet that can
## be used for fetching rows.
{
  conId <- con@Id
  statement <- as(statement, "character")
  if (!is.null(bind.data)) {
      if (class(bind.data)[1] != "data.frame")
          bind.data <- as.data.frame(bind.data)
      if (min(dim(bind.data)) <= 0) {
          stop("bind.data must have non-zero dimensions")
      }
  }
  rsId <- .Call("RS_SQLite_exec",
                conId, statement, bind.data,
                PACKAGE = .SQLitePkgName)
#  out <- new("SQLitedbResult", Id = rsId)
#  if(dbGetInfo(out, what="isSelect")
#    out <- new("SQLiteResultSet", Id = rsId)
#  out
  out <- new("SQLiteResult", Id = rsId)
  out
}

## helper function: it exec's *and* retrieves a statement. It should
## be named something else.
"sqliteQuickSQL" <-
function(con, statement, bind.data=NULL, ...)
{
   rs <- sqliteExecStatement(con, statement, bind.data)
   if(dbHasCompleted(rs)){
      dbClearResult(rs)            ## no records to fetch, we're done
      invisible()
      return(NULL)
   }
   res <- sqliteFetch(rs, n = -1, ...)
   if(dbHasCompleted(rs))
      dbClearResult(rs)
   else
      warning("pending rows")
   res
}

"sqliteFetch" <-
function(res, n=0, ...)
## Fetch at most n records from the opened resultSet (n = -1 meanSQLite
## all records, n=0 means extract as many as "default_fetch_rec",
## as defined by SQLiteDriver (see summary(drv, TRUE)).
## The returned object is a data.frame.
## Note: The method dbHasCompleted() on the resultSet tells you whether
## or not there are pending records to be fetched.
##
## TODO: Make sure we don't exhaust all the memory, or generate
## an object whose size exceeds option("object.size").  Also,
## are we sure we want to return a data.frame?
{

  if(!isIdCurrent(res))
     stop("invalid result handle")
  n <- as.integer(n)
  rsId <- res@Id
  rel <- .Call("RS_SQLite_fetch", rsId, nrec = n, PACKAGE = .SQLitePkgName)
  if (is.null(rel)) rel <- list()       # result set is completed
  ## create running row index as of previous fetch (if any)
  cnt <- dbGetRowCount(res)
  nrec <- if (length(rel) > 0L) length(rel[[1L]]) else 0L
  indx <- seq(from = cnt - nrec + 1L, length.out = nrec)
  attr(rel, "row.names") <- as.integer(indx)
  class(rel) <- "data.frame"
  rel
}

"sqliteFetchOneColumn" <-
function(con, statement, n=0, ...)
{
    rs <- dbSendQuery(con, statement)
    on.exit(dbClearResult(rs))
    n <- as.integer(n)
    rsId <- rs@Id
    rel <- .Call("RS_SQLite_fetch", rsId, nrec = n, PACKAGE = .SQLitePkgName)
    if (length(rel) == 0 || length(rel[[1]]) == 0)
      return(NULL)
    rel[[1]]
}

"sqliteResultInfo" <-
function(obj, what = "", ...)
{
  if(!isIdCurrent(obj))
    stop(paste("expired", class(obj)))
   id <- obj@Id
   info <- .Call("RS_SQLite_resultSetInfo", id, PACKAGE = .SQLitePkgName)
   flds <- info$fieldDescription[[1]]
   if(!is.null(flds)){
       flds$Sclass <- .Call("RS_DBI_SclassNames", flds$Sclass,
                            PACKAGE = .SQLitePkgName)
       flds$type <- .Call("RS_SQLite_typeNames", flds$type,
                            PACKAGE = .SQLitePkgName)
       ## no factors
       info$fields <- structure(flds, row.names = paste(seq(along.with=flds$type)),
                                class="data.frame")
   }
   if(!missing(what))
     info[what]
   else
     info
}

"sqliteDescribeResult" <-
function(obj, verbose = FALSE, ...)
{
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

"sqliteCloseResult" <-
function(res, ...)
{
  if(!isIdCurrent(res)){
     warning(paste("expired SQLiteResult"))
     return(TRUE)
  }
  .Call("RS_SQLite_closeResultSet", res@Id, PACKAGE = .SQLitePkgName)
}

"sqliteTableFields" <-
function(con, name, ...)
{
   if(length(dbListResults(con))>0){
      con2 <- dbConnect(con)
      on.exit(dbDisconnect(con2))
   }
   else
      con2 <- con
   rs <- dbSendQuery(con2, paste("select * from ", name, "limit 1"))
   dummy <- fetch(rs, n = 1)
   dbClearResult(rs)
   nms <- names(dummy)
   if(is.null(nms))
      character()
   else
      nms
}
## this is exactly the same as ROracle's oraReadTable
"sqliteReadTable" <-
function(con, name, row.names = "row_names", check.names = TRUE, ...)
## Should we also allow row.names to be a character vector (as in read.table)?
## is it "correct" to set the row.names of output data.frame?
## Use NULL, "", or 0 as row.names to prevent using any field as row.names.
{
   out <- try(dbGetQuery(con, paste("SELECT * from", name)))
   if(inherits(out, ErrorClass))
      stop(paste("could not find table", name))
   if(check.names)
       names(out) <- make.names(names(out), unique = TRUE)
   ## should we set the row.names of the output data.frame?
   nms <- names(out)
   j <- switch(mode(row.names),
           character = if(row.names=="") 0 else
               match(tolower(row.names), tolower(nms),
                     nomatch = if(missing(row.names)) 0 else -1),
           numeric=, logical = row.names,
           NULL = 0,
           0)
   if(as.numeric(j)==0)
      return(out)
   if(is.logical(j)) ## Must be TRUE
      j <- match(row.names, tolower(nms), nomatch=0)
   if(j<1 || j>ncol(out)){
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

"dbBuildTableDefinition" <-
function(dbObj, name, value, field.types = NULL, row.names = TRUE, ...)
{
  if(!is.data.frame(value))
    value <- as.data.frame(value)
  if(!is.null(row.names) && row.names){
    value  <- cbind(row.names(value), value)  ## can't use row.names= here
    names(value)[1] <- "row.names"
  }
  if(is.null(field.types)){
    ## the following mapping should be coming from some kind of table
    ## also, need to use converter functions (for dates, etc.)
    field.types <- sapply(value, dbDataType, dbObj = dbObj)
  }
  i <- match("row.names", names(field.types), nomatch=0)
  if(i>0) ## did we add a row.names value?  If so, it's a text field.
    field.types[i] <- dbDataType(dbObj, field.types[["row.names"]])
  names(field.types) <-
    make.db.names(dbObj, names(field.types), allow.keywords = FALSE)

  ## need to create a new (empty) table
  flds <- paste(names(field.types), field.types)
  paste("CREATE TABLE", name, "\n(", paste(flds, collapse=",\n\t"), "\n)")
}

"sqliteImportFile" <-
function(con, name, value, field.types = NULL, overwrite = FALSE,
  append = FALSE, header, row.names, nrows = 50, sep = ",",
  eol="\n", skip = 0, ...)
{
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
    flds <- count.fields(txtcon, sep)
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

sqliteWriteTable <- function(con, name, value, row.names=TRUE,
                              overwrite=FALSE, append=FALSE,
                              field.types=NULL, ...)
{
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

## from ROracle, except we don't quote strings here.
"safe.write" <-
function(value, file, batch, row.names = TRUE, ...,
  sep = ',', eol = '\n', quote.string = FALSE)
## safe.write makes sure write.table don't exceed available memory by batching
## at most batch rows (but it is still slowww)
{
   N <- nrow(value)
   if(N<1){
      warning("no rows in data.frame")
      return(NULL)
   }
   if(missing(batch) || is.null(batch))
      batch <- 10000
   else if(batch<=0)
      batch <- N
   from <- 1
   to <- min(batch, N)
   while(from<=N){
     write.table(value[from:to,, drop=FALSE], file = file,
        append = from>1,
        quote = quote.string, sep=sep, na = .SQLite.NA.string,
        row.names=row.names, col.names=(from==1), eol = eol, ...)
      from <- to+1
      to <- min(to+batch, N)
   }
   invisible(NULL)
}

##
## Utilities
##
"sqliteDataType" <- function(obj, ...)
{
  rs.class <- data.class(obj)
  rs.mode <- storage.mode(obj)
  if(rs.class=="numeric"){
    sql.type <- if(rs.mode=="integer") "INTEGER" else  "REAL"
  }
  else {
    sql.type <- switch(rs.class,
                  character = "TEXT",
                  logical = "INTEGER",
                  factor = "TEXT",	## up to 65535 characters
                  ordered = "TEXT",
                  "TEXT")
    if (is.list(obj)) sql.type <- "BLOB"
  }
  sql.type
}

sqliteCopyDatabase <- function(from, to)
{
    if (!is(from, "SQLiteConnection"))
        stop("'from' must be a SQLiteConnection object")
    destdb <- to
    if (!is(to, "SQLiteConnection")) {
        if (is.character(to) && length(to) == 1L && !is.na(to) && nzchar(to)) {
            if (":memory:" == to)
                stop("invalid file name for 'to'.  Use a SQLiteConnection",
                     " object to copy to an in-memory database")
            destdb <- dbConnect(SQLite(), dbname = path.expand(to))
            on.exit(dbDisconnect(destdb))
        } else {
            stop("'to' must be SQLiteConnection object or a non-empty string")
        }
    }
    .Call("RS_SQLite_copy_database", from@Id, destdb@Id, PACKAGE = .SQLitePkgName)
    invisible(NULL)
}
