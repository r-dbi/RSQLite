% $Id$
\name{dbSendQuery-methods}
\docType{methods}
\alias{dbSendQuery-methods}
\alias{dbGetQuery-methods}
\alias{dbSendPreparedQuery}
\alias{dbGetPreparedQuery}
\alias{dbSendPreparedQuery-methods}
\alias{dbGetPreparedQuery-methods}
\alias{dbGetException-methods}
\alias{dbSendQuery,SQLiteConnection,character-method}
\alias{dbGetQuery,SQLiteConnection,character-method}
\alias{dbSendPreparedQuery,SQLiteConnection,character,data.frame-method}
\alias{dbGetPreparedQuery,SQLiteConnection,character,data.frame-method}
\alias{dbClearResult,SQLiteResult-method}
\alias{dbGetException,SQLiteConnection-method}
\title{
  Execute a statement on a given database connection
}
\description{
   These methods are straight-forward implementations of the corresponding
   generic functions.
   
   The prepared variants take an extra data.frame, which performs parameter
   binding.
}
\section{Methods}{\describe{
\item{conn}{
  an \code{SQLiteConnection} object.
  }
\item{statement}{a character vector of length 1 with the SQL statement.}
\item{res}{an \code{SQLiteResult} object.}
\item{\dots }{additional parameters.}
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
  \code{\link[DBI]{fetch}},
  \code{\link[DBI]{dbCommit}},
  \code{\link[DBI]{dbGetInfo}},
  \code{\link[DBI]{dbReadTable}}.
}
\examples{\dontrun{
drv <- dbDriver("MySQL")
con <- dbConnect(drv)
res <- dbSendQuery(con, "SELECT * from liv25")
data <- fetch(res, n = -1)
}
}
\keyword{methods}
\keyword{interface}
\keyword{database}
% vim: syntax=tex
