SQLITE_CFLAGS= \
 -DSQLITE_ENABLE_RTREE \
 -DSQLITE_ENABLE_FTS3 \
 -DSQLITE_ENABLE_FTS3_PARENTHESIS \
 -DSQLITE_ENABLE_FTS5 \
 -DSQLITE_SOUNDEX

all: extension-functions.o sqlite3.o

sqlite3.o: sqlite3.h
	$(CC) $(CFLAGS) $(SQLITE_CFLAGS) -c -o sqlite3.o sqlite3.c

extension-functions.o: sqlite3ext.h

clean:
	rm -f *.o
