#' Support Functions
#' 
#' These functions are the workhorses behind the RSQLite package, but users
#' need not invoke these directly.
#' 
#' 
#' @aliases sqliteInitDriver sqliteDriverInfo sqliteDescribeDriver
#' sqliteCloseDriver sqliteNewConnection sqliteConnectionInfo
#' sqliteDescribeConnection sqliteCloseConnection sqliteExecStatement
#' sqliteFetch sqliteQuickSQL sqliteTransactionStatement sqliteResultInfo
#' sqliteDescribeResult sqliteCloseResult sqliteReadTable sqliteWriteTable
#' sqliteImportFile sqliteTableFields sqliteDataType sqliteFetchOneColumn
#' .SQLitePkgName .SQLitePkgVersion .SQLite.NA.string SQLITE_RWC SQLITE_RW
#' SQLITE_RO last.warning .conflicts.OK
#' @param max.con positive integer specifying maximum number of open
#' connections.  The default is 10.  Note that since SQLite is embedded in
#' R/S-Plus connections are simple, very efficient direct C calls.
#' @param fetch.default.rec default number of rows to fetch (move to R/S-Plus).
#' This default is used in \code{sqliteFetch}.  The default is 500.
#' @param force.reload logical indicating whether to re-initialize the driver.
#' This may be useful if you want to change the defaults (e.g.,
#' \code{fetch.default.rec}).  Note that the driver is a singleton (subsequent
#' inits just returned the previously initialized driver, thus this argument).
#' @param obj any of the SQLite DBI objects (e.g., \code{SQLiteConnection},
#' \code{SQLiteResult}).
#' @param what character vector of metadata to extract, e.g., "version",
#' "statement", "isSelect".
#' @param verbose logical controlling how much information to display.
#' Defaults to \code{FALSE}.
#' @param drv an \code{SQLiteDriver} object as produced by \code{sqliteInit}.
#' @param con an \code{SQLiteConnection} object as produced by
#' \code{sqliteNewConnection}.
#' @param res an \code{SQLiteResult} object as produced by by
#' \code{sqliteExecStatement}.
#' @param dbname character string with the SQLite database file name (SQLite,
#' like Microsoft's Access, stores an entire database in one file).
#' @param loadable.extensions logical describing whether loadable extensions
#' will be enabled for this connection. The default is FALSE.
#' @param flags An integer that will be interpretted as a collection of flags
#' by the SQLite API.  If \code{NULL}, the flags will default to
#' \code{SQLITE_RWC} which will open the file in read/write mode and create the
#' file if it does not exist.  You can use \code{SQLITE_RW} to open in
#' read/write mode and \code{SQLITE_RO} to open in read only mode.  In both
#' cases, an error is raised if the database file does not already exist.  See
#' \url{http://sqlite.org/c3ref/open.html} for more details.
#' @param shared.cache logical describing whether shared-cache mode should be
#' enabled on the SQLite driver. The default is FALSE.
#' @param bind.data a data frame which will be used to bind variables in the
#' statement.
#' @param cache_size positive integer to pass to the \code{PRAGMA cache_size};
#' this changes the maximum number of disk pages that SQLite will hold in
#' memory (SQLite's default is 2000 pages).
#' @param synchronous values the \code{PRAGMA synchronous} flag, possible
#' values are 0, 1, or 2 or the corresponding strings "OFF", "NORMAL", or
#' "FULL".  The \code{RSQLite} package uses a default of 0 (OFF), although
#' SQLite's default is 2 (FULL) as of version 3.2.8.  Users have reported
#' significant speed ups using \code{sychronous="OFF"}, and the SQLite
#' documentation itself implies considerably improved performance at the very
#' modest risk of database corruption in the unlikely case of the operating
#' system (\emph{not} the R application) crashing.
#' @param vfs The name of the SQLite virtual filesystem module to use.  If
#' \code{NULL}, the default module will be used.  Module availability depends
#' on your operating as summarized by the following table:
#' 
#' \tabular{rlll}{ module \tab OSX \tab Unix (not OSX) \tab Windows\cr
#' "unix-none" \tab Y \tab Y \tab N\cr "unix-dotfile" \tab Y \tab Y \tab N\cr
#' "unix-flock" \tab Y \tab N \tab N\cr "unix-afp" \tab Y \tab N \tab N\cr
#' "unix-posix" \tab Y \tab N \tab N\cr } See
#' \url{http://www.sqlite.org/compile.html} for details.
#' @param force logical indicating whether to close a connection that has open
#' result sets.  The default is \code{FALSE}.
#' @param statement character string holding SQL statements.
#' @param n number of rows to fetch from the given result set. A value of -1
#' indicates to retrieve all the rows.  The default of 0 specifies to extract
#' whatever the \code{fetch.default.rec} was specified during driver
#' initialization \code{sqliteInit}.
#' @param name character vector of names (table names, fields, keywords).
#' @param value a data.frame.
#' @param field.types a list specifying the mapping from R/S-Plus fields in the
#' data.frame \code{value} to SQL data types.  The default is
#' \code{sapply(value,SQLDataType)}, see \code{SQLiteSQLType}.
#' @param row.names a logical specifying whether to prepend the \code{value}
#' data.frame row names or not.  The default is \code{TRUE}.
#' @param check.names a logical specifying whether to convert DBMS field names
#' into legal S names. Default is \code{TRUE}.
#' @param overwrite logical indicating whether to replace the table \code{name}
#' with the contents of the data.frame \code{value}.  The defauls is
#' \code{FALSE}.
#' @param append logical indicating whether to append \code{value} to the
#' existing table \code{name}.
#' @param header logical, does the input file have a header line?  Default is
#' the same heuristic used by \code{read.table}, i.e., TRUE if the first line
#' has one fewer column that the second line.
#' @param nrows number of lines to rows to import using \code{read.table} from
#' the input file to create the proper table definition. Default is 50.
#' @param sep field separator character.
#' @param eol end-of-line separator.
#' @param skip number of lines to skip before reading data in the input file.
#' @param \dots placeholder for future use.
#' @return \code{sqliteInitDriver} returns an \code{SQLiteDriver} object.
#' 
#' \code{sqliteDriverInfo} returns a list of name-value metadata pairs.
#' 
#' \code{sqliteDescribeDriver} returns \code{NULL} (displays the object's
#' metadata).
#' 
#' \code{sqliteNewConnection} returns an \code{SQLiteConnection} object.
#' 
#' \code{sqliteConnectionInfo}returns a list of name-value metadata pairs.
#' 
#' \code{sqliteDescribeConnection} returns \code{NULL} (displays the object's
#' metadata).
#' 
#' \code{sqliteCloseConnection} returns a logical indicating whether the
#' operation succeeded or not.
#' 
#' \code{sqliteExecStatement} returns an \code{SQLiteResult} object.
#' 
#' \code{sqliteFetch} returns a data.frame.
#' 
#' \code{sqliteQuickSQL} returns either a data.frame if the \code{statement} is
#' a \code{select}-like or NULL otherwise.
#' 
#' \code{sqliteDescribeResult} returns \code{NULL} (displays the object's
#' metadata).
#' 
#' \code{sqliteCloseResult} returns a logical indicating whether the operation
#' succeeded or not.
#' 
#' \code{sqliteReadTable} returns a data.frame with the contents of the DBMS
#' table.
#' 
#' \code{sqliteWriteTable} returns a logical indicating whether the operation
#' succeeded or not.
#' 
#' \code{sqliteImportFile} returns a logical indicating whether the operation
#' succeeded or not.
#' 
#' \code{sqliteTableFields} returns a character vector with the table
#' \code{name} field names.
#' 
#' \code{sqliteDataType} retuns a character string with the closest SQL data
#' type.  Note that SQLite is typeless, so this is mostly for creating table
#' that are compatible across RDBMS.
#' 
#' \code{sqliteResultInfo} returns a list of name-value metadata pairs.
#' @section Constants: \code{.SQLitePkgName} (currently \code{"RSQLite"}),
#' \code{.SQLitePkgVersion} (the R package version),
#' \code{.SQLitecle.NA.string} (character that SQLite uses to denote
#' \code{NULL} on input), \code{.conflicts.OK}.
#' @name sqliteSupport
NULL


#' Summarize an SQLite object
#' 
#' These methods are straight-forward implementations of the corresponding
#' generic functions.
#' 
#' 
#' @name summary-methods
#' @aliases coerce-methods summary-methods format-methods show-methods
#' coerce,dbObjectId,integer-method coerce,dbObjectId,numeric-method
#' coerce,dbObjectId,character-method
#' coerce,SQLiteConnection,SQLiteDriver-method
#' coerce,SQLiteResult,SQLiteConnection-method format,dbObjectId-method
#' print,dbObjectId-method show,dbObjectId-method summary,SQLiteObject-method
#' summary,SQLiteDriver-method summary,SQLiteConnection-method
#' summary,SQLiteResult-method
#' @docType methods
#' @section Methods: \describe{
#' 
#' \item{object = "DBIObject"}{ Provides relevant metadata information on
#' \code{object}, for instance, the SQLite server file, the SQL statement
#' associated with a result set, etc.  } \item{from}{object to be coerced}
#' \item{to}{coercion class} \item{x}{object to \code{format} or \code{print}
#' or \code{show}} }
NULL


