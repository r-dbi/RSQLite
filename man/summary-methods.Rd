\docType{methods}
\name{summary-methods}
\alias{coerce,SQLiteConnection,SQLiteDriver-method}
\alias{coerce,SQLiteResult,SQLiteConnection-method}
\alias{coerce,dbObjectId,character-method}
\alias{coerce,dbObjectId,integer-method}
\alias{coerce,dbObjectId,numeric-method}
\alias{coerce-methods}
\alias{format,dbObjectId-method}
\alias{format-methods}
\alias{print,dbObjectId-method}
\alias{show,dbObjectId-method}
\alias{show-methods}
\alias{summary,SQLiteConnection-method}
\alias{summary,SQLiteDriver-method}
\alias{summary,SQLiteObject-method}
\alias{summary,SQLiteResult-method}
\alias{summary-methods}
\title{Summarize an SQLite object}
\description{
  These methods are straight-forward implementations of the
  corresponding generic functions.
}
\section{Methods}{
  \describe{

  \item{object = "DBIObject"}{ Provides relevant metadata
  information on \code{object}, for instance, the SQLite
  server file, the SQL statement associated with a result
  set, etc.  } \item{from}{object to be coerced}
  \item{to}{coercion class} \item{x}{object to
  \code{format} or \code{print} or \code{show}} }
}

