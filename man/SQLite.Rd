% $Id$
\name{SQLite}
\alias{SQLite}
\alias{SQLiteDriver}
\title{
  Initialize the SQLite engine for the current R session.
}
\description{
This function initializes the SQLite engine.
It returns an object that allows you to connect to the SQLite engine
embedded in R.
}
\usage{
SQLite(max.con = 200, fetch.default.rec = 500, force.reload = FALSE, 
       shared.cache=FALSE)
}
\arguments{
\item{max.con}{
  IGNORED.  As of RSQLite 0.9.0, connections are managed dynamically and
  there is no predefined limit to the number of connections you can have
  in a given R session.
  }
\item{fetch.default.rec}{
  default number of records to fetch at one time from the database.
  The \code{fetch} method will use this number as a default, but
  individual calls can override it.
  }
\item{force.reload}{
  should the package code be reloaded (reinitialized)?
  Setting this to \code{TRUE} allows you to change
  default settings.  Notice that all connections should be closed
  before re-loading.
  }
\item{shared.cache}{
  logical describing whether shared-cache mode should be enabled on the SQLite
  driver. The default is \code{FALSE}.
  }
}
\value{
An object of class \code{SQLiteDriver} which extends 
\code{dbDriver} and \code{dbObjectId}.
This object is needed to create connections
to the embedded SQLite database.
There can be many SQLite database instances running
simultaneously.
}
\section{Side Effects}{
The R client part of the database communication is initialized,
but note that connecting to database instances needs to be done through
calls to \code{dbConnect}.
}
\details{
This object is a singleton, that is, on subsequent invocations
it returns the same initialized object. 

This implementation allows the R embedded SQLite engine
to work with multiple database instances through multiple connections 
simultaneously.

SQLite keeps each database instance in one single file. The name
of the database \emph{is} the file name, thus database names
should be legal file names in the running platform.
}
\section{User authentication}{
SQLite is a single-user database engine, so no authentication
is required.
}
\author{David A. James}
\section{References}{
See the Omega Project for Statistical Computing
\url{http://stat.bell-labs.com/RS-DBI}
for more details on the R database interface.

See the Adobe PDF file \code{DBI.pdf} under the \code{doc}
subdirectory of the DBI package, i.e., 
\code{system.file("doc", "DBI.pdf", package = "DBI")}

See the documentation at the SQLite Web site
\url{http://www.sqlite.org} for details.
}
\seealso{
On database drivers:

\code{\link[DBI]{dbDriver}},
\code{\link[DBI]{dbUnloadDriver}},
\code{\link[DBI]{dbListConnections}}.

On connections, SQL statements and resultSets:

\code{\link[DBI]{dbConnect}},
\code{\link[DBI]{dbDisconnect}},
\code{\link[DBI]{dbSendQuery}},
\code{\link[DBI]{dbGetQuery}},
\code{\link[DBI]{fetch}},
\code{\link[DBI]{dbListResults}}.

On transaction management:

\code{\link[DBI]{dbCommit}}, 
\code{\link[DBI]{dbRollback}}.

On meta-data:

\code{\link{summary}},
\code{\link[DBI]{dbGetInfo}},
\code{\link[DBI]{dbListTables}},
\code{\link[DBI]{dbListFields}},
\code{\link[DBI]{dbColumnInfo}},
\code{\link[DBI]{dbGetException}},
\code{\link[DBI]{dbGetStatement}},
\code{\link[DBI]{dbHasCompleted}},
\code{\link[DBI]{dbGetRowCount}},
\code{\link[DBI]{dbGetRowsAffected}}.
}
\examples{
   # create a SQLite instance and create one connection.
   m <- dbDriver("SQLite")
   
   # initialize a new database to a tempfile and copy some data.frame
   # from the base package into it
   tfile <- tempfile()
   con <- dbConnect(m, dbname = tfile)
   data(USArrests)
   dbWriteTable(con, "USArrests", USArrests)
   
   # query
   rs <- dbSendQuery(con, "select * from USArrests")
   d1 <- fetch(rs, n = 10)      # extract data in chunks of 10 rows
   dbHasCompleted(rs)
   d2 <- fetch(rs, n = -1)      # extract all remaining data
   dbHasCompleted(rs)
   dbClearResult(rs)
   dbListTables(con)

   # clean up
   dbDisconnect(con)
   file.info(tfile)
   file.remove(tfile)
}
\keyword{interface}
\keyword{database}
% docclass is function
%  vim: syntax=tex
