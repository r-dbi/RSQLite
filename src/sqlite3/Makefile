all: libsqlite3.a
libsqlite3.a: libsqlite3.a(sqlite3.o) libsqlite3.a(extension-functions.o)
	${RANLIB} $@

sqlite3.o: sqlite3.h
extension-functions.o: sqlite3ext.h

clean:
	rm -f sqlite3.a *.o
