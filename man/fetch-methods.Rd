% $Id$
\name{fetch-methods}
\docType{methods}
\alias{fetch-methods}
\alias{fetch,SQLiteResult,numeric-method}
\alias{fetch,SQLiteResult-method}
\title{
  Fetch records from a previously executed query
}
\description{
   This method is a straight-forward implementation of the corresponding
   generic function.
}
\section{Methods}{\describe{

\item{res}{
  an \code{SQLiteResult} object.
  }
\item{n}{
  maximum number of records to retrieve per fetch.
  Use \code{n = -1} to retrieve all pending records;
  use a value of \code{n = 0} for fetching the default number 
  of rows \code{fetch.default.rec} defined in the 
  \code{\link{SQLite}} initialization invocation.
  }
\item{\dots }{currently not used.}
}
}
\details{
  The \code{RSQLite} implementations retrieves all records into a 
  buffer internally managed by the RSQLite driver (thus this memory
  in not managed by R but its part of the R process), and
  \code{fetch} simple returns records from this internal buffer.
}
\references{
  See the Database Interface definition document
  \code{DBI.pdf} in the base directory of this package
  or \url{http://stat.bell-labs.com/RS-DBI}.
}
\seealso{
  \code{\link{SQLite}},
  \code{\link[DBI]{dbConnect}},
  \code{\link[DBI]{dbSendQuery}},
  \code{\link[DBI]{dbGetQuery}},
  \code{\link[DBI]{dbClearResult}},
  \code{\link[DBI]{dbCommit}},
  \code{\link[DBI]{dbGetInfo}},
  \code{\link[DBI]{dbReadTable}}.
}
\examples{
drv <- dbDriver("SQLite")
tfile <- tempfile()
con <- dbConnect(drv, dbname = tfile)
data(USJudgeRatings)
dbWriteTable(con, "jratings", USJudgeRatings)

res <- dbSendQuery(con, statement = paste(
                      "SELECT row_names, ORAL, DILG, FAMI",
                      "FROM jratings"))

# we now fetch the first 10 records from the resultSet into a data.frame
data1 <- fetch(res, n = 10)   
dim(data1)

dbHasCompleted(res)

# let's get all remaining records
data2 <- fetch(res, n = -1)

dbClearResult(res)
dbDisconnect(con)
}
\keyword{methods}
\keyword{interface}
\keyword{database}
% vim: syntax=tex
