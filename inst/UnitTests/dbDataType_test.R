test_integer <- function()
{
    checkEquals("INTEGER", sqliteDataType(1L))
    checkEquals("INTEGER", sqliteDataType(FALSE))
    checkEquals("INTEGER", sqliteDataType(TRUE))
    checkEquals("INTEGER", sqliteDataType(NA))
}

test_real <- function()
{
    checkEquals("REAL", sqliteDataType(1.0))
}

test_text <- function()
{
    checkEquals("TEXT", sqliteDataType("a"))
    checkEquals("TEXT", sqliteDataType(factor(letters)))
    checkEquals("TEXT", sqliteDataType(factor(letters, ordered = TRUE)))
}

test_blob <- function()
{
    checkEquals("BLOB", sqliteDataType(list(raw(1))))
    checkEquals("BLOB", sqliteDataType(list()))
    checkEquals("BLOB", sqliteDataType(list(a=NULL)))
}

test_I_AsIs <- function()
{
    df <- data.frame(a=I(1:2),
                     b=I(c("x", "y")),
                     c=I(list(raw(3), raw(1))),
                     d=I(c(1.1, 2.2)))
    got <- sapply(df, sqliteDataType)
    expect <- c(a="INTEGER", b="TEXT", c="BLOB", d="REAL")
    checkEquals(expect, got)
}

test_classes <- function()
{
    ## unhandled classes default to storage.mode and finally to TEXT.
    checkEquals("REAL", sqliteDataType(Sys.Date()))
    checkEquals("REAL", sqliteDataType(Sys.time()))

    intClass <- structure(1L, class="unknown1")
    checkEquals("INTEGER", sqliteDataType(intClass))

    dblClass <- structure(3.14, class="unknown1")
    checkEquals("REAL", sqliteDataType(dblClass))

    strClass <- structure("abc", class="unknown1")
    checkEquals("TEXT", sqliteDataType(strClass))
}

test_sqliteDataType <- function()
{
    input_list <- list(a=c(1L, 2L, 3L),
                       b=c(1.2, 2.2, 3.3),
                       c=c(TRUE, FALSE),
                       d=c("a", "b"),
                       e=factor(c("a", "a", "b")),
                       f=factor(c("a", "a", "b"), ordered = TRUE),
                       g=1+2i)

    expect_list <- list(a="INTEGER",
                        b="REAL",
                        c="INTEGER",
                        d="TEXT",
                        e="TEXT",
                        f="TEXT",
                        g="TEXT")

    mapply(function(input, expect) checkEquals(expect,
                                               sqliteDataType(input)),
           input_list, expect_list)
}
