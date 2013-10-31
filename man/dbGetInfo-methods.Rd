\docType{methods}
\name{dbGetInfo-methods}
\alias{dbColumnInfo,SQLiteResult-method}
\alias{dbColumnInfo-methods}
\alias{dbGetDBIVersion-methods}
\alias{dbGetInfo}
\alias{dbGetInfo,SQLiteConnection-method}
\alias{dbGetInfo,SQLiteDriver-method}
\alias{dbGetInfo,SQLiteObject-method}
\alias{dbGetInfo,SQLiteResult-method}
\alias{dbGetInfo-methods}
\alias{dbGetRowCount,SQLiteResult-method}
\alias{dbGetRowCount-methods}
\alias{dbGetRowsAffected,SQLiteResult-method}
\alias{dbGetRowsAffected-methods}
\alias{dbGetStatement,SQLiteResult-method}
\alias{dbGetStatement-methods}
\alias{dbHasCompleted,SQLiteResult-method}
\alias{dbHasCompleted-methods}
\title{Database interface meta-data}
\description{
  These methods are straight-forward implementations of the
  corresponding generic functions.
}
\section{Methods}{
  \describe{ \item{dbObj}{ any object that implements some
  functionality in the R/S-Plus interface to databases (a
  driver, a connection or a result set).  } %\item{drv}{an
  \code{SQLiteDriver}.} %\item{conn}{an
  \code{SQLiteConnection}.} \item{res}{ an
  \code{SQLiteResult}.} \item{list()}{currently not being
  used.} }
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

