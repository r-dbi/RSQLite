\name{dbRemoveTable,SQLiteConnection,character-method}
\alias{dbRemoveTable,SQLiteConnection,character-method}
\title{Remove a table from the database.}
\usage{
  \S4method{dbRemoveTable}{SQLiteConnection,character}(conn,
    name, ...)
}
\arguments{
  \item{conn}{An existing
  \code{\linkS4class{SQLiteConnection}}}

  \item{...}{Ignored. Included for compatibility with
  generic.}
}
\description{
  Executes the SQL \code{DROP TABLE}.
}

