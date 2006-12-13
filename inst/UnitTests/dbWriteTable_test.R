library("RSQLite")

DATA <- new.env(parent=emptyenv(), hash=TRUE)

.setUp <- function() {
    DATA$dbfile <- tempfile()
    DATA$db <- dbConnect(dbDriver("SQLite"), dbname=DATA$dbfile)
}

.tearDown <- function() {
    lapply(dbListResults(DATA$db), dbClearResult)
    dbDisconnect(DATA$db)
    file.remove(DATA$dbfile)
}

testCanCloseAfterFailedWriteTable <- function() {
    ## handle DB connection manually since we want
    ## to explicitly check dbDisconnect is error free.
    tf <- tempfile()
    con <- dbConnect(dbDriver("SQLite"), dbname=tf)

    x <- data.frame(col1=1:10, col2=letters[1:10])

    dbWriteTable(con, "t1", x)
    dbGetQuery(con, "create unique index t1_c1_c2_idx on t1(col1, col2)")

    ## uniqueness constraint error/failure
    checkEquals(FALSE, dbWriteTable(con,"t1", x, append=T))

    ## this used to cause an error
    dbDisconnect(con)
    file.remove(tf)
}


testCommasInDataFrame <- function() {
    ## From: "Clarkson, Brian" <brian.clarkson@credit-suisse.com>
    ## Subject: RE: improper use of sqlite3_prepare() API?
    ## Date: Mon Dec  4 20:27:06 2006 -0800

    ## Oh and while I am talking to you, there are two more problems that I
    ## was able to hack the R to get around and hence wasn't as urgent...

    ## You cannot write data.frames that contain commas in its character
    ## string data to a database. The problem was that the sqliteWriteTable
    ## function internally uses comma-delimited files without properly
    ## quoting the text columns. Here is an example:

    df <- data.frame(company=c("ABC, Inc.","DEF Holdings"),
                     layoffs=c(1000,2000),
                     country=c("JP","HK"))
    ## Our fix is not automagic, but we now allow sep as an argument.
    dbWriteTable(DATA$db, "t1", df, sep="\t")
}


##  con <- dbConnect(drv,dbname="test.db") blah2 <-
##  dbGetQuery(con,"select * from blah") dbDisconnect(con)
## [1] TRUE blah2
##        company layoffs country 1 ABC, Inc.  1000 JP\r 2 DEF Holdings
## 2000 HK\r


## If I read back the results that I just wrote, we can see that the last
## column has '\r' appended to each row. I traced this to assumption in
## sqliteImportFile that the eol character is assumed in the code to be
## \n' which is not true for Windows. Specifying the eol character in the
## dbWriteTable call fixes this problem:

## dbWriteTable(con,"blah",blah,eol="\r\n")
