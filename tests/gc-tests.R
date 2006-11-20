library("RSQLite")
torture=FALSE
drv <- SQLite()
con <- dbConnect(drv, tempfile())
table.name <- "testing"
set.seed(123)
df <- as.data.frame( matrix( rnorm( 225000 ), ncol = 225 ) )
dbWriteTable( con, "testing", df, row.names = FALSE, 
             overwrite = TRUE )

get_data <- function( indices, con, table_name ) {
   query <- paste(
                  "select * from",
                  table_name,
                  "where _ROWID_ in (",
                  paste( indices, collapse = "," ),
                  ")"
                  )
   dbGetQuery( con, query )
}

gctorture(on=torture)
ans <- get_data(1:3, con, table.name )[ ,1:5]
ans
gctorture(on=FALSE)

df2 <- data.frame(name=letters[1:10],
	          id=1:10,
                  score=1:10 * 2.345)
gctorture(on=torture)
dbWriteTable(con, "t2", df2)
gctorture(on=FALSE)
