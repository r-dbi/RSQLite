# Configure what SQLite should do when the database is locked

When a transaction cannot lock the database, because it is already
locked by another one, SQLite by default throws an error:
`database is locked`. This behavior is usually not appropriate when
concurrent access is needed, typically when multiple processes write to
the same database.

`sqliteSetBusyHandler()` lets you set a timeout or a handler for these
events. When setting a timeout, SQLite will try the transaction multiple
times within this timeout. To set a timeout, pass an integer scalar to
`sqliteSetBusyHandler()`.

Another way to set a timeout is to use a `PRAGMA`, e.g. the SQL query

    PRAGMA busy_timeout=3000

sets the busy timeout to three seconds.

## Usage

``` r
sqliteSetBusyHandler(dbObj, handler)
```

## Arguments

- dbObj:

  A
  [SQLiteConnection](https://rsqlite.r-dbi.org/reference/SQLiteConnection-class.md)
  object.

- handler:

  Specifies what to do when the database is locked by another
  transaction. It can be:

  - `NULL`: fail immediately,

  - an integer scalar: this is a timeout in milliseconds that
    corresponds to `PRAGMA busy_timeout`,

  - an R function: this function is called with one argument, see
    details below.

## Value

Invisible `NULL`.

## Details

Note that SQLite currently does *not* schedule concurrent transactions
fairly. If multiple transactions are waiting on the same database, any
one of them can be granted access next. Moreover, SQLite does not
currently ensure that access is granted as soon as the database is
available. Make sure that you set the busy timeout to a high enough
value for applications with high concurrency and many writes.

If the `handler` argument is a function, then it is used as a callback
function. When the database is locked, this will be called with a single
integer, which is the number of calls for same locking event. The
callback function must return an integer scalar. If it returns `0L`,
then no additional attempts are made to access the database, and an
error is thrown. Otherwise another attempt is made to access the
database and the cycle repeats.

Handler callbacks are useful for debugging concurrent behavior, or to
implement a more sophisticated busy algorithm. The latter is currently
considered experimental in RSQLite. If the callback function fails, then
RSQLite will print a warning, and the transaction is aborted with a
"database is locked" error.

Note that every database connection has its own busy timeout or handler
function.

Calling `sqliteSetBusyHandler()` on a connection that is not connected
is an error.

## See also

<https://www.sqlite.org/c3ref/busy_handler.html>
