\name{sqliteQuickColumn}
\alias{sqliteQuickColumn}

\title{Return an entire column from a SQLite database}
\description{
  Return an entire column from a table in a SQLite database as an R
  vector of the appropriate type.  This function is experimental and
  subject to change.
}

\usage{
sqliteQuickColumn(con, table, column)
}
%- maybe also 'usage' for other objects documented here.
\arguments{
\item{con}{ a \code{SQLiteConnection} object as produced by
    \code{sqliteNewConnection}.}
  \item{table}{a string specifying the name of the table}
  \item{column}{a string specifying the name of the column in the
      specified table to retrieve.}
}
\details{
  This function relies upon the SQLite internal \code{ROWID} column to
  determine the number of rows in the table.  This may not work
  depending on the table schema definition and pattern of update.
}
\value{
  an R vector of the appropriate type (based on the type of the column
  in the database).
}

\author{Seth Falcon}

\keyword{interface}

