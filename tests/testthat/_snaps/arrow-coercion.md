# one warning per chunk names the columns, values and rows

    Code
      chunk <- fetch_arrow_chunk(res)
    Condition
      Warning:
      Values converted to the Arrow type of 4 columns:
      * Column `i` (int64): 2 text values converted (rows 3 and 5); 1 real value converted (row 4)
      * Column `s` (utf8): 1 blob value not valid UTF-8 or with a NUL byte, NULL instead (row 3); 2 integer values converted (rows 4 and 5)
      * Column `b` (binary): 1 text value converted (row 3); 1 integer value converted (row 5)
      * Column `n` (null): 1 integer value dropped by the null type (row 3); 1 text value dropped by the null type (row 4)

