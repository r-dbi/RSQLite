#' @include SQLiteConnection.R
NULL

#' Write a local data frame or file to the database
#'
#' Functions for writing data frames or delimiter-separated files
#' to database tables.
#'
#' @seealso
#' The corresponding generic function [DBI::dbWriteTable()].
#'
#' @export
#' @rdname dbWriteTable
#' @param conn a \code{\linkS4class{SQLiteConnection}} object, produced by
#'   [DBI::dbConnect()]
#' @param name a character string specifying a table name. SQLite table names
#'   are \emph{not} case sensitive, e.g., table names `ABC` and `abc`
#'   are considered equal.
#' @param value a data.frame (or coercible to data.frame) object or a
#'   file name (character).  In the first case, the data.frame is
#'   written to a temporary file and then imported to SQLite; when `value`
#'   is a character, it is interpreted as a file name and its contents imported
#'   to SQLite.
#' @param row.names A logical specifying whether the `row.names` should be
#'   output to the output DBMS table; if `TRUE`, an extra field whose name
#'   will be whatever the R identifier `"row.names"` maps to the DBMS (see
#'   [DBI::make.db.names()]). If `NA` will add rows names if
#'   they are characters, otherwise will ignore.
#' @param overwrite a logical specifying whether to overwrite an existing table
#'   or not. Its default is `FALSE`.
#' @param append a logical specifying whether to append to an existing table
#'   in the DBMS.  Its default is `FALSE`.
#' @param field.types character vector of named  SQL field types where
#'   the names are the names of new table's columns. If missing, types inferred
#'   with [DBI::dbDataType()]).
#' @param temporary a logical specifying whether the new table should be
#'   temporary. Its default is `FALSE`.
#' @param ... Needed for compatibility with generic. Otherwise ignored.
#' @details In a primary key column qualified with
#' \href{https://www.sqlite.org/autoinc.html}{`AUTOINCREMENT`}, missing
#' values will be assigned the next largest positive integer,
#' while nonmissing elements/cells retain their value.  If the
#' autoincrement column exists in the data frame
#' passed to the `value` argument,
#' the `NA` elements are overwritten.
#' Similarly, if the key column is not present in the data frame, all
#' elements are automatically assigned a value.
#' @export
#' @examples
#' con <- dbConnect(SQLite())
#' dbWriteTable(con, "mtcars", mtcars)
#' dbReadTable(con, "mtcars")
#'
#' # A zero row data frame just creates a table definition.
#' dbWriteTable(con, "mtcars2", mtcars[0, ])
#' dbReadTable(con, "mtcars2")
#'
#' dbDisconnect(con)
setMethod("dbWriteTable", c("SQLiteConnection", "character", "data.frame"),
  function(conn, name, value, ...,
           row.names = pkgconfig::get_config("RSQLite::row.names.table", FALSE),
           overwrite = FALSE, append = FALSE,
           field.types = NULL, temporary = FALSE) {

    row.names <- compatRowNames(row.names)

    if ((!is.logical(row.names) && !is.character(row.names)) || length(row.names) != 1L)  {
      stopc("`row.names` must be a logical scalar or a string")
    }
    if (!is.logical(overwrite) || length(overwrite) != 1L || is.na(overwrite))  {
      stopc("`overwrite` must be a logical scalar")
    }
    if (!is.logical(append) || length(append) != 1L || is.na(append))  {
      stopc("`append` must be a logical scalar")
    }
    if (!is.logical(temporary) || length(temporary) != 1L)  {
      stopc("`temporary` must be a logical scalar")
    }
    if (overwrite && append) {
      stopc("overwrite and append cannot both be TRUE")
    }
    if (!is.null(field.types) && !(is.character(field.types) && !is.null(names(field.types)) && !anyDuplicated(names(field.types)))) {
      stopc("`field.types` must be a named character vector with unique names, or NULL")
    }
    if (append && !is.null(field.types)) {
      stopc("Cannot specify field.types with append = TRUE")
    }

    name <- check_quoted_identifier(name)

    dbBegin(conn, name = "dbWriteTable")
    on.exit(dbRollback(conn, name = "dbWriteTable"))

    found <- dbExistsTable(conn, name)
    if (found && !overwrite && !append) {
      stop("Table ", name, " exists in database, and both overwrite and",
        " append are FALSE", call. = FALSE)
    }
    if (found && overwrite) {
      dbRemoveTable(conn, name)
    }

    value <- sql_data(value, row.names = row.names)

    if (!found || overwrite) {
      fields <- field_def(conn, value, field.types)

      dbCreateTable(
        conn = conn,
        name = name,
        fields = fields,
        temporary = temporary
      )
    } else if (append) {
      col_names <- dbListFields(conn, name)
      value <- match_col(value, col_names)
    }

    if (nrow(value) > 0) {
      dbAppendTable(
        conn = conn,
        name = name,
        value = value
      )
    }

    dbCommit(conn, name = "dbWriteTable")
    on.exit(NULL)
    invisible(TRUE)
  }
)

