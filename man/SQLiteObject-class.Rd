\docType{class}
\name{SQLiteObject-class}
\alias{SQLiteObject-class}
\title{Class SQLiteObject}
\description{
  Base class for all SQLite-specific DBI classes
}
\examples{
\dontrun{
drv <- dbDriver("SQLite")
con <- dbConnect(drv, dbname = "rsdbi.db")
}
}

