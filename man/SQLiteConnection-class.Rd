% $Id$
\name{SQLiteConnection-class}
\docType{class}
\alias{SQLiteConnection-class}
\title{Class SQLiteConnection}
\description{SQLite connection class.}
\section{Generators}{
    The method \code{\link[DBI]{dbConnect}} is the main generator.
}
\section{Extends}{
Class \code{"DBIConnection"}, directly.
Class \code{"SQLiteObject"}, directly.
Class \code{"DBIObject"}, by class "DBIConnection".
Class \code{"dbObjectId"}, by class "SQLiteObject".
}
\section{Methods}{
  \describe{
    \item{\link{coerce}}{\code{signature(from = "SQLiteConnection", to = "SQLiteResult")}: ... }
    \item{\link[DBI]{dbCallProc}}{\code{signature(conn = "SQLiteConnection")}: ... }
    \item{\link[DBI]{dbCommit}}{\code{signature(conn = "SQLiteConnection")}: ... }
    \item{\link[DBI]{dbConnect}}{\code{signature(drv = "SQLiteConnection")}: ... }
    \item{\link[DBI]{dbDisconnect}}{\code{signature(conn = "SQLiteConnection")}: ... }
    \item{\link[DBI]{dbExistsTable}}{\code{signature(conn = "SQLiteConnection", name = "character")}: ... }
    \item{\link[DBI]{dbGetException}}{\code{signature(conn = "SQLiteConnection")}: ... }
    \item{\link[DBI]{dbGetInfo}}{\code{signature(dbObj = "SQLiteConnection")}: ... }
    \item{\link[DBI]{dbGetQuery}}{\code{signature(conn = "SQLiteConnection", statement = "character")}: ... }
    \item{\link[DBI]{dbListFields}}{\code{signature(conn = "SQLiteConnection", name = "character")}: ... }
    \item{\link[DBI]{dbListResults}}{\code{signature(conn = "SQLiteConnection")}: ... }
    \item{\link[DBI]{dbListTables}}{\code{signature(conn = "SQLiteConnection")}: ... }
    \item{\link[DBI]{dbReadTable}}{\code{signature(conn = "SQLiteConnection", name = "character")}: ... }
    \item{\link[DBI]{dbRemoveTable}}{\code{signature(conn = "SQLiteConnection", name = "character")}: ... }
    \item{\link[DBI]{dbRollback}}{\code{signature(conn = "SQLiteConnection")}: ... }
    \item{\link[DBI]{dbSendQuery}}{\code{signature(conn = "SQLiteConnection", statement = "character")}: ... }
    \item{\link[DBI]{dbWriteTable}}{\code{signature(conn = "SQLiteConnection", name = "character", value = "data.frame")}: ... }
    \item{summary}{\code{signature(object = "SQLiteConnection")}: ... }
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

\examples{
drv <- dbDriver("SQLite")
tfile <- tempfile()
con <- dbConnect(drv, dbname = tfile)
dbDisconnect(con)
dbUnloadDriver(drv)
}
\keyword{database}
\keyword{interface}
\keyword{classes}
% vim: syntax=tex
