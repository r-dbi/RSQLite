# vim: set syntax=make
RSQLite.so: RS-DBI.o RS-SQLite.o
	R CMD SHLIB -o RSQLite.so RS-DBI.o RS-SQLite.o

RS-DBI.o: S4R.h RS-DBI.h RS-DBI.c
	R CMD COMPILE RS-DBI.c

RS-SQLite.o: S4R.h RS-SQLite.h RS-SQLite.c
	R CMD COMPILE RS-SQLite.c

clean:
	rm -rf RS-DBI.o RS-SQLite.o RSQLite.so RSQLite.a RSQLite.dll libsqlite3.a  RSQLite_res.o Makedeps
