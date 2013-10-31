\docType{methods}
\name{transactions}
\alias{dbBeginTransaction}
\alias{dbBeginTransaction,SQLiteConnection-method}
\alias{dbBeginTransaction-methods}
\alias{dbCommit,SQLiteConnection-method}
\alias{dbRollback,SQLiteConnection-method}
\alias{dbRollback-methods}
\alias{transactions}
\title{DBMS Transaction Management}
\description{
  By default, SQLite is in auto-commit mode.
  \code{dbBeginTransaction} starts a SQLite transaction and
  turns auto-commit off. \code{dbCommit} and
  \code{dbRollback} commit and rollback the transaction,
  respectively and turn auto-commit on.
}
\section{Methods}{
  \describe{ \item{conn}{ a \code{SQLiteConnection} object,
  as produced by the function \code{dbConnect}.  }
  \item{list()}{ any database-specific arguments.  }\item{
  }{ any database-specific arguments.  } }
}
\examples{
drv <- dbDriver("SQLite")
tfile <- tempfile()
con <- dbConnect(drv, dbname = tfile)
data(USArrests)
dbWriteTable(con, "arrests", USArrests)
dbGetQuery(con, "select count(*) from arrests")[1, ]

dbBeginTransaction(con)
rs <- dbSendQuery(con, "DELETE from arrests WHERE Murder > 1")
do_commit <- if (dbGetInfo(rs)[["rowsAffected"]] > 40) FALSE else TRUE
dbClearResult(rs)
dbGetQuery(con, "select count(*) from arrests")[1, ]
if (!do_commit)
    dbRollback(con)
dbGetQuery(con, "select count(*) from arrests")[1, ]

dbBeginTransaction(con)
rs <- dbSendQuery(con, "DELETE from arrests WHERE Murder > 5")
dbClearResult(rs)
dbCommit(con)
dbGetQuery(con, "select count(*) from arrests")[1, ]

dbDisconnect(con)
}

