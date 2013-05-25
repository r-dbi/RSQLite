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


testWithRowNames <- function() {
    df <- data.frame(a=1:10, b=pi*1:10, c=LETTERS[1:10],
                     stringsAsFactors=FALSE)
    rn <- paste(letters[1:10], 1:10, sep="")
    row.names(df) <- rn
    dbWriteTable(DATA$db, "t1rn", df)

    expect <- df
    row.names(expect) <- 1:nrow(df)
    expect <- cbind(rn, expect, stringsAsFactors=FALSE)
    names(expect)[1] <- "row_names"
    got <- dbGetQuery(DATA$db, "select * from t1rn")
    colTypes <- c("character", "integer", "double", "character")
    names(colTypes) <- names(expect)
    checkEquals(colTypes, sapply(expect, typeof))
    checkEquals(colTypes, sapply(got, typeof))
    checkEquals(dim(expect), dim(got))
    checkEquals(expect, got)
}

testOverwriteAndAppend <- function() {
    df <- data.frame(a=1:10, b=pi*1:10, c=LETTERS[1:10],
                     stringsAsFactors=FALSE)
    dbWriteTable(DATA$db, "t1", df, row.names=FALSE)
    ## The default is overwrite=FALSE, append
    checkTrue(!suppressWarnings(dbWriteTable(DATA$db, "t1",
                                             df, row.names=FALSE)))
    checkTrue(dbWriteTable(DATA$db, "t1", df, row.names=FALSE,
                           append=TRUE))
    checkTrue(dbWriteTable(DATA$db, "t1", df, row.names=FALSE,
                           overwrite=TRUE))
    ## you can't overwrite and append
    checkException(dbWriteTable(DATA$db, "t1", df, row.names=FALSE,
                                overwrite=TRUE, append=TRUE),
                   silent=TRUE)
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
    checkEquals(FALSE,
                suppressWarnings(dbWriteTable(con,"t1", x, append=TRUE)))

    ## this used to cause an error
    checkEquals(TRUE, dbDisconnect(con))
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
                     country=c("JP","HK"),
                     stringsAsFactors=FALSE)
    dbWriteTable(DATA$db, "t1", df, row.names=FALSE)
    got <- dbGetQuery(DATA$db, "select * from t1")
    checkEquals(df, got)
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

## tests for importing a file using dbWriteTable

testImportViaWriteTable <- function() {
    expect <- data.frame(a=c(1:3, NA), b=c("x", "y", "z", "E"),
                         stringsAsFactors=FALSE)
    checkTrue(dbWriteTable(DATA$db, "dat", "dat1.txt", sep="|", eol="\n",
                           header=TRUE, overwrite=TRUE))
    got <- dbGetQuery(DATA$db, "select * from dat")
    checkEquals(expect, got)

    checkTrue(dbWriteTable(DATA$db, "dat", "dat2.txt", sep="|", eol="\n",
                           header=TRUE, overwrite=TRUE))
    got <- dbGetQuery(DATA$db, "select * from dat")
    checkEquals(expect, got)

    checkTrue(dbWriteTable(DATA$db, "dat", "dat3.txt", sep="|", eol="\r\n",
                           header=TRUE, overwrite=TRUE))
    got <- dbGetQuery(DATA$db, "select * from dat")
    checkEquals(expect, got)

    checkTrue(dbWriteTable(DATA$db, "dat", "dat4.txt", sep="|", eol="\r\n",
                           header=TRUE, overwrite=TRUE))
    got <- dbGetQuery(DATA$db, "select * from dat")
    checkEquals(expect, got)

}


testFactorWithNA <- function() {
    df <- data.frame(x=1:10,y=factor(LETTERS[1:10]))
    df$y[4] <- NA

    dbWriteTable(DATA$db, "bad_table", df)

    got <- dbGetQuery(DATA$db, "select * from bad_table")

    checkEquals(df$x, got$x)
    checkEquals(as.character(df$y), got$y)
}

testLogicalTreatedAsInt <- function() {
    df <- data.frame(x=1:3, y=c(NA, TRUE, FALSE))

    dbWriteTable(DATA$db, "t1", df)

    got <- dbGetQuery(DATA$db, "select * from t1")

    checkEquals("integer", typeof(got$y))
    checkEquals(as.integer(NA), got$y[1])
    checkEquals(1L, got$y[2])
    checkEquals(0L, got$y[3])
}

testCommentCharIsRespected <- function()
{
    tmp_file <- tempfile()
    on.exit(file.remove(tmp_file))
    cat('A,B,C\n11,2#2,33\n', file = tmp_file)
    ## default comment.char is '#'
    checkException(dbWriteTable(DATA$db, "t1", tmp_file,
                                header = TRUE, sep = ","),
                   silent = TRUE)

    ## specifying a comment.char works
    dbWriteTable(DATA$db, "t1", tmp_file, header = TRUE, sep = ",",
                 comment.char = "")
    got <- as.character(dbGetQuery(DATA$db, "select B from t1"))
    checkEquals("2#2", got)
}

testColClasses <- function()
{
    tmp_file <- tempfile()
    on.exit(file.remove(tmp_file))
    cat('A,B,C\n1,2,3\n4,5,6\na,7,8\n', file = tmp_file)
    dbWriteTable(DATA$db, "t1", tmp_file, header = TRUE, sep = ",",
                 colClasses=c("character", "integer", "double"))
    got <- dbGetQuery(DATA$db, "select * from t1")
    checkEquals(c(A="character", B="integer", C="numeric"),
                sapply(got, class))
}
