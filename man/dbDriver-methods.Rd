% $Id$
\name{dbDriver-methods}
\docType{methods}
\alias{dbDriver-methods}
\alias{dbUnloadDriver-methods}
\alias{dbDriver,character-method}
\alias{dbUnloadDriver,SQLiteDriver-method}
\title{
  SQLite implementation of the Database Interface (DBI) classes 
  and drivers 
}
\description{
  SQLite driver initialization and closing
}
\section{Methods}{\describe{
\item{drvName}{
  character name of the driver to instantiate.
  }
\item{drv}{
  an object that inherits from \code{SQLiteDriver} as created by
  \code{dbDriver}.
}
\item{\dots}{
  any other arguments are passed to the driver \code{drvName}.
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
  \code{\link[DBI]{dbListTables}},
  \code{\link[DBI]{dbReadTable}}.
}
\examples{\dontrun{
# create an SQLite instance for capacity of up to 25 simultaneous
# connections.
m <- dbDriver("SQLite", max.con = 25)

con <- dbConnect(m, dbname="sqlite.db")
rs <- dbSubmitQuery(con, 
         "select * from HTTP_ACCESS where IP_ADDRESS = '127.0.0.1'")
df <- fetch(rs, n = 50)
df2 <- fetch(rs, n = -1)
dbClearResult(rs)

pcon <- dbConnect(p, "user", "password", "dbname")
dbListTables(pcon)
}
}
\keyword{methods}
\keyword{interface}
\keyword{database}
% vim: syntax=tex
