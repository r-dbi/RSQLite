% $Id$
\name{dbConnect-methods}
\docType{methods}
\alias{dbDisconnect-methods}
\alias{dbConnect-methods}
\alias{dbDisconnect,SQLiteConnection-method}
\alias{dbConnect,SQLiteDriver-method}
\alias{dbConnect,SQLiteConnection-method}
\alias{dbConnect,character-method}
\title{
  Create a connection object to an SQLite DBMS
}
\description{
   These methods are straight-forward implementations of the corresponding
   generic functions.
}
\section{Methods}{\describe{
\item{drv}{
  an object of class \code{SQLiteDriver}, or
  the character string "SQLite" or an \code{SQLiteConnection}.
  }
\item{conn}{
  an \code{SQLiteConnection} object as produced by \code{dbConnect}.
  }
\item{\dots }{
  As of RSQLite 0.4-1 you may specify values for the two \code{PRAGMAs}
  \code{cache\_size} and \code{synchronous} when initializing a new
  connection (this does not applies, obviously, to cloning an existing
  connection).

  RSQLite defaults \code{synchronous} to 0 (or "OFF"),
  although SQLite's default as of 3.2.8 is 2 (FULL).
  Possible values for \code{synchronous} are 0, 1, or 2 or the 
  corresponding strings "OFF", "NORMAL", or "FULL".
  Users have reported significant speed ups using \code{sychronous=0},
  and the SQLite documentation itself implies considerable improved
  performance at the very modest risk of database corruption in the
  unlikely case of the operating system (\emph{not} the R application) 
  crashing. See the SQLite documentation for the full details of this
  \code{PRAGMA}.
  
  \code{cache\_size} can be a positive integer to change
   the maximum number of disk pages that SQLite holds in
   memory (SQLite's default is 2000 pages). }
}
}
\section{Side Effects}{
  A connection between R/S-Plus and the embeddable SQLite server is 
  established.  Note that since the SQLite is embedded in R/S-Plus,
  connections are not too resource hungry.

  SQLite connections only require the file name where the SQLite
  database reside.  For details see \code{\link{SQLite}}.
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
  \code{\link[DBI]{fetch}},
  \code{\link[DBI]{dbCommit}},
  \code{\link[DBI]{dbGetInfo}},
  \code{\link[DBI]{dbReadTable}}.
}

\keyword{methods}
\keyword{interface}
\keyword{database}
% vim: syntax=tex
