# the warning message lists columns and rows

    Code
      df <- as.data.frame(dbGetQueryArrow(con, "SELECT * FROM t"))
    Condition
      Warning:
      Mixed types in 2 columns, values converted to the column types:
      * Column `x` (double): 1 string value converted (row 3)
      * Column `y` (utf8): 1 blob value not valid UTF-8, NA (row 4)

