sqliteQuickColumn <- function(con, table, column) {
  .Call("RS_SQLite_quick_column", con@Id, as.character(table),
    as.character(column), PACKAGE="RSQLite")
}

sqliteFetchOneColumn <- function(con, statement, n=0, ...) {
  rs <- dbSendQuery(con, statement)
  on.exit(dbClearResult(rs))
  n <- as.integer(n)
  rsId <- rs@Id
  rel <- .Call("RS_SQLite_fetch", rsId, nrec = n, PACKAGE = .SQLitePkgName)
  if (length(rel) == 0 || length(rel[[1]]) == 0)
    return(NULL)
  rel[[1]]
}

sqliteResultInfo <- function(obj, what = "", ...) {
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

## from ROracle, except we don't quote strings here.
## safe.write makes sure write.table don't exceed available memory by batching
## at most batch rows (but it is still slowww)
#' @export
safe.write <- function(value, file, batch, row.names = TRUE, ..., sep = ',',
  eol = '\n', quote.string = FALSE) {
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

#' @export
sqliteCopyDatabase <- function(from, to) {
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
