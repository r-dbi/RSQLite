# a result is fetched either as data frames or as an Arrow stream

    Code
      dbFetch(res)
    Condition
      Error:
      ! Can't fetch a result as a data frame after fetching it as an Arrow stream.
      i Fetch each result in one way only, or send the query again.

---

    Code
      read_arrow_stream(res)
    Condition
      Error:
      ! Can't fetch a result as an Arrow stream after fetching it as a data frame.
      i Fetch each result in one way only, or send the query again.

