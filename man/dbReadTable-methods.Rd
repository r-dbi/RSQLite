% $Id$
\name{dbReadTable-methods}
\docType{methods}
\alias{dbReadTable-methods}
\alias{dbWriteTable-methods}
\alias{dbExistsTable-methods}
\alias{dbRemoveTable-methods}
\alias{dbReadTable,SQLiteConnection,character-method}
\alias{dbWriteTable,SQLiteConnection,character,data.frame-method}
\alias{dbWriteTable,SQLiteConnection,character,character-method}
\alias{dbExistsTable,SQLiteConnection,character-method}
\alias{dbRemoveTable,SQLiteConnection,character-method}
\title{
  Convenience functions for Importing/Exporting DBMS tables
}
\description{
  These functions mimic their R/S-Plus counterpart 
  \code{get},
  \code{assign},
  \code{exists}, 
  \code{remove}, and
  \code{objects},
  except that they generate code that gets remotely executed
  in a database engine.
}
\section{Methods}{\describe{
\item{conn}{
  an \code{SQLiteConnection} database connection object.
  }
\item{name}{
  a character string specifying a table name.
  }
\item{value}{
  a data.frame (or coercible to data.frame) object 
  or a file name (character).  In the first case, the data.frame
  is written to a temporary file and then imported to SQLite;
  when \code{value} is a character, it is interpreted as a
  file name and its contents imported to SQLite.
  }
\item{row.names}{
  in the case of \code{dbReadTable}, this argument can be a string or
  an index specifying the column in the DBMS table to be used as 
  \code{row.names} in the output data.frame (a \code{NULL}, \code{""}, or 0 
  specifies that no column should be used as \code{row.names} in the output).

  In the case of \code{dbWriteTable}, this argument should be a logical
  specifying whether the \code{row.names} should be output to the
  output DBMS table; if \code{TRUE}, an extra field whose name will be 
  whatever the R/S-Plus identifier \code{"row.names"} maps to the DBMS
  (see \code{\link[DBI]{make.db.names}}).
  }
\item{overwrite}{
  a logical specifying whether to overwrite an existing table
  or not.  Its default is \code{FALSE}.  (See the BUGS section below).
  }
\item{append}{
  a logical specifying whether to append to an existing table
  in the DBMS.  Its default is \code{FALSE}.
  }
\item{\dots }{
  optional arguments.

  When \code{dbWriteTable} is used to import data from a file, 
  you may optionally specify \code{header=}, \code{row.names=},
  \code{col.names=}, \code{sep=}, \code{eol=}, \code{field.types=}, 
  and \code{skip=}.

  \code{header} is a logical indicating whether the first data line
  (but see \code{skip}) has a header or not.  If missing, it value
  is determined following \code{\link[base]{read.table}} convention,
  namely, it is set to TRUE if and only if the first row has one
  fewer field that the number of columns.

  \code{row.names} is a logical to specify whether the first column
  is a set of row names.  If missing its defualt follows the 
  \code{\link[base]{read.table}} convention.
  
  \code{col.names} a character vector with column names (these names
  will be filtered with \code{\link[DBI]{make.db.names}} to 
  ensure valid SQL identifiers. (See also \code{field.types} below.)

  The field separator \code{sep=} defaults to \code{','}.

  The end-of-line delimiter \code{eol} defaults to \code{'\n'}.

  \code{skip} specifies number of lines to skip before reading the data
  and it defaults to 0. 

  \code{field.types} is a list of named field SQL types where 
  \code{names(field.types)} provide the new table's column names 
  (if missing, field types are inferred using \code{\link[DBI]{dbDataType}}).
 }
}
}

\value{
   A data.frame in the case of \code{dbReadTable}; otherwise a logical 
   indicating whether the operation was successful.  
}
\section{BUGS}{
  These RSQLite methods do not use transactions, thus it is dangerous 
  to specify \code{overwrite=TRUE} in \code{dbWriteTable} (the
  table is first removed and in case the data exporting fails
  the original table is lost forever).
}
\note{
   Note that the data.frame returned by \code{dbReadTable} only has
   primitive data, e.g., it does not coerce character data to factors.

   SQLite table names are \emph{not} case sensitive, e.g., table
   names \code{ABC} and \code{abc} are considered equal.
}
\references{
   See the Database Interface definition document
   \code{DBI.pdf} in the base directory of this package
   or \url{http://stat.bell-labs.com/RS-DBI}.
}
\seealso{
  \code{\link{sqliteImportFile}},
  \code{\link{SQLite}},
  \code{\link[DBI]{dbDriver}},
  \code{\link[DBI]{dbConnect}},
  \code{\link[DBI]{dbSendQuery}},
  \code{\link[DBI]{dbGetQuery}},
  \code{\link[DBI]{fetch}},
  \code{\link[DBI]{dbCommit}},
  \code{\link[DBI]{dbGetInfo}},
  \code{\link[DBI]{dbListTables}},
  \code{\link[DBI]{dbReadTable}}.
}
\examples{\dontrun{
conn <- dbConnect("SQLite", dbname = "sqlite.db")
if(dbExistsTable(con, "fuel_frame")){
   dbRemoveTable(conn, "fuel_frame")
   dbWriteTable(conn, "fuel_frame", fuel.frame)
}
if(dbExistsTable(conn, "RESULTS")){
   dbWriteTable(conn, "RESULTS", results2000, append = T)
else
   dbWriteTable(conn, "RESULTS", results2000)
}
}
}
\keyword{methods}
\keyword{interface}
\keyword{database}
% vim: syntax=tex
