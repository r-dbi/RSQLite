\name{isIdCurrent}
\alias{isIdCurrent}
\title{Check whether an dbObjectId handle object is valid or not}
\usage{
isIdCurrent(obj)
}
\arguments{
  \item{obj}{any \code{dbObjectId} (e.g., \code{dbDriver},
  \code{dbConnection}, \code{dbResult}).}
}
\value{
a logical scalar.
}
\description{
Support function that verifies that an dbObjectId holding a
reference to a foreign object is still valid for
communicating with the RDBMS
}
\details{
\code{dbObjectId} are R/S-Plus remote references to foreign
(C code) objects. This introduces differences to the
object's semantics such as persistence (e.g., connections
may be closed unexpectedly), thus this function provides a
minimal verification to ensure that the foreign object
being referenced can be contacted.
}
\examples{
\dontrun{
cursor <- dbSendQuery(con, sql.statement)
isIdCurrent(cursor)
}
}

