\name{sqlite-meta}
\alias{dbColumnInfo,SQLiteResult-method}
\alias{dbGetInfo,SQLiteResult-method}
\alias{dbGetRowCount,SQLiteResult-method}
\alias{dbGetRowsAffected,SQLiteResult-method}
\alias{dbGetStatement,SQLiteResult-method}
\alias{dbHasCompleted,SQLiteResult-method}
\alias{sqlite-meta}
\alias{sqliteDescribeResult}
\alias{summary,SQLiteResult-method}
\title{Database interface meta-data.}
\usage{
  \S4method{dbGetInfo}{SQLiteResult}(dbObj, ...)

  \S4method{dbGetStatement}{SQLiteResult}(res, ...)

  \S4method{dbColumnInfo}{SQLiteResult}(res, ...)

  \S4method{dbGetRowsAffected}{SQLiteResult}(res, ...)

  \S4method{dbGetRowCount}{SQLiteResult}(res, ...)

  \S4method{dbHasCompleted}{SQLiteResult}(res, ...)

  \S4method{summary}{SQLiteResult}(object, ...)

  sqliteDescribeResult(obj, verbose = FALSE, ...)
}
\arguments{
  \item{obj,dbObj,res}{An object of class
  \code{\linkS4class{SQLiteResult}}}

  \item{...}{Ignored. Needed for compatibility with
  generic}
}
\description{
  See documentation of generics for more details.
}
\examples{
data(USArrests)
drv <- dbDriver("SQLite")
con <- dbConnect(drv, dbname=":memory:")
dbWriteTable(con, "t1", USArrests)
dbWriteTable(con, "t2", USArrests)

dbListTables(con)

rs <- dbSendQuery(con, "select * from t1 where UrbanPop >= 80")
dbGetStatement(rs)
dbHasCompleted(rs)

info <- dbGetInfo(rs)
names(info)
info$fields

fetch(rs, n=2)
dbHasCompleted(rs)
info <- dbGetInfo(rs)
info$fields
dbClearResult(rs)

names(dbGetInfo(drv))

# DBIConnection info
names(dbGetInfo(con))

dbDisconnect(con)
}

