all: extension-functions.o sqlite3.o

sqlite3.o: sqlite3.h
extension-functions.o: sqlite3ext.h

clean:
	rm -f sqlite3.a *.o
