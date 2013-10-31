\name{dbObjectId-class}
\alias{dbObjectId-class}
\alias{show,dbObjectId-method}
\title{Class dbObjectId.}
\usage{
  \S4method{show}{dbObjectId}(object)
}
\arguments{
  \item{object}{of class \code{dbObjectId}}
}
\description{
  A helper (mixin) class to provide external references in
  an R/S-Plus portable way.
}
\note{
  A cleaner mechanism would use external references, but
  historically this class has existed mainly for R/S-Plus
  portability.
}
\section{Objects from the Class}{
  A virtual Class: No objects may be created from it.
}
\examples{
con <- dbConnect(SQLite(), ":memory:")
is(sqlite, "dbObjectId")   ## True
is(con, "dbObjectId")  ## True
isIdCurrent(con)       ## True
dbDisconnect(con)
isIdCurrent(con)       ## False
}

