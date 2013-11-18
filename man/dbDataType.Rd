\docType{methods}
\name{dbDataType}
\alias{dbDataType}
\alias{dbDataType,SQLiteConnection-method}
\alias{dbDataType,SQLiteDriver-method}
\alias{dbDataType,SQLiteResult-method}
\alias{sqliteDataType}
\title{Determine the SQL Data Type of an R object.}
\usage{
\S4method{dbDataType}{SQLiteDriver}(dbObj, obj, ...)

\S4method{dbDataType}{SQLiteConnection}(dbObj, obj, ...)

\S4method{dbDataType}{SQLiteResult}(dbObj, obj, ...)

sqliteDataType(obj, ...)
}
\arguments{
  \item{dbObj}{a \code{SQLiteDriver} object,}

  \item{obj}{an R object whose SQL type we want to
  determine.}

  \item{...}{Needed for compatibility with generic.
  Otherwise ignored.}
}
\description{
  This method is a straight-forward implementation of the
  corresponding generic function.
}
\examples{
data(quakes)
drv <- SQLite()

sapply(quakes, function(x) dbDataType(drv, x))

dbDataType(drv, 1)
dbDataType(drv, as.integer(1))
dbDataType(drv, "1")
dbDataType(drv, charToRaw("1"))
}

