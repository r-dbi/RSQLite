\name{dbListFields,SQLiteConnection,character-method}
\alias{dbListFields,SQLiteConnection,character-method}
\alias{sqliteTableFields}
\title{List fields in specified table.}
\usage{
  \S4method{dbListFields}{SQLiteConnection,character}(conn,
    name, ...)

  sqliteTableFields(con, name, ...)
}
\arguments{
  \item{conn,con}{An existing
  \code{\linkS4class{SQLiteConnection}}}

  \item{name}{a length 1 character vector giving the name
  of a table.}

  \item{...}{Ignored. Included for compatibility with
  generic.}
}
\description{
  List fields in specified table.
}

