% $Id$
\name{dbCommit-methods}
\docType{methods}
\alias{dbCommit-methods}
\alias{dbRollback-methods}
\alias{dbCommit,SQLiteConnection-method}
\alias{dbRollback,SQLiteConnection-method}
\title{
  DBMS Transaction Management
}
\description{
   Not yet implemented.
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
\examples{\dontrun{
drv <- dbDriver("SQLite")
con <- dbConnect(drv, dbname = "mySQLite.db")
rs <- dbSendQuery(con, 
      "delete * from PURGE as p where p.wavelength<0.03")
if(dbGetInfo(rs, what = "rowsAffected") > 250){
  warning("dubious deletion -- rolling back transaction")
  dbRollback(con)
}
}
}
\keyword{methods}
\keyword{interface}
\keyword{database}
% vim: syntax=tex
