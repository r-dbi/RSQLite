\docType{class}
\name{SQLiteDriver-class}
\alias{SQLiteDriver-class}
\title{Class SQLiteDriver}
\description{
  An SQLite driver implementing the R/S-Plus database (DBI)
  API.
}
\section{Generators}{
  The main generators are \code{\link[DBI]{dbDriver}} and
  \code{\link{SQLite}}. \dontrun{ drv <- dbDriver("SQLite")
  con <- dbConnect(drv, dbname="path/to/dbfile") }
}

