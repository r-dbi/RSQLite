\name{dbReadTable,SQLiteConnection,character-method}
\alias{dbReadTable,SQLiteConnection,character-method}
\alias{sqliteReadTable}
\title{Convenience functions for importing/exporting DBMS tables}
\usage{
  \S4method{dbReadTable}{SQLiteConnection,character}(conn,
    name, ...)

  sqliteReadTable(con, name, row.names = "row_names",
    check.names = TRUE, ...)
}
\arguments{
  \item{conn}{a \code{\linkS4class{SQLiteConnection}}
  object, produced by \code{\link[DBI]{dbConnect}}}

  \item{name}{a character string specifying a table name.
  SQLite table names are \emph{not} case sensitive, e.g.,
  table names \code{ABC} and \code{abc} are considered
  equal.}

  \item{...}{Ignored. Needed for compatibility with
  generic.}

  \item{check.names}{If \code{TRUE}, the default, column
  names will be converted to valid R identifiers.}

  \item{row.names}{A string or an index specifying the
  column in the DBMS table to use as \code{row.names} in
  the output data.frame (a \code{NULL}, \code{""}, or 0
  specifies that no column should be used as
  \code{row.names} in the output.)}
}
\value{
  A data.frame in the case of \code{dbReadTable}; otherwise
  a logical indicating whether the operation was
  successful.
}
\description{
  These functions mimic their R/S-Plus counterpart
  \code{get}, \code{assign}, \code{exists}, \code{remove},
  and \code{objects}, except that they generate code that
  gets remotely executed in a database engine.
}
\note{
  Note that the data.frame returned by \code{dbReadTable}
  only has primitive data, e.g., it does not coerce
  character data to factors.
}
\examples{
\dontrun{
conn <- dbConnect("SQLite", dbname = "sqlite.db")
if(dbExistsTable(con, "fuel_frame")){
   dbRemoveTable(conn, "fuel_frame")
   dbWriteTable(conn, "fuel_frame", fuel.frame)
}
if(dbExistsTable(conn, "RESULTS"))
   dbWriteTable(conn, "RESULTS", results2000, append = TRUE)
else
   dbWriteTable(conn, "RESULTS", results2000)

}
}

