## $Id$

S_SRC = zzz.R S4R.R dbObjectId.R SQLite.R SQLiteSupport.R 
All.R: $(S_SRC)
	cat $(S_SRC) > All.R
cp: 
	cp All.R ../../RSQLite/R

tags:  $(S_SRC)
	rtags.py $(S_SRC) > tags

clean:
	rm -rf All.R tags
