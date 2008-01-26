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
  Execute a SQL statement on a database connection
}
\description{
   These are the primary methods for interacting with a database via SQL
   queries.
}
\section{Methods}{\describe{
\item{conn}{a \code{SQLiteConnection} object.}
\item{statement}{a character vector of length one specifying the SQL
statement that should be executed.  Only a single SQL statment should be
provided.}
\item{res}{a \code{SQLiteResult} object.}
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
\examples{
con <- dbConnect(SQLite(), ":memory:")
data(USArrests)
dbWriteTable(con, "arrests", USArrests)

res <- dbSendQuery(con, "SELECT * from arrests")
data <- fetch(res, n = 2)
data
dbClearResult(res)

dbGetQuery(con, "SELECT * from arrests limit 3")

tryCatch(dbGetQuery(con, "SELECT * FROM tableDoesNotExist"),
         error=function(e) { print("caught") })
dbGetException(con)

}
\keyword{methods}
\keyword{interface}
\keyword{database}
% vim: syntax=tex
