The following notes were generated across my local OS X install and ubuntu running on travis-ci. Response to NOTEs across three platforms below.

* I am taking over maintenance of RSQLite. I'ved asked Seth Falcon to 
  email you to confirm this.

* checking CRAN incoming feasibility ... NOTE
  Possibly mis-spelled words in DESCRIPTION:
    DBI (14:46)
    SQLite (3:8, 12:46, 13:29, 15:24)
    
  These are correct spellings

* checking compiled code ... NOTE
  File ‘/Users/hadley/Documents/databases/RSQLite.Rcheck/RSQLite/libs/RSQLite.so’:
    Found ‘___stderrp’, possibly from ‘stderr’ (C)
      Object: ‘sqlite-all.o’

  This is in C code from the embedded SQLite database.
  
I also ran R CMD check on all downstream dependencies on R-devel. All packages that I install past R CMD check without ERRORs, WARNINGs, or NOTE. (See below for packages that I couldn't install). I informed all downstream maintainers of the pending update one month ago, giving plenty of time for fixes.

Downstream dependency failure ---------------------------------------------------

CITAN =================================================================== 
 *  checking package dependencies ... ERROR
Package required but not available: ‘RGtk2’

See the information on DESCRIPTION files in the chapter ‘Creating R
packages’ of the ‘Writing R Extensions’ manual. 

marmap ================================================================== 
 *  checking package dependencies ... ERROR
Package required but not available: ‘ncdf’

See the information on DESCRIPTION files in the chapter ‘Creating R
packages’ of the ‘Writing R Extensions’ manual. 

MUCflights ============================================================== 
 *  checking package dependencies ... ERROR
Package required but not available: ‘XML’

See the information on DESCRIPTION files in the chapter ‘Creating R
packages’ of the ‘Writing R Extensions’ manual. 

pitchRx ================================================================= 
 *  checking package dependencies ... ERROR
Package required but not available: ‘XML2R’

Package suggested but not available for checking: ‘rgl’

See the information on DESCRIPTION files in the chapter ‘Creating R
packages’ of the ‘Writing R Extensions’ manual. 

rangeMapper ============================================================= 
 *  checking package dependencies ... ERROR
Package required but not available: ‘rgdal’

Package suggested but not available for checking: ‘rgeos’

See the information on DESCRIPTION files in the chapter ‘Creating R
packages’ of the ‘Writing R Extensions’ manual. 

RQDA ==================================================================== 
 *  checking package dependencies ... ERROR
Packages required but not available: ‘gWidgetsRGtk2’ ‘RGtk2’

Package which this enhances but not available for checking: ‘rjpod’

See the information on DESCRIPTION files in the chapter ‘Creating R
packages’ of the ‘Writing R Extensions’ manual. 

snplist ================================================================= 
 *  checking package dependencies ... ERROR
Package required but not available: ‘biomaRt’

See the information on DESCRIPTION files in the chapter ‘Creating R
packages’ of the ‘Writing R Extensions’ manual. 


