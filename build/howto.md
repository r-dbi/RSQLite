# Update version of SQLite #

1. Download latest amalgamation from
[http://sqlite.org/download.html].
2. Unzip and copy `.c` and `.h` files into
`src/sqlite`. Exclude `shell.c`. Currently we track three files:
`sqlite3.c`, `sqlite3.h`, and `sqlite3ext.h`.
3. Update `DESCRIPTION` for included version of SQLite
4. Update `inst/UnitTests/dbGetInfo_test.R` for expected SQLite
version.
5. Update `inst/NEWS`
6. Build and check
