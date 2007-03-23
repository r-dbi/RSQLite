% $Id$
\name{dbGetInfo-methods}
\docType{methods}
\alias{dbGetInfo}
\alias{dbGetDBIVersion-methods}
\alias{dbGetStatement-methods}
\alias{dbGetRowCount-methods}
\alias{dbGetRowsAffected-methods}
\alias{dbColumnInfo-methods}
\alias{dbHasCompleted-methods}
\alias{dbGetInfo,SQLiteObject-method}
\alias{dbGetInfo,SQLiteDriver-method}        % BUG: this is not needed
\alias{dbGetInfo,SQLiteConnection-method}        % BUG: this is not needed
\alias{dbGetInfo,SQLiteResult-method}        % BUG: this is not needed
\alias{dbGetStatement,SQLiteResult-method}
\alias{dbGetRowCount,SQLiteResult-method}
\alias{dbGetRowsAffected,SQLiteResult-method}
\alias{dbColumnInfo,SQLiteResult-method}
\alias{dbHasCompleted,SQLiteResult-method}
\title{
  Database interface meta-data
}
\description{
   These methods are straight-forward implementations of the corresponding
   generic functions.
}
\section{Methods}{\describe{
\item{dbObj}{
  any object that implements some functionality in the R/S-Plus
  interface to databases (a driver, a connection or a result set).
  }
%\item{drv}{an \code{SQLiteDriver}.}
%\item{conn}{an \code{SQLiteConnection}.}
\item{res}{ an \code{SQLiteResult}.}
\item{\dots}{currently not being used.}
}
}
\references{
  See the Database Interface definition document
  \code{DBI.pdf} in the base directory of this package
  or \url{http://stat.bell-labs.com/RS-DBI}.
}
\seealso{
  \code{\link{SQLite}},
  \code{\link[DBI]{dbDriver}},
  \code{\link[DBI]{dbConnect}},
  \code{\link[DBI]{dbSendQuery}},
  \code{\link[DBI]{dbGetQuery}},
  \code{\link[DBI]{fetch}},
  \code{\link[DBI]{dbCommit}},
  \code{\link[DBI]{dbGetInfo}},
  \code{\link[DBI]{dbListTables}},
  \code{\link[DBI]{dbReadTable}}.
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

\keyword{methods}
\keyword{interface}
\keyword{database}
% vim: syntax=tex
