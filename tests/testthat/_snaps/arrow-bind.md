# parameters that don't match the placeholders fail as for dbBind()

    Code
      bind_arrow_stream(res, nanoarrow::basic_array_stream(list(nanoarrow::as_nanoarrow_array(
        1:3))))
    Condition
      Error:
      ! Parameters must be an Arrow stream of struct arrays, with a column per placeholder.

# a type that can't be bound fails before any row runs

    Code
      bind_arrow_stream(res, stream)
    Condition
      Error:
      ! Can't bind parameter 1 of Arrow type date64.

---

    Code
      bind_arrow_stream(res, stream)
    Condition
      Error:
      ! Can't bind parameter 1 of Arrow type list<: int32>.

