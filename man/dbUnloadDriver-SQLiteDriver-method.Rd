\name{dbUnloadDriver,SQLiteDriver-method}
\alias{dbUnloadDriver,SQLiteDriver-method}
\alias{sqliteCloseDriver}
\title{Unload SQLite driver.}
\usage{
  \S4method{dbUnloadDriver}{SQLiteDriver}(drv, ...)

  sqliteCloseDriver(drv, ...)
}
\arguments{
  \item{drv}{Object created by \code{\link{SQLite}}}

  \item{...}{Ignored. Needed for compatibility with
  generic.}
}
\value{
  A logical indicating whether the operation succeeded or
  not.
}
\description{
  Unload SQLite driver.
}

