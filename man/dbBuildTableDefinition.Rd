\name{dbBuildTableDefinition}
\alias{dbBuildTableDefinition}
\title{Build the SQL CREATE TABLE definition as a string}
\description{
   Build the SQL CREATE TABLE definition as a string for the
   input data.frame
}
\usage{
dbBuildTableDefinition(dbObj, name, value, field.types = NULL, row.names = TRUE, ...)
}
\arguments{
  \item{dbObj}{any DBI object (used only to dispatch according to the 
    engine (e.g., MySQL, SQLite, Oracle) }
  \item{name}{name of the new SQL table}
  \item{value}{data.frame for which we want to create a table}
  \item{field.types}{optional named list of the types for each field 
    in \code{value}} 
  \item{row.names}{logical, should row.name of \code{value} be exported
    as a \code{row\_names} field? Default is TRUE}
  \item{\dots}{reserved for future use}
}
\details{
  The output SQL statement is a simple \code{CREATE TABLE} with
  suitable for \code{dbGetQuery}
}
\value{
  An SQL string
}
\references{
  See the Database Interface definition document
  \code{DBI.pdf} in the base directory of this package
  or \url{http://stat.bell-labs.com/RS-DBI}.
}
\seealso{
  \code{\link{SQLite}},
  \code{\link[DBI]{dbConnect}},
  \code{\link[DBI]{dbSendQuery}},
  \code{\link[DBI]{dbGetQuery}},
  \code{\link[DBI]{fetch}},
  \code{\link[DBI]{dbCommit}},
  \code{\link[DBI]{dbGetInfo}},
  \code{\link[DBI]{dbReadTable}}.
}
\keyword{methods}
\keyword{interface}
\keyword{database}
%% vim: syntax=tex
