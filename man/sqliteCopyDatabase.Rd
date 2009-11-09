\name{sqliteCopyDatabase}
\alias{sqliteCopyDatabase}

\title{
Copy a SQLite database to a file
}
\description{
This function allows you to copy the main database of a given database
connection to a file.  It can be used to save an in-memory database
created using \code{dbname = ":memory:"}.
}
\usage{
sqliteCopyDatabase(db, filename)
}

\arguments{
  \item{db}{
    A \code{SQLiteConnection} object.
  }
  \item{filename}{
    A string containing the path where the copy will be written.
  }
}
\details{
  This function uses SQLite's online backup API to make the copy.  The
  target file given by \code{filename} will be over written if it
  already exists.
}
\value{
  Returns \code{TRUE} if the copy was successful and \code{FALSE} if an
  error code was returned by the SQLite API.
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
df <- data.frame(letters=letters[1:4], numbers=1:4)
ok <- dbWriteTable(db, "table1", df, row.names = FALSE)
stopifnot(ok)

## Copy the contents of the in memory database to
## the specified file
backupDbFile <- tempfile()
ok <- sqliteCopyDatabase(db, backupDbFile)
stopifnot(ok)

## cleanup
dbDisconnect(db)
unlink(backupDbFile)
}

\keyword{database}
