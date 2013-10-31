\docType{class}
\name{SQLiteConnection-class}
\alias{SQLiteConnection-class}
\title{Class SQLiteConnection}
\description{
  \code{SQLiteConnection} objects are usually created by
  \code{\link[DBI]{dbConnect}}
}
\examples{
con <- dbConnect(SQLite(), dbname = tempfile())
dbDisconnect(con)
dbUnloadDriver(drv)
}

