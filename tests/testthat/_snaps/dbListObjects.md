# dbListObjects snapshot - empty memory db

    Code
      dbListObjects(con)
    Output
              table is_prefix
      1 <Id> "main"      TRUE

# dbListObjects snapshot - with prefix

    Code
      dbListObjects(con, prefix = Id(schema = "main"))
    Output
                    table is_prefix
      1 <Id> "main"."bar"     FALSE
      2 <Id> "main"."foo"     FALSE

