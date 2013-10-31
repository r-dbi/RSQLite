\docType{methods}
\name{dbDataType}
\alias{dbDataType}
\alias{dbDataType,SQLiteObject-method}
\title{Determine the SQL Data Type of an S object.}
\description{
  This method is a straight-forward implementation of the
  corresponding generic function.
}
\section{Methods}{
  \describe{ \item{dbObj}{ a \code{SQLiteDriver} object,
  e.g., \code{ODBCDriver}, \code{OracleDriver}.  }
  \item{obj}{ R/S-Plus object whose SQL type we want to
  determine.  } \item{list()}{ any other parameters that
  individual methods may need.  }\item{ }{ any other
  parameters that individual methods may need.  } }
}
\examples{
data(quakes)
drv <- dbDriver("SQLite")
sapply(quakes, function(x) dbDataType(drv, x))

dbDataType(drv, 1)
dbDataType(drv, as.integer(1))
dbDataType(drv, "1")
dbDataType(drv, charToRaw("1"))
}

