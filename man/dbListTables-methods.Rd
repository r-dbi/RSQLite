\docType{methods}
\name{dbListTables-methods}
\alias{dbListConnections,SQLiteDriver-method}
\alias{dbListConnections-methods}
\alias{dbListFields,SQLiteConnection,character-method}
\alias{dbListFields-methods}
\alias{dbListResults,SQLiteConnection-method}
\alias{dbListResults-methods}
\alias{dbListTables,SQLiteConnection-method}
\alias{dbListTables-methods}
\title{List items from an SQLite DBMS and from objects}
\description{
  These methods are straight-forward implementations of the
  corresponding generic functions.
}
\section{Methods}{
  \describe{ \item{drv}{an \code{SQLiteDriver}.}
  \item{conn}{an \code{SQLiteConnection}.} \item{name}{a
  character string with the table name.}
  \item{list()}{currently not used.} }
}
\examples{
\dontrun{
drv <- dbDriver("SQLite")
# after working awhile...
for(con in dbListConnections(odbc)){
   dbGetStatement(dbListResults(con))
}
}
}

