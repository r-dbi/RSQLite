\docType{class}
\name{SQLiteConnection-class}
\alias{SQLiteConnection-class}
\title{Class SQLiteConnection}
\description{
  SQLite connection class.
}
\section{Generators}{
  The method \code{\link[DBI]{dbConnect}} is the main
  generator.
}
\examples{
drv <- dbDriver("SQLite")
tfile <- tempfile()
con <- dbConnect(drv, dbname = tfile)
dbDisconnect(con)
dbUnloadDriver(drv)
}

