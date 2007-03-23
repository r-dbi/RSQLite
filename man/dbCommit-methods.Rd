% $Id$
\name{dbCommit-methods}
\docType{methods}
\alias{dbBeginTransaction}
\alias{dbBeginTransaction-methods}
\alias{dbCommit-methods}
\alias{dbRollback-methods}
\alias{dbBeginTransaction,SQLiteConnection-method}
\alias{dbCommit,SQLiteConnection-method}
\alias{dbRollback,SQLiteConnection-method}
\title{
  DBMS Transaction Management
}
\description{
  By default, SQLite is in auto-commit mode. \code{dbBeginTransaction}
  starts a SQLite transaction and turns auto-commit
  off. \code{dbCommit} and \code{dbRollback} commit and rollback the
  transaction, respectively and turn auto-commit on.

}
\section{Methods}{\describe{
\item{conn}{
  a \code{SQLiteConnection} object, as produced by the function 
  \code{dbConnect}.
  }
\item{\dots }{
  any database-specific arguments.
  }
}
}
\references{
  See the Database Interface definition document
  \code{DBI.pdf} in the base directory of this package
  or
  \url{http://stat.bell-labs.com/RS-DBI}.
}
\seealso{
   \code{\link{SQLite}},
   \code{\link[DBI]{dbConnect}},
   \code{\link[DBI]{dbSendQuery}},
   \code{\link[DBI]{dbGetQuery}},
   \code{\link[DBI]{fetch}},
   \code{\link[DBI]{dbCommit}},
   \code{\link[DBI]{dbGetInfo}},
   \code{\link[DBI]{dbReadTable}}.
}
\examples{
drv <- dbDriver("SQLite")
tfile <- tempfile()
con <- dbConnect(drv, dbname = tfile)
data(USArrests)
dbWriteTable(con, "arrests", USArrests)
dbGetQuery(con, "select count(*) from arrests")[1, ]

dbBeginTransaction(con)
rs <- dbSendQuery(con, "DELETE from arrests WHERE Murder > 1")
dbGetQuery(con, "select count(*) from arrests")[1, ]
if (dbGetInfo(rs)[["rowsAffected"]] > 40)
  dbRollback(con)
dbGetQuery(con, "select count(*) from arrests")[1, ]

dbBeginTransaction(con)
rs <- dbSendQuery(con, "DELETE from arrests WHERE Murder > 5")
dbCommit(con)
dbGetQuery(con, "select count(*) from arrests")[1, ]


dbDisconnect(con)
}
\keyword{methods}
\keyword{interface}
\keyword{database}
% vim: syntax=tex
