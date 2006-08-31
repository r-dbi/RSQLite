% $Id$
\name{safe.write}
\alias{safe.write}
\title{Write a data.frame avoiding exceeding memory limits}
\description{
   This function batches calls to \code{write.table} to avoid
   exceeding memory limits for very large data.frames.
}
\usage{
safe.write(value, file, batch, row.names = TRUE, ..., sep = ',', 
  eol = '\n', quote.string=FALSE)
}
\arguments{
  \item{value}{a data.frame;}
  \item{file}{a file object (connection, file name, etc).}
  \item{batch}{maximum number of rows to write at a time.}
  \item{\dots}{any other arguments are passed to \code{write.table}.}
  \item{sep}{field separator passed to \code{write.table}.}
  \item{eol}{end of line character passed to \code{write.table}.}
  \item{quote.string}{logical value passed to \code{write.table}.}
}
\details{
   The function has a while loop invoking \code{\link[base]{write.table}}
   for subsets of \code{batch} rows of \code{value}.  Since this is
   a helper function for \code{\link[RMySQL]{mysqlWriteTable}} has hardcoded
   other arguments to \code{write.table}.
}
\value{
    \code{NULL}, invisibly.
}
\note{No error checking whatsoever is done.}

\seealso{\code{\link[base]{write.table}}} 

\examples{\dontrun{
   ctr.file <- file("dump.sqloader", "w")
   safe.write(big.data, file = ctr.file, batch = 25000)
}
}
\keyword{internal}
%% vim: syntax=tex
