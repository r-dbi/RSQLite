# Package index

## All functions

- [`SQLite()`](https://rsqlite.r-dbi.org/reference/SQLite.md)
  [`dbConnect(`*`<SQLiteConnection>`*`)`](https://rsqlite.r-dbi.org/reference/SQLite.md)
  [`dbConnect(`*`<SQLiteDriver>`*`)`](https://rsqlite.r-dbi.org/reference/SQLite.md)
  [`dbDisconnect(`*`<SQLiteConnection>`*`)`](https://rsqlite.r-dbi.org/reference/SQLite.md)
  : Connect to an SQLite database
- [`datasetsDb()`](https://rsqlite.r-dbi.org/reference/datasetsDb.md) :
  A sample sqlite database
- [`dbReadTable(`*`<SQLiteConnection>`*`,`*`<character>`*`)`](https://rsqlite.r-dbi.org/reference/dbReadTable.md)
  : Read a database table
- [`dbWriteTable(`*`<SQLiteConnection>`*`,`*`<character>`*`,`*`<character>`*`)`](https://rsqlite.r-dbi.org/reference/dbWriteTable.md)
  [`dbWriteTable(`*`<SQLiteConnection>`*`,`*`<character>`*`,`*`<data.frame>`*`)`](https://rsqlite.r-dbi.org/reference/dbWriteTable.md)
  : Write a local data frame or file to the database
- [`initExtension()`](https://rsqlite.r-dbi.org/reference/initExtension.md)
  : Add useful extension functions
- [`rsqliteVersion()`](https://rsqlite.r-dbi.org/reference/rsqliteVersion.md)
  : RSQLite version
- [`dbBegin(`*`<SQLiteConnection>`*`)`](https://rsqlite.r-dbi.org/reference/sqlite-transaction.md)
  [`dbCommit(`*`<SQLiteConnection>`*`)`](https://rsqlite.r-dbi.org/reference/sqlite-transaction.md)
  [`dbRollback(`*`<SQLiteConnection>`*`)`](https://rsqlite.r-dbi.org/reference/sqlite-transaction.md)
  [`sqliteIsTransacting()`](https://rsqlite.r-dbi.org/reference/sqlite-transaction.md)
  : SQLite transaction management
- [`sqliteCopyDatabase()`](https://rsqlite.r-dbi.org/reference/sqliteCopyDatabase.md)
  : Copy a SQLite database
- [`sqliteSetBusyHandler()`](https://rsqlite.r-dbi.org/reference/sqliteSetBusyHandler.md)
  : Configure what SQLite should do when the database is locked