match_col <- function(value, col_names) {
  if (length(col_names) == length(value)) {
    if (!all(names(value) == col_names)) {
      if (all(tolower(names(value)) == tolower(col_names))) {
        warning("Column names will be matched ignoring character case",
                call. = FALSE)
        names(value) <- col_names
        return(value)
      }
    }
  }

  if (!all(names(value) %in% col_names)) {
    stop("Columns ",
      paste0("`", setdiff(names(value), col_names), "`", collapse = ", "),
      " not found",
      call. = FALSE
    )
  }

  value
}

field_def <- function(conn, data, field_types) {
  # Match column names with compatibility rules
  new_field_types <- match_col(field_types, names(data))

  # Automatic types for all other fields
  auto_field_types <- db_data_types(conn, data[setdiff(names(data), names(field_types))])
  field_types[names(auto_field_types)] <- auto_field_types

  # Reorder
  field_types <- field_types[names(data)]

  field_types
}

db_data_types <- function(conn, data) {
  vcapply(data, function(x) dbDataType(conn, x))
}

#' @param header is a logical indicating whether the first data line (but see
#'   `skip`) has a header or not.  If missing, it value is determined
#'   following [read.table()] convention, namely, it is set to TRUE if
#'   and only if the first row has one fewer field that the number of columns.
#' @param sep The field separator, defaults to `','`.
#' @param eol The end-of-line delimiter, defaults to `'\n'`.
#' @param skip number of lines to skip before reading the data. Defaults to 0.
#' @param nrows Number of rows to read to determine types.
#' @param colClasses Character vector of R type names, used to override
#'   defaults when imputing classes from on-disk file.
#' @export
#' @rdname dbWriteTable
setMethod("dbWriteTable", c("SQLiteConnection", "character", "character"),
  function(conn, name, value, ..., field.types = NULL, overwrite = FALSE,
           append = FALSE, header = TRUE, colClasses = NA, row.names = FALSE,
           nrows = 50, sep = ",", eol="\n", skip = 0, temporary = FALSE) {
    if(overwrite && append)
      stop("overwrite and append cannot both be TRUE")
    value <- path.expand(value)

    row.names <- compatRowNames(row.names)

    dbBegin(conn, name = "dbWriteTable")
    on.exit(dbRollback(conn, name = "dbWriteTable"))

    found <- dbExistsTable(conn, name)
    if (found && !overwrite && !append) {
      stop("Table ", name, " exists in database, and both overwrite and",
           " append are FALSE", call. = FALSE)
    }
    if (found && overwrite) {
      dbRemoveTable(conn, name)
    }

    if (!found || overwrite) {
      # Initialise table with first `nrows` lines
      if (is.null(field.types)) {
        fields <- utils::read.table(
          value, sep = sep, header = header, skip = skip, nrows = nrows,
          na.strings = "\\N", comment.char = "", colClasses = colClasses,
          stringsAsFactors = FALSE)
      } else {
        fields <- field.types
      }
      sql <- sqlCreateTable(conn, name, fields, row.names = FALSE,
                            temporary = temporary)
      dbExecute(conn, sql)
    }

    skip <- skip + as.integer(header)
    connection_import_file(conn@ptr, name, value, sep, eol, skip)

    dbCommit(conn, name = "dbWriteTable")
    on.exit(NULL)
    invisible(TRUE)
  }
)

#' @rdname SQLiteConnection-class
#' @export
setMethod("dbAppendTable", "SQLiteConnection", function(conn, name, value, ...,
                                                        row.names = NULL) {
  dbBegin(conn, name = "dbAppendTable")
  on.exit(dbRollback(conn, name = "dbAppendTable"))

  out <- callNextMethod()

  on.exit(NULL)
  dbCommit(conn, name = "dbAppendTable")

  out
})

#' @rdname SQLiteConnection-class
#' @export
setMethod("sqlData", "SQLiteConnection", function(con, value,
                                                  row.names = pkgconfig::get_config("RSQLite::row.names.query", FALSE),
                                                  ...) {
  value <- sql_data(value, row.names)
  value <- quote_string(value, con)

  value
})

check_quoted_identifier <- function(name) {
  name
}


