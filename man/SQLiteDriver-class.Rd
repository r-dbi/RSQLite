% $Id$
\name{SQLiteDriver-class}
\docType{class}
\alias{SQLiteDriver-class}
\title{Class SQLiteDriver}
\description{
   An SQLite driver implementing the R/S-Plus database (DBI) API.
}
\section{Generators}{
   The main generators are \code{\link[DBI]{dbDriver}} and 
   \code{\link{SQLite}}.
}
\section{Extends}{
Class \code{"DBIDriver"}, directly.
Class \code{"SQLiteObject"}, directly.
Class \code{"DBIObject"}, by class "DBIDriver".
Class \code{"dbObjectId"}, by class "SQLiteObject".
}
\section{Methods}{
  \describe{
    \item{\link{coerce}}{\code{signature(from = "SQLiteObject", to = "SQLiteDriver")}: ... }
    \item{\link[DBI]{dbConnect}}{\code{signature(drv = "SQLiteDriver")}: ... }
    \item{\link[DBI]{dbGetInfo}}{\code{signature(dbObj = "SQLiteDriver")}: ... }
    \item{\link[DBI]{dbListConnections}}{\code{signature(drv = "SQLiteDriver")}: ... }
    \item{\link[DBI]{dbUnloadDriver}}{\code{signature(drv = "SQLiteDriver")}: ... }
    \item{\link{summary}}{\code{signature(object = "SQLiteDriver")}: ... }
  }
}
\references{
  See the Database Interface definition document
  \code{DBI.pdf} in the base directory of this package
  or \url{http://stat.bell-labs.com/RS-DBI}.
}
\author{R-SIG-DB}

\seealso{
 DBI classes:
 \code{\link{SQLiteObject-class}}
 \code{\link{SQLiteDriver-class}}
 \code{\link{SQLiteConnection-class}}
 \code{\link{SQLiteResult-class}}
}

\examples{\dontrun{
drv <- dbDriver("SQLite")
con <- dbConnect(drv, dbname="path/to/dbfile")
}
}
\keyword{database}
\keyword{interface}
\keyword{classes}
% vim: syntax=tex
