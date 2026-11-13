# a dictionary index out of range fails at its row

    Code
      bind_arrow_stream(res, stream)
    Condition
      Error:
      ! Can't bind the dictionary index 2 of parameter 1 in row 2, out of range for 2 values.

---

    Code
      bind_arrow_stream(res, stream)
    Condition
      Error:
      ! Can't bind the dictionary index -1 of parameter 1 in row 2, out of range for 2 values.

---

    Code
      bind_arrow_stream(res, stream)
    Condition
      Error:
      ! Can't bind the dictionary index 255 of parameter 1 in row 2, out of range for 2 values.

---

    Code
      bind_arrow_stream(res, stream)
    Condition
      Error:
      ! Can't bind the dictionary index -1 of parameter 1 in row 2, out of range for 2 values.

---

    Code
      bind_arrow_stream(res, stream)
    Condition
      Error:
      ! Can't bind the dictionary index 18446744073709551615 of parameter 1 in row 2, out of range for 2 values.

---

    Code
      bind_arrow_stream(res, stream)
    Condition
      Error:
      ! Can't bind the dictionary index 99 of parameter 1 in row 2, out of range for 1 values.

# values beyond SQLite's length limit fail with their parameter and row

    Code
      bind_arrow_stream(res, stream)
    Condition
      Error:
      ! Can't bind the value of 31 bytes of parameter 2 in row 2, beyond SQLite's length limit of 30 bytes.

---

    Code
      bind_arrow_stream(res, stream)
    Condition
      Error:
      ! Can't bind the value of 31 bytes of parameter 2 in row 2, beyond SQLite's length limit of 30 bytes.

---

    Code
      bind_arrow_stream(res, stream)
    Condition
      Error:
      ! Can't bind the value of 31 bytes of parameter 2 in row 2, beyond SQLite's length limit of 30 bytes.

---

    Code
      bind_arrow_stream(res, stream)
    Condition
      Error:
      ! Can't bind the value of 31 bytes of parameter 2 in row 2, beyond SQLite's length limit of 30 bytes.

---

    Code
      bind_arrow_stream(res, stream)
    Condition
      Error:
      ! Can't bind the value of 31 bytes of parameter 2 in row 2, beyond SQLite's length limit of 30 bytes.

# a stream that reads the rows of the result itself fails up front

    Code
      bind_arrow_stream(res, stream)
    Condition
      Error:
      ! Can't bind a result to an Arrow stream of its own rows.

# results whose parameters read each other's rows fail up front

    Code
      bind_arrow_stream(results[[1]], stream)
    Condition
      Error:
      ! Can't bind a result to an Arrow stream of a result whose parameters read the rows of this one.

---

    Code
      bind_arrow_stream(results[[1]], stream)
    Condition
      Error:
      ! Can't bind a result to an Arrow stream of a result whose parameters read the rows of this one.

