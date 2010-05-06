set.seed(0x977)

mk_df <- function()
{
    mk_blob <- function(n) as.raw(sample(0:255, n, replace = TRUE))
    name <- letters[1:10]
    data <- lapply(1:10, function(x) mk_blob(sample(10:256, 1)))
    score <- rnorm(10)
    count <- sample(1:10)
    df <- data.frame(name = name, score = score, count = count,
                     data = I(data),
                     stringsAsFactors = FALSE)
}

mk_db <- function(df)
{
    db <- dbConnect(SQLite(), dbname = ":memory:")
    dbGetQuery(db, "create table t (name text, score float,
                    count integer, data blob)")
    dbGetPreparedQuery(db, "insert into t values (?, ?, ?, ?)", df)
    db
}

do_column_test <- function(colName)
{
    df <- mk_df()
    db <- mk_db(df)
    ans <- dbGetQuery(db, sprintf("select %s from t", colName))[[1]]
    ## for list valued columns, there will be an AsIs class attr
    want <- df[[colName]]
    if (is.list(want)) class(want) <- NULL
    checkEquals(want, ans)
    dbDisconnect(db)
}

test_column_access <- function()
{
    for (cn in names(mk_df())) {
        do_column_test(cn)
    }
}

test_simple_blob_column <- function()
{
    db <- dbConnect(SQLite(), dbname = ":memory:")
    dbGetQuery(db, "CREATE TABLE t1 (name TEXT, data BLOB)")

    z <- paste("hello", 1:10)
    df <- data.frame(a = letters[1:10],
                     z = I(lapply(z, charToRaw)))
    dbGetPreparedQuery(db, "insert into t1 values (:a, :z)", df)
    a <- dbGetQuery(db, "select name from t1")
    checkEquals(10, nrow(a))
    a <- dbGetQuery(db, "select data from t1")
    checkEquals(10, nrow(a))
    a <- dbGetQuery(db, "select * from t1")
    checkEquals(10, nrow(a))
    checkEquals(2, ncol(a))

    checkEquals(z, sapply(a$data, rawToChar))
    dbDisconnect(db)
}

test_null_valued_blobs <- function()
{
    db <- dbConnect(SQLite(), ":memory:")
    df <- data.frame(ii=1:3, aa=letters[1:3])
    df$blob <- list(NULL, raw(3), raw(0))

    ## verify that you can insert BLOB NULL.  This makes use of
    ## dbSendPreparedQuery so we are testing that interface here.
    checkEquals(TRUE, dbWriteTable(db, "t3", df, row.names=FALSE))

    ## db NULL => R NULL
    ans <- dbGetQuery(db, "SELECT * FROM t3 WHERE blob IS NULL")
    checkEquals(1, ans[["ii"]])
    checkEquals("a", ans[["aa"]])
    checkTrue(is.list(ans[["blob"]]))
    checkEquals(1, length(ans[["blob"]]))
    checkTrue(is.null(ans[["blob"]][[1]]))

    ## zero-length BLOBs map correctly
    ans <- dbGetQuery(db, "SELECT * FROM t3 WHERE blob=x''")
    checkEquals(3, ans[["ii"]])
    checkEquals("c", ans[["aa"]])
    checkEquals(raw(0), ans[["blob"]][[1]])

    ## no rows returned, types inferred correctly
    ans <- dbGetQuery(db, "SELECT * FROM t3 WHERE 0")
    checkEquals(0, nrow(ans))
    wantedTypes <- c("integer", "character", "list")
    checkEquals(wantedTypes, as.character(sapply(ans, typeof)))
}
