% $Id$
\name{summary-methods}
\docType{methods}
\alias{coerce-methods}
\alias{summary-methods}
\alias{format-methods}
\alias{show-methods}
\alias{coerce,dbObjectId,integer-method}
\alias{coerce,dbObjectId,numeric-method}
\alias{coerce,dbObjectId,character-method}
\alias{coerce,SQLiteConnection,SQLiteDriver-method}
\alias{coerce,SQLiteResult,SQLiteConnection-method}
\alias{format,dbObjectId-method}
\alias{print,dbObjectId-method}
\alias{show,dbObjectId-method}
\alias{summary,SQLiteObject-method}
\alias{summary,SQLiteDriver-method}
\alias{summary,SQLiteConnection-method}
\alias{summary,SQLiteResult-method}
\title{Summarize an SQLite object}
\description{
   These methods are straight-forward implementations of the corresponding
   generic functions.
}
\section{Methods}{\describe{

\item{object = "DBIObject"}{
   Provides relevant metadata information on \code{object}, 
   for instance, the SQLite server file, the
   SQL statement associated with a result set, etc.  
   }
\item{from}{object to be coerced}
\item{to}{coercion class}
\item{x}{object to \code{format} or \code{print} or \code{show}}
}
}
\keyword{methods}
\keyword{database}
\keyword{interface}
% vim: syntax=tex
