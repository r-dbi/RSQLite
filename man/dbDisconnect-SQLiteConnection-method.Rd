\docType{methods}
\name{dbDisconnect,SQLiteConnection-method}
\alias{dbDisconnect,SQLiteConnection-method}
\alias{sqliteCloseConnection}
\title{Disconnect an SQLite connection.}
\usage{
\S4method{dbDisconnect}{SQLiteConnection}(conn, ...)

sqliteCloseConnection(con, ...)
}
\arguments{
  \item{conn,con}{An existing
  \code{\linkS4class{SQLiteConnection}}}

  \item{...}{Ignored. Included for compatibility with
  generic.}
}
\description{
Disconnect an SQLite connection.
}