#' Read a database table
#'
#' Returns the contents of a database table given by name as a data frame.
#'
#' Note that the data frame returned by `dbReadTable()` only has
#' primitive data, e.g., it does not coerce character data to factors.
#'
#' @seealso
#' The corresponding generic function [DBI::dbReadTable()].
#'
#' @return A data frame.
#'
#' @param conn a \code{\linkS4class{SQLiteConnection}} object, produced by
#'   [DBI::dbConnect()]
#' @param name a character string specifying a table name. SQLite table names
#'   are \emph{not} case sensitive, e.g., table names `ABC` and `abc`
#'   are considered equal.
#' @param check.names If `TRUE`, the default, column names will be
#'   converted to valid R identifiers.
#' @param select.cols  Deprecated, do not use.
#' @param ... Needed for compatibility with generic. Otherwise ignored.
#' @inheritParams DBI::sqlRownamesToColumn
#' @export
#' @examples
#' library(DBI)
#' db <- RSQLite::datasetsDb()
#' dbReadTable(db, "mtcars")
#' dbReadTable(db, "mtcars", row.names = FALSE)
#' dbDisconnect(db)
setMethod("dbReadTable", c("SQLiteConnection", "character"),
  function(conn, name, ...,
           row.names = pkgconfig::get_config("RSQLite::row.names.table", FALSE),
           check.names = TRUE, select.cols = NULL) {
    name <- check_quoted_identifier(name)

    row.names <- compatRowNames(row.names)

    if ((!is.logical(row.names) && !is.character(row.names)) || length(row.names) != 1L)  {
      stopc("`row.names` must be a logical scalar or a string")
    }

    if (!is.logical(check.names) || length(check.names) != 1L)  {
      stopc("`check.names` must be a logical scalar")
    }

    if (is.null(select.cols)) {
      select.cols = "*"
    } else {
      warning_once("`select.cols` is deprecated, use `dbGetQuery()` for complex queries.",
        call. = FALSE)
    }

    name <- dbQuoteIdentifier(conn, name)
    out <- dbGetQuery(conn, paste("SELECT", select.cols, "FROM", name),
                      row.names = row.names)

    if (check.names) {
      names(out) <- make.names(names(out), unique = TRUE)
    }

    out
  }
)


#' @rdname SQLiteConnection-class
#' @export
#' @param temporary If `TRUE`, only temporary tables are considered.
#' @param fail_if_missing If `FALSE`, `dbRemoveTable()` succeeds if the
#'   table doesn't exist.
setMethod("dbRemoveTable", c("SQLiteConnection", "character"),
  function(conn, name, ..., temporary = FALSE, fail_if_missing = TRUE) {
    name <- check_quoted_identifier(name)
    name <- dbQuoteIdentifier(conn, name)

    if (fail_if_missing) {
      extra <- ""
    } else {
      extra <- "IF EXISTS "
    }
    if (temporary) {
      extra <- paste0(extra, "temp.")
    }

    dbExecute(conn, paste0("DROP TABLE ", extra, name))
    invisible(TRUE)
  }
)


#' @rdname SQLiteConnection-class
#' @export
setMethod(
  "dbExistsTable", c("SQLiteConnection", "character"),
  function(conn, name, ...) {
    stopifnot(length(name) == 1L)
    rs <- sqliteListTablesWithName(conn, name)
    on.exit(dbClearResult(rs), add = TRUE)

    nrow(dbFetch(rs, 1L)) > 0
  }
)


#' @rdname SQLiteConnection-class
#' @export
setMethod("dbListTables", "SQLiteConnection", function(conn, ...) {
  rs <- sqliteListTables(conn)
  on.exit(dbClearResult(rs), add = TRUE)

  dbFetch(rs)$name
})

sqliteListTables <- function(conn) {
  sql <- sqliteListTablesQuery(conn)
  dbSendQuery(conn, sql)
}

sqliteListTablesWithName <- function(conn, name) {
  # Also accept quoted identifiers
  id <- as.list(dbUnquoteIdentifier(conn, dbQuoteIdentifier(conn, name))[[1]]@name)
  schema <- id[["schema"]]
  table <- id[["table"]]

  sql <- sqliteListTablesQuery(conn, schema, SQL("$name"))
  rs <- dbSendQuery(conn, sql)
  dbBind(rs, list(name = tolower(table)))
  rs
}

sqliteListTablesQuery <- function(conn, schema = NULL, name = NULL) {
  if (is.null(schema)) {
    info_sql <- "(SELECT * FROM sqlite_master UNION ALL SELECT * FROM sqlite_temp_master)"
  } else {
    info_sql <- paste0("(SELECT * FROM ", dbQuoteIdentifier(conn, schema), ".sqlite_master)")
  }

  SQL(paste0("SELECT name ",
    "FROM ", info_sql, " ",
    "WHERE (type = 'table' OR type = 'view') ",
    if (!is.null(name)) paste0("AND (lower(name) = ", dbQuoteString(conn, name), ") "),
    "ORDER BY name",
    sep = "\n"
  ))
}

#' @rdname SQLiteConnection-class
#' @export
setMethod("dbDataType", "SQLiteConnection", function(dbObj, obj, ...) {
  dbDataType(SQLite(), obj, ...)
})
