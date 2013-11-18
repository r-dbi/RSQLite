\docType{methods}
\name{dbWriteTable,SQLiteConnection,character,data.frame-method}
\alias{dbWriteTable,SQLiteConnection,character,character-method}
\alias{dbWriteTable,SQLiteConnection,character,data.frame-method}
\alias{sqliteImportFile}
\alias{sqliteWriteTable}
\title{Write a local data frame or file to the database.}
\usage{
\S4method{dbWriteTable}{SQLiteConnection,character,data.frame}(conn, name,
  value, ...)

\S4method{dbWriteTable}{SQLiteConnection,character,character}(conn, name, value,
  ...)

sqliteWriteTable(con, name, value, row.names = TRUE, overwrite = FALSE,
  append = FALSE, field.types = NULL, ...)

sqliteImportFile(con, name, value, field.types = NULL, overwrite = FALSE,
  append = FALSE, header, row.names, nrows = 50, sep = ",", eol = "\\n",
  skip = 0, ...)
}
\arguments{
  \item{conn,con}{a \code{\linkS4class{SQLiteConnection}}
  object, produced by \code{\link[DBI]{dbConnect}}}

  \item{name}{a character string specifying a table name.
  SQLite table names are \emph{not} case sensitive, e.g.,
  table names \code{ABC} and \code{abc} are considered
  equal.}

  \item{value}{a data.frame (or coercible to data.frame)
  object or a file name (character).  In the first case,
  the data.frame is written to a temporary file and then
  imported to SQLite; when \code{value} is a character, it
  is interpreted as a file name and its contents imported
  to SQLite.}

  \item{...}{Passed on to \code{sqliteWriteTable}.}

  \item{row.names}{A logical specifying whether the
  \code{row.names} should be output to the output DBMS
  table; if \code{TRUE}, an extra field whose name will be
  whatever the R identifier \code{"row.names"} maps to the
  DBMS (see \code{\link[DBI]{make.db.names}}).}

  \item{overwrite}{a logical specifying whether to
  overwrite an existing table or not. Its default is
  \code{FALSE}. (See the BUGS section below)}

  \item{append}{a logical specifying whether to append to
  an existing table in the DBMS.  Its default is
  \code{FALSE}.}

  \item{field.types}{character vector of named SQL field
  types where the names are the names of new table's
  columns. If missing, types inferred with
  \code{\link[DBI]{dbDataType}}).}

  \item{header}{is a logical indicating whether the first
  data line (but see \code{skip}) has a header or not.  If
  missing, it value is determined following
  \code{\link{read.table}} convention, namely, it is set to
  TRUE if and only if the first row has one fewer field
  that the number of columns.}

  \item{sep}{The field separator, defaults to \code{','}.}

  \item{eol}{The end-of-line delimiter, defaults to
  \code{'\n'}.}

  \item{skip}{number of lines to skip before reading the
  data. Defaults to 0.}

  \item{nrows}{Number of rows to read to determine types}
}
\description{
  Write a local data frame or file to the database.
}

