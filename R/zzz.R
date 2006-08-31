## $Id$
".conflicts.OK" <- TRUE

## these are needed while source'ing the package (prior
## to library.dyname).
library(methods, warn.conflicts = FALSE)
library(DBI, warn.conflicts = FALSE)

".First.lib" <- 
function(lib, pkg)
{
   ## need to dyn.load sqlite.dll before we attempt to load
   ## RSQLite.dll  -- there's got to be a better way...

   if(.Platform$OS.type=="windows"){
      if(!is.loaded(symbol.C("sqlite3_libversion")))
         dyn.load(system.file("libs", "sqlite3.dll", package = "RSQLite"))
   }

   library.dynam("RSQLite", pkg, lib)
   library(methods, warn.conflicts = FALSE)
   library(DBI, warn.conflicts = FALSE)
}
