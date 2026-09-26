# dbSendQueryArrow() returns a SQLiteResultArrow

    Code
      rs
    Output
      <SQLiteResultArrow>
        SQL  SELECT 1 AS a, 'x' AS b, 1.5 AS c, x'0102' AS d, NULL AS e
        ROWS Fetched: 0 [incomplete]
             Changed: 0

---

    Code
      rs
    Output
      <SQLiteResultArrow>
        SQL  SELECT 1 AS a, 'x' AS b, 1.5 AS c, x'0102' AS d, NULL AS e
        ROWS Fetched: 1 [complete]
             Changed: 0

