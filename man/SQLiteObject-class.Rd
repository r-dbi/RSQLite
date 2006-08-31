% $Id$
\name{SQLiteObject-class}
\docType{class}
\alias{SQLiteObject-class}
\title{Class SQLiteObject}
\description{
   Base class for all SQLite-specific DBI classes
}
\section{Objects from the Class}{
   A virtual Class: No objects may be created from it.
}
\section{Extends}{
Class \code{"DBIObject"}, directly.
Class \code{"dbObjectId"}, directly.
}
\section{Methods}{
  \describe{
    \item{\link{coerce}}{\code{signature(from = "SQLiteObject", to = "SQLiteDriver")}: ... }
    \item{\link[DBI]{dbDataType}}{\code{signature(dbObj = "SQLiteObject")}: ... }
    \item{\link[DBI]{isSQLKeyword}}{\code{signature(dbObj = "SQLiteObject", name = "character")}: ... }
    \item{\link[DBI]{make.db.names}}{\code{signature(dbObj = "SQLiteObject", snames = "character")}: ... }
    \item{\link[DBI]{SQLKeywords}}{\code{signature(dbObj = "SQLiteObject")}: ... }
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
con <- dbConnect(drv, dbname = "rsdbi.db")
}
}
\keyword{database}
\keyword{interface}
\keyword{classes}
% vim: syntax=tex
