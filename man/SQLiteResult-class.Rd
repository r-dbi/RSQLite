% $Id$
\name{SQLiteResult-class}
\docType{class}
\alias{SQLiteResult-class}
\title{Class SQLiteResult}
\description{
   SQLite's query results class.  This classes encapsulates the
   result of an SQL statement (either \code{select} or not).
}
\section{Generators}{
   The main generator is \code{\link[DBI]{dbSendQuery}}.
}
\section{Extends}{
Class \code{"DBIResult"}, directly.
Class \code{"SQLiteObject"}, directly.
Class \code{"DBIObject"}, by class "DBIResult".
Class \code{"dbObjectId"}, by class "SQLiteObject".
}
\section{Methods}{
  \describe{
    \item{\link{coerce}}{\code{signature(from = "SQLiteConnection", to = "SQLiteResult")}: ... }
    \item{\link[DBI]{dbClearResult}}{\code{signature(res = "SQLiteResult")}: ... }
    \item{\link[DBI]{dbColumnInfo}}{\code{signature(res = "SQLiteResult")}: ... }
    \item{\link[DBI]{dbGetException}}{\code{signature(conn = "SQLiteResult")}: ... }
    \item{\link[DBI]{dbGetInfo}}{\code{signature(dbObj = "SQLiteResult")}: ... }
    \item{\link[DBI]{dbGetRowCount}}{\code{signature(res = "SQLiteResult")}: ... }
    \item{\link[DBI]{dbGetRowsAffected}}{\code{signature(res = "SQLiteResult")}: ... }
    \item{\link[DBI]{dbGetStatement}}{\code{signature(res = "SQLiteResult")}: ... }
    \item{\link[DBI]{dbHasCompleted}}{\code{signature(res = "SQLiteResult")}: ... }
    \item{\link[DBI]{dbListFields}}{\code{signature(conn = "SQLiteResult", name = "missing")}: ... }
    \item{\link[DBI]{fetch}}{\code{signature(res = "SQLiteResult", n = "numeric")}: ... }
    \item{\link[DBI]{fetch}}{\code{signature(res = "SQLiteResult", n = "missing")}: ... }
    \item{\link{summary}}{\code{signature(object = "SQLiteResult")}: ... }
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

\keyword{database}
\keyword{interface}
\keyword{classes}
% vim: syntax=tex
