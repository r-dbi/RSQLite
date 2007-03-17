".First.lib" <- 
function(libname, pkgname)
{
    require("methods")
   ## need to dyn.load sqlite.dll before we attempt to load
   ## RSQLite.dll  -- there's got to be a better way...

##    if(.Platform$OS.type=="windows"){
##       if(!is.loaded("sqlite3_libversion"))
##          dyn.load(system.file("libs", "sqlite3.dll", package = "RSQLite"))
##    }
##    library.dynam("RSQLite", package=pkgname)
}

.onLoad <- .First.lib
