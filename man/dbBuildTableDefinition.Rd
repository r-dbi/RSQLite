\name{dbBuildTableDefinition}
\alias{dbBuildTableDefinition}
\title{Build the SQL CREATE TABLE definition as a string}
\usage{
dbBuildTableDefinition(dbObj, name, value, field.types = NULL,
  row.names = TRUE, ...)
}
\arguments{
  \item{dbObj}{The object created by \code{\link{SQLite}}}

  \item{name}{name of the new SQL table}

  \item{value}{data.frame for which we want to create a
  table}

  \item{field.types}{optional named list of the types for
  each field in \code{value}}

  \item{row.names}{logical, should row.name of \code{value}
  be exported as a \code{row\_names} field? Default is
  \code{TRUE}}

  \item{...}{Ignored. Reserved for future use.}
}
\value{
  An SQL string
}
\description{
  The output SQL statement is a simple \code{CREATE TABLE}
  with suitable for \code{dbGetQuery}
}

