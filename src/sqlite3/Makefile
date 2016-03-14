CFLAGS= \
 -DSQLITE_ENABLE_RTREE \
 -DSQLITE_ENABLE_FTS3 \
 -DSQLITE_ENABLE_FTS3_PARENTHESIS \
 -DSQLITE_ENABLE_FTS5 \
 -DSQLITE_SOUNDEX

all: libsqlite3.a
libsqlite3.a: libsqlite3.a(sqlite3.o) libsqlite3.a(extension-functions.o)
	${RANLIB} $@

sqlite3.o: sqlite3.h sqlite3ext.h
extension-functions.o:

clean:
	rm -f sqlite3.a *.o
