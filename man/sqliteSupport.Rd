% $Id$
\name{sqliteSupport}                % adapted from ROracle
\alias{sqliteInitDriver}            % driver-related function
\alias{sqliteDriverInfo}
\alias{sqliteDescribeDriver}
\alias{sqliteCloseDriver}           % connection-related
\alias{sqliteNewConnection}
\alias{sqliteConnectionInfo}
\alias{sqliteDescribeConnection}
\alias{sqliteCloseConnection}
\alias{sqliteExecStatement}         % result-related
\alias{sqliteFetch}
\alias{sqliteQuickSQL}
\alias{sqliteTransactionStatement}
\alias{sqliteResultInfo}
\alias{sqliteDescribeResult}
\alias{sqliteCloseResult}
\alias{sqliteReadTable}
\alias{sqliteWriteTable}            % convenience functions
\alias{sqliteImportFile}
\alias{sqliteTableFields}
\alias{sqliteDataType}
\alias{sqliteFetchOneColumn}
\alias{.SQLitePkgName}              % constants
\alias{.SQLitePkgVersion}
\alias{.SQLitePkgRCS}
\alias{.SQLite.NA.string}
\alias{last.warning}
%\alias{.SQLiteSQLKeywords}
\alias{.conflicts.OK}
%\non_function{}
\title{Support Functions}
\description{
   These functions are the workhorses behind the RSQLite package, but
   users need not invoke these directly.
}
\usage{
   ## SQLiteDriver-related
   sqliteInitDriver(max.con=16, fetch.default.rec = 500, force.reload=FALSE,
                    shared.cache=FALSE)
   sqliteDriverInfo(obj, what, ...)
   sqliteDescribeDriver(obj, verbose = FALSE, ...)
   sqliteCloseDriver(drv, ...)

   ## SQLiteConnection-related
   sqliteNewConnection(drv, dbname, loadable.extensions=FALSE, cache_size=NULL,
                       synchronous=0)
   sqliteConnectionInfo(obj, what, ...)
   sqliteDescribeConnection(obj, verbose = FALSE, ...)
   sqliteCloseConnection(con, ...)

   ## SQLiteResult-related
   sqliteExecStatement(con, statement, bind.data=NULL)
   sqliteTransactionStatement(con, statement)
   sqliteFetch(res, n=0, ...)
   sqliteQuickSQL(con, statement, bind.data=NULL, ...)
   sqliteResultInfo(obj, what, ...)
   sqliteDescribeResult(obj, verbose = FALSE, ...)
   sqliteCloseResult(res, ...)

   ## data mappings and convenience functions
   sqliteDataType(obj, ...)
   sqliteReadTable(con, name, row.names = "row_names", check.names = TRUE, ...)
   sqliteImportFile(con, name, value, field.types, overwrite=FALSE,
      append=FALSE, header, row.names, nrows=50, sep=",", eol="\n",
      skip = 0, ...)
   sqliteWriteTable(con, name, value, row.names = TRUE,
                    overwrite = FALSE, append = FALSE,
                    field.types = NULL, ...)
   sqliteTableFields(con, name, ...)
}
\arguments{
\item{max.con}{
   positive integer specifying maximum number of open connections.
   The default is 10.  Note that since SQLite is embedded in R/S-Plus
   connections are simple, very efficient direct C calls.
}
\item{fetch.default.rec}{
   default number of rows to fetch (move to R/S-Plus).  This default is
   used in \code{sqliteFetch}.
   The default is 500.
}
\item{force.reload}{
   logical indicating whether to re-initialize the driver.  This may be
   useful if you want to change the defaults (e.g., \code{fetch.default.rec}).
   Note that the driver is a singleton (subsequent inits just returned the
   previously initialized driver, thus this argument).
}
\item{obj}{
   any of the SQLite DBI objects (e.g., \code{SQLiteConnection},
   \code{SQLiteResult}).
}
\item{what}{
   character vector of metadata to extract, e.g., "version", "statement",
   "isSelect".
}
\item{verbose}{
   logical controlling how much information to display.
   Defaults to \code{FALSE}.
}
\item{drv}{
   an \code{SQLiteDriver} object as produced by \code{sqliteInit}.
}
\item{con}{
   an \code{SQLiteConnection} object as produced by \code{sqliteNewConnection}.
}
\item{res}{
   an \code{SQLiteResult} object as produced by by \code{sqliteExecStatement}.
}
\item{dbname}{
   character string with the SQLite database file name (SQLite, like
   Microsoft's Access, stores an entire database in one file).
}
\item{loadable.extensions}{
   logical describing whether loadable extensions will be enabled for this
   connection. The default is FALSE.
}
\item{shared.cache}{
   logical describing whether shared-cache mode should be enabled on the SQLite
   driver. The default is FALSE.
}
\item{bind.data}{
   a data frame which will be used to bind variables in the statement.
}
\item{cache_size}{
   positive integer to pass to the \code{PRAGMA cache_size};  this
   changes the maximum number of disk pages that SQLite will hold in
   memory (SQLite's default is 2000 pages).
}
\item{synchronous}{
  values the \code{PRAGMA synchronous} flag, possible values are
  0, 1, or 2 or the corresponding strings "OFF", "NORMAL", or "FULL".
  The \code{RSQLite} package uses a default of 0 (OFF), although
  SQLite's default is 2 (FULL) as of version 3.2.8.
  Users have reported significant speed ups using \code{sychronous="OFF"},
  and the SQLite documentation itself implies considerably improved
  performance at the very modest risk of database corruption in the
  unlikely case of the operating system (\emph{not} the R application)
  crashing.
}
%\item{max.results}{
%   positive integer indicating the maximum number of results that
%   SQLite connections will hold open.  The current default of 1
%   is hardcoded in the C code.
%}
\item{force}{
   logical indicating whether to close a connection that has open
   result sets.  The default is \code{FALSE}.
}
\item{statement}{
   character string holding SQL statements.
}
\item{n}{
   number of rows to fetch from the given result set. A value of -1
   indicates to retrieve all the rows.  The default of 0 specifies
   to extract whatever the \code{fetch.default.rec} was specified
   during driver initialization \code{sqliteInit}.
}
\item{name}{
   character vector of names (table names, fields, keywords).
}
\item{value}{
   a data.frame.
}
\item{field.types}{
   a list specifying the mapping from R/S-Plus fields in the data.frame
   \code{value} to SQL data types.  The default is
   \code{sapply(value,SQLDataType)}, see \code{SQLiteSQLType}.
}
\item{row.names}{
   a logical specifying whether to prepend the \code{value} data.frame
   row names or not.  The default is \code{TRUE}.
}
\item{check.names}{
   a logical specifying whether to convert DBMS field names into
   legal S names. Default is \code{TRUE}.
}
\item{overwrite}{
   logical indicating whether to replace the table \code{name} with
   the contents of the data.frame \code{value}.
   The defauls is \code{FALSE}.
}
\item{append}{
   logical indicating whether to append \code{value} to the existing
   table \code{name}.
}
\item{header}{
  logical, does the input file have a header line?  Default is the
  same heuristic used by \code{read.table}, i.e., TRUE if the first
  line has one fewer column that the second line.
}
\item{nrows}{
   number of lines to rows to import using \code{read.table} from the
  input file to create the proper table definition. Default is 50.
}
\item{sep}{field separator character.}
\item{eol}{end-of-line separator.}
\item{skip}{
   number of lines to skip before reading data in the input file.
}
\item{\dots}{
   placeholder for future use.
}
}
\value{
   \code{sqliteInitDriver} returns an \code{SQLiteDriver} object.

   \code{sqliteDriverInfo} returns a list of name-value metadata pairs.

   \code{sqliteDescribeDriver} returns \code{NULL} (displays the object's
   metadata).

   \code{sqliteCloseDriver} returns a logical indicating whether the
   operation succeeded or not.

   \code{sqliteNewConnection} returns an \code{SQLiteConnection} object.

   \code{sqliteConnectionInfo}returns a list of name-value metadata pairs.

   \code{sqliteDescribeConnection} returns \code{NULL} (displays the
   object's metadata).

   \code{sqliteCloseConnection} returns a logical indicating whether the
   operation succeeded or not.

   \code{sqliteExecStatement} returns an \code{SQLiteResult} object.

   \code{sqliteFetch} returns a data.frame.

   \code{sqliteQuickSQL} returns either a data.frame if the \code{statement} is
   a \code{select}-like or NULL otherwise.

   \code{sqliteDescribeResult} returns \code{NULL} (displays the object's
   metadata).

   \code{sqliteCloseResult} returns a logical indicating whether the
   operation succeeded or not.

   \code{sqliteReadTable}  returns a data.frame with the contents of the
   DBMS table.

   \code{sqliteWriteTable}  returns a logical indicating whether the
   operation succeeded or not.

   \code{sqliteImportFile}  returns a logical indicating whether the
   operation succeeded or not.

   \code{sqliteTableFields} returns a character vector with the
   table \code{name} field names.

   \code{sqliteDataType} retuns a character string with the closest
   SQL data type.  Note that SQLite is typeless, so this is mostly for
   creating table that are compatible across RDBMS.

   \code{sqliteResultInfo} returns a list of name-value metadata pairs.
}
\section{Constants}{
\code{.SQLitePkgName} (currently \code{"RSQLite"}),
\code{.SQLitePkgVersion} (the R package version),
\code{.SQLitePkgRCS} (the RCS revision),
\code{.SQLitecle.NA.string} (character that SQLite uses to
denote \code{NULL} on input),
%\code{.SQLiteSQLKeywords}    % TODO: should we add these?
\code{.conflicts.OK}.
%\non_function{}
}
\keyword{datasets}
\keyword{interface}
\keyword{database}
%\keyword{internal}
% vim:syntax=tex
