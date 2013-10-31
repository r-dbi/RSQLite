\name{sqlite-io}
\alias{count.fields.wrapper}
\alias{dbReadTable,SQLiteConnection,character-method}
\alias{dbWriteTable,SQLiteConnection,character,character-method}
\alias{sqlite-io}
\alias{sqliteImportFile}
\alias{sqliteReadTable}
\alias{sqliteWriteTable}
\title{Convenience functions for importing/exporting DBMS tables}
\usage{
  \S4method{dbReadTable}{SQLiteConnection,character}(conn,
    name, ...)

  sqliteReadTable(con, name, row.names = "row_names",
    check.names = TRUE, ...)

  sqliteWriteTable(con, name, value, row.names = TRUE,
    overwrite = FALSE, append = FALSE, field.types = NULL,
    ...)

  \S4method{dbWriteTable}{SQLiteConnection,character,character}(conn,
    name, value, ...)

  sqliteImportFile(con, name, value, field.types = NULL,
    overwrite = FALSE, append = FALSE, header, row.names,
    nrows = 50, sep = ",", eol = "\n", skip = 0, ...)

  count.fields.wrapper(file, sep = "", quote = "\"'",
    skip = 0, blank.lines.skip = TRUE, comment.char = "#",
    ...)
}
\arguments{
  \item{conn}{a \code{\linkS4class{SQLiteConnection}}
  object, produced by \code{\link[DBI](dbConnect)}}

  \item{name}}{a character string specifying a table name.
  SQLite table names are \emph{not} case sensitive, e.g.,
  table names \code{ABC} and \code{abc} are considered
  equal.}

  \item{value}{a data.frame (or coercible to data.frame)
  object or a file name (character).  In the first case,
  the data.frame is written to a temporary file and then
  imported to SQLite; when \code{value} is a character, it
  is interpreted as a file name and its contents imported
  to SQLite.}

  \item{row.names}{in the case of \code{dbReadTable}, this
  argument can be a string or an index specifying the
  column in the DBMS table to be used as \code{row.names}
  in the output data.frame (a \code{NULL}, \code{""}, or 0
  specifies that no column should be used as
  \code{row.names} in the output.

  In the case of \code{dbWriteTable}, this argument should
  be a logical specifying whether the \code{row.names}
  should be output to the output DBMS table; if
  \code{TRUE}, an extra field whose name will be whatever
  the R identifier \code{"row.names"} maps to the DBMS (see
  \code{\link[DBI]{make.db.names}}).  }}

  \item{overwrite}{a logical specifying whether to
  overwrite an existing table or not. Its default is
  \code{FALSE}. (See the BUGS section below)}

  \item{append}{a logical specifying whether to append to
  an existing table in the DBMS.  Its default is
  \code{FALSE}.}

  \item{...}{Ignored. Needed for compatibility with
  generic.}

  \item{header}{is a logical indicating whether the first
  data line (but see \code{skip}) has a header or not.  If
  missing, it value is determined following
  \code{\link{read.table}} convention, namely, it is set to
  TRUE if and only if the first row has one fewer field
  that the number of columns.}

  \item{col.names}{a character vector with column names
  (these names will be filtered with
  \code{\link[DBI]{make.db.names}} to ensure valid SQL
  identifiers. (See also \code{field.types} below.)}

  \item{sep}{The field separator, defaults to \code{','}.}

  \item{eol}{The end-of-line delimiter, defaults to
  \code{'\n'}.}

  \item{number}{of lines to skip before reading the data.
  Defaults to 0.}

  \item{field.types}{character vector of named SQL field
  types where the names are the names of new table's
  columns. If missing, types inferred with
  \code{\link[DBI]{dbDataType}}).}
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
if(dbExistsTable(conn, "RESULTS")){
   dbWriteTable(conn, "RESULTS", results2000, append = TRUE)
else
   dbWriteTable(conn, "RESULTS", results2000)
}
}
}

