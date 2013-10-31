\docType{methods}
\name{dbSendQuery-methods}
\alias{dbClearResult,SQLiteResult-method}
\alias{dbGetException,SQLiteConnection-method}
\alias{dbGetException-methods}
\alias{dbGetPreparedQuery}
\alias{dbGetPreparedQuery,SQLiteConnection,character,data.frame-method}
\alias{dbGetPreparedQuery-methods}
\alias{dbGetQuery,SQLiteConnection,character-method}
\alias{dbGetQuery-methods}
\alias{dbSendPreparedQuery}
\alias{dbSendPreparedQuery,SQLiteConnection,character,data.frame-method}
\alias{dbSendPreparedQuery-methods}
\alias{dbSendQuery,SQLiteConnection,character-method}
\alias{dbSendQuery-methods}
\title{Execute a SQL statement on a database connection}
\description{
  These are the primary methods for interacting with a
  database via SQL queries.
}
\section{Methods}{
  \describe{ \item{conn}{a \code{SQLiteConnection} object.}
  \item{statement}{a character vector of length one
  specifying the SQL statement that should be executed.
  Only a single SQL statment should be provided.}
  \item{res}{a \code{SQLiteResult} object.}
  \item{list()}{additional parameters.}\item{ }{additional
  parameters.} }
}
\examples{
con <- dbConnect(SQLite(), ":memory:")
data(USArrests)
dbWriteTable(con, "arrests", USArrests)

res <- dbSendQuery(con, "SELECT * from arrests")
data <- fetch(res, n = 2)
data
dbClearResult(res)

dbGetQuery(con, "SELECT * from arrests limit 3")

tryCatch(dbGetQuery(con, "SELECT * FROM tableDoesNotExist"),
         error=function(e) { print("caught") })
dbGetException(con)

## The following example demonstrates the use of
## transactions and bound parameters in prepared
## statements.

set.seed(0x4554)

make_data <- function(n)
{
    alpha <- c(letters, as.character(0:9))
    make_key <- function(n)
    {
        paste(sample(alpha, n, replace = TRUE), collapse = "")
    }
    keys <- sapply(sample(1:5, replace=TRUE), function(x) make_key(x))
    counts <- sample(seq_len(1e4), n, replace = TRUE)
    data.frame(key = keys, count = counts, stringsAsFactors = FALSE)
}

key_counts <- make_data(100)


db <- dbConnect(SQLite(), dbname = ":memory:")

sql <- "
create table keys (key text, count integer)
"

dbGetQuery(db, sql)

bulk_insert <- function(sql, key_counts)
{
    dbBeginTransaction(db)
    dbGetPreparedQuery(db, sql, bind.data = key_counts)
    dbCommit(db)
    dbGetQuery(db, "select count(*) from keys")[[1]]
}

##  for all styles, you can have up to 999 parameters

## anonymous
sql <- "insert into keys values (?, ?)"
bulk_insert(sql, key_counts)


## named w/ :, $, @
## names are matched against column names of bind.data

sql <- "insert into keys values (:key, :count)"
bulk_insert(sql, key_counts[ , 2:1])

sql <- "insert into keys values ($key, $count)"
bulk_insert(sql, key_counts)

sql <- "insert into keys values (@key, @count)"
bulk_insert(sql, key_counts)

## indexed (NOT CURRENTLY SUPPORTED)
## sql <- "insert into keys values (?1, ?2)"
## bulk_insert(sql)

sql <- "select * from keys where count = :cc"
dbGetPreparedQuery(db, sql, data.frame(cc = c(95, 403)))

dbDisconnect(db)
}

