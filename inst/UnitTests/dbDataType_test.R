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
    ## unhandled classes end up as text
    checkEquals("TEXT", sqliteDataType(Sys.Date()))
}

test_blob <- function()
{
    checkEquals("BLOB", sqliteDataType(list(raw(1))))
    checkEquals("BLOB", sqliteDataType(list()))
}
