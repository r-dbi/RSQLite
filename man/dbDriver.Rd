\docType{methods}
\name{dbDriver}
\alias{dbDriver}
\alias{dbDriver,character-method}
\alias{dbUnloadDriver,SQLiteDriver-method}
\title{SQLite implementation of the Database Interface (DBI) classes and drivers}
\description{
  SQLite driver initialization and closing
}
\section{Methods}{
  \describe{ \item{drvName}{ character name of the driver
  to instantiate.  } \item{drv}{ an object that inherits
  from \code{SQLiteDriver} as created by \code{dbDriver}. }
  \item{list()}{ any other arguments are passed to the
  driver \code{drvName}.  } }
}
\examples{
\dontrun{
# create an SQLite instance for capacity of up to 25 simultaneous
# connections.
m <- dbDriver("SQLite", max.con = 25)

con <- dbConnect(m, dbname="sqlite.db")
rs <- dbSubmitQuery(con,
         "select * from HTTP_ACCESS where IP_ADDRESS = '127.0.0.1'")
df <- fetch(rs, n = 50)
df2 <- fetch(rs, n = -1)
dbClearResult(rs)

pcon <- dbConnect(p, "user", "password", "dbname")
dbListTables(pcon)
}
}

