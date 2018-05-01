# DBI

Version: 0.8

## Newly broken

*   checking examples ... ERROR
    ```
    Running examples in ‘DBI-Ex.R’ failed
    The error most likely occurred in:
    
    > ### Name: DBI-package
    > ### Title: DBI: R Database Interface
    > ### Aliases: DBI DBI-package
    > 
    > ### ** Examples
    > 
    > RSQLite::SQLite()
    Error in loadNamespace(i, c(lib.loc, .libPaths()), versionCheck = vI[[i]]) : 
      namespace ‘DBI’ 0.8 is already loaded, but >= 0.8.0.9001 is required
    Calls: :: ... tryCatch -> tryCatchList -> tryCatchOne -> <Anonymous>
    Execution halted
    ```

# MonetDBLite

Version: 0.5.1

## Newly broken

*   checking examples ... ERROR
    ```
    ...
    
    The following objects are masked from ‘package:stats’:
    
        filter, lag
    
    The following objects are masked from ‘package:base’:
    
        intersect, setdiff, setequal, union
    
    > # To connect to a database first create a src:
    > dbdir <- file.path(tempdir(), "dplyrdir")
    > my_db <- MonetDBLite::src_monetdblite(dbdir)
    > 
    > # copy some data to DB
    > my_iris  <- copy_to(my_db, iris)
    Warning: Connection is garbage-collected, use dbDisconnect() to avoid this.
    Error in .local(conn, statement, ...) : 
      Unable to execute statement 'ROLLBACK'.
    Server says 'Invalid connection'.
    Calls: copy_to ... dbRollback -> dbRollback -> dbSendQuery -> dbSendQuery -> .local
    Execution halted
    ```

# DECIPHER

Version: 2.4.0

## Newly broken

*   checking examples ... ERROR
    ```
    Running examples in ‘DECIPHER-Ex.R’ failed
    The error most likely occurred in:
    
    > ### Name: Add2DB
    > ### Title: Add Data to a Database
    > ### Aliases: Add2DB
    > 
    > ### ** Examples
    > 
    > # Create a sequence database
    > gen <- system.file("extdata", "Bacteria_175seqs.gen", package="DECIPHER")
    > dbConn <- dbConnect(SQLite(), ":memory:")
    > Seqs2DB(gen, "GenBank", dbConn, "Bacteria")
    
    Reading GenBank file chunk 1Error: `field.types` must be a named character vector with unique names, or NULL
    Execution halted
    ```

*   checking running R code from vignettes ...
    ```
    ...
    
    > dbConn <- dbConnect(SQLite(), ":memory:")
    
    > Seqs2DB(gb, "GenBank", dbConn, "Bacteria")
    
    Reading GenBank file chunk 1
      When sourcing ‘DesignProbes.R’:
    Error: `field.types` must be a named character vector with unique names, or NULL
    Execution halted
    when running code in ‘DesignSignatures.Rnw’
      ...
    > dbConn <- "<<path to write sequence database>>"
    
    > dbConn <- dbConnect(SQLite(), ":memory:")
    
    > N <- Seqs2DB(fas, "FASTA", dbConn, "")
    
    Reading FASTA file chunk 1
      When sourcing ‘DesignSignatures.R’:
    Error: `field.types` must be a named character vector with unique names, or NULL
    Execution halted
    ```

