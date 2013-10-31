\name{dbGetInfo,SQLiteConnection-method}
\alias{dbGetInfo,SQLiteConnection-method}
\alias{sqliteConnectionInfo}
\title{Get metadata about a connection.}
\usage{
  \S4method{dbGetInfo}{SQLiteConnection}(dbObj, ...)

  sqliteConnectionInfo(obj, what = "", ...)
}
\arguments{
  \item{dbObj,obj}{An \code{\linkS4class{SQLiteConnection}}
  object}

  \item{what}{character vector. If supplied used to subset
  output.}

  \item{...}{Ignored. Included for compatibility with
  generic.}
}
\description{
  Get metadata about a connection.
}

