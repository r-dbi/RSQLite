% $Id$
\name{dbDataType-methods}
\docType{methods}
\alias{dbDataType-methods}
\alias{dbDataType,SQLiteObject-method}
\title{
  Determine the SQL Data Type of an S object
}
\description{
   This method is a straight-forward implementation of the corresponding
   generic function.
}
\section{Methods}{\describe{
\item{dbObj}{
  a \code{SQLiteDriver} object, e.g., \code{ODBCDriver},
  \code{OracleDriver}.
  }
\item{obj}{
  R/S-Plus object whose SQL type we want to determine.
  }
\item{\dots }{
  any other parameters that individual methods may need.
  }
}
}
\references{
  See the Database Interface definition document
  \code{DBI.pdf} in the base directory of this package
  or \url{http://stat.bell-labs.com/RS-DBI}.
}
\seealso{
  \code{\link[DBI]{isSQLKeyword}}
  \code{\link[DBI]{make.db.names}}
}
\examples{\dontrun{
data(quakes)
drv <- dbDriver("SQLite")
sql.type <- dbDataType(drv, quakes)
}
}
\keyword{methods}
\keyword{interface}
\keyword{database}
% docclass is function
% Converted by Sd2Rd version 1.15.2.1.
% vim: syntax=tex
