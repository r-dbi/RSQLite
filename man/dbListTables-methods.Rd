% $Id$
\name{dbListTables-methods}
\docType{methods}
\alias{dbListTables-methods}
\alias{dbListFields-methods}
\alias{dbListConnections-methods}
\alias{dbListResults-methods}
\alias{dbListTables,SQLiteConnection-method}
\alias{dbListFields,SQLiteConnection,character-method}
\alias{dbListConnections,SQLiteDriver-method}
\alias{dbListResults,SQLiteConnection-method}
\title{
  List items from an SQLite DBMS and from objects 
}
\description{
   These methods are straight-forward implementations of the corresponding
   generic functions.
}
\section{Methods}{\describe{
  \item{drv}{an \code{SQLiteDriver}.}
  \item{conn}{an \code{SQLiteConnection}.}
  \item{name}{a character string with the table name.}
  \item{\dots}{currently not used.}
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
  \code{\link[DBI]{dbGetInfo}},
  \code{\link[DBI]{dbColumnInfo}},
  \code{\link[DBI]{dbDriver}},
  \code{\link[DBI]{dbConnect}},
  \code{\link[DBI]{dbSendQuery}}
}

\examples{\dontrun{
drv <- dbDriver("SQLite")
# after working awhile...
for(con in dbListConnections(odbc)){
   dbGetStatement(dbListResults(con))
}
}
}
\keyword{methods}
\keyword{interface}
\keyword{database}
% vim: syntax=tex
