library("RSQLite")

# From file -------------------------------------------------------------------

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
