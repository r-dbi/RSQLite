\name{sqliteCopyDatabase}
\alias{sqliteCopyDatabase}

\title{
Copy a SQLite database
}

\description{
  This function copies a database connection to a file or to another
  database connection.  It can be used to save an in-memory database
  (created using \code{dbname = ":memory:"}) to a file or to create an
  in-memory database as a copy of anothe database.
}

\usage{
sqliteCopyDatabase(from, to)
}

\arguments{
  \item{from}{
    A \code{SQLiteConnection} object.  The main database in \code{from}
    will be copied to \code{to}.
  }
  
  \item{to}{
    Either a string specifying the file name where the copy will be
    written or a \code{SQLiteConnection} object pointing to an empty
    database.  If \code{to} specifies an already existing
    file, it will be overwritten without a warning.  When \code{to} is a
    database connection, it is assumed to point to an empty and unused
    database; the behavior is undefined otherwise.
  }

}

 \details{
  This function uses SQLite's experimental online backup API to make the
  copy.  

}

\value{
  Returns \code{NULL}.
}

\references{
  \url{http://www.sqlite.org/backup.html}
}

\author{
Seth Falcon
}

\examples{
## Create an in memory database
db <- dbConnect(SQLite(), dbname = ":memory:")
df <- data.frame(letters=letters[1:4], numbers=1:4, stringsAsFactors = FALSE)
ok <- dbWriteTable(db, "table1", df, row.names = FALSE)
stopifnot(ok)

## Copy the contents of the in memory database to
## the specified file
backupDbFile <- tempfile()
sqliteCopyDatabase(db, backupDbFile)
diskdb <- dbConnect(SQLite(), dbname = backupDbFile)
stopifnot(identical(df, dbReadTable(diskdb, "table1")))

## Copy from one connection to another
db2 <- dbConnect(SQLite(), dbname = ":memory:")
sqliteCopyDatabase(db, db2)
stopifnot(identical(df, dbReadTable(db2, "table1")))

## cleanup
dbDisconnect(db)
dbDisconnect(diskdb)
dbDisconnect(db2)
unlink(backupDbFile)
}

\keyword{database}
