# Build the SQL CREATE TABLE definition as a string

The output SQL statement is a simple `CREATE TABLE` suitable for
`dbGetQuery`

## Usage

``` r
sqliteBuildTableDefinition(
  con,
  name,
  value,
  field.types = NULL,
  row.names = pkgconfig::get_config("RSQLite::row.names.query", FALSE)
)
```

## Arguments

- con:

  A database connection.

- name:

  Name of the new SQL table

- value:

  A data.frame, for which we want to create a table.

- field.types:

  Optional, named character vector of the types for each field in
  `value`

- row.names:

  Logical. Should row.name of `value` be exported as a `row_names`
  field? Default is `TRUE`

## Value

An SQL string
