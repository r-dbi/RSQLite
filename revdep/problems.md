# Setup

## Platform

|setting  |value                        |
|:--------|:----------------------------|
|version  |R version 3.3.1 (2016-06-21) |
|system   |x86_64, linux-gnu            |
|ui       |X11                          |
|language |en_US:en                     |
|collate  |en_US.UTF-8                  |
|tz       |Europe/Zurich                |
|date     |2016-07-07                   |

## Packages

|package  |*  |version |date       |source                       |
|:--------|:--|:-------|:----------|:----------------------------|
|DBI      |   |0.4-1   |2016-05-08 |cran (@0.4-1)                |
|RSQLite  |   |1.0.0   |2016-07-06 |local (rstats-db/RSQLite@NA) |
|testthat |   |1.0.2   |2016-04-23 |cran (@1.0.2)                |

# Check results
20 packages with problems

## dplyr (0.5.0)
Maintainer: Hadley Wickham <hadley@rstudio.com>  
Bug reports: https://github.com/hadley/dplyr/issues

0 errors | 1 warning  | 2 notes

```
checking Rd cross-references ... WARNING
package ‘microbenchmark’ exists but was not installed under R >= 2.10.0 so xrefs cannot be checked

checking installed package size ... NOTE
  installed size is 15.9Mb
  sub-directories of 1Mb or more:
    libs  13.8Mb

checking dependencies in R code ... NOTE
Missing or unexported object: ‘RSQLite::rsqliteVersion’
```

## ecd (0.6.4)
Maintainer: Stephen H-T. Lihn <stevelihn@gmail.com>

1 error  | 0 warnings | 0 notes

```
checking package dependencies ... ERROR
Package required but not available: ‘Rmpfr’

See section ‘The DESCRIPTION file’ in the ‘Writing R Extensions’
manual.
```

## filematrix (1.1.0)
Maintainer: Andrey A Shabalin <ashabalin@vcu.edu>  
Bug reports: https://github.com/andreyshabalin/filematrix/issues

0 errors | 1 warning  | 0 notes

```
checking re-building of vignette outputs ... WARNING
Error in re-building vignettes:
  ...
Quitting from lines 2-23 (Best_Prectices.Rmd) 
Error: processing vignette 'Best_Prectices.Rmd' failed with diagnostics:
could not find function "doc_date"
Execution halted

```

## freqweights (1.0.2)
Maintainer: Emilio Torres-Manzanera <torres@uniovi.es>

1 error  | 0 warnings | 0 notes

```
checking whether package ‘freqweights’ can be installed ... ERROR
Installation failed.
See ‘/home/muelleki/git/R/RSQLite/revdep/checks/freqweights.Rcheck/00install.out’ for details.
```

## gcbd (0.2.5)
Maintainer: Dirk Eddelbuettel <edd@debian.org>

0 errors | 1 warning  | 3 notes

```
checking re-building of vignette outputs ... WARNING
Error in re-building vignettes:
  ...
Loading required package: RSQLite
Loading required package: DBI
Loading required package: plyr
Loading required package: reshape

Attaching package: ‘reshape’

The following objects are masked from ‘package:plyr’:

    rename, round_any

Loading required package: lattice
Warning in packageDescription("gputools") :
  no package 'gputools' was found
Error: processing vignette 'gcbd.Rnw' failed with diagnostics:
at gcbd.Rnw:860, subscript out of bounds
Execution halted


checking package dependencies ... NOTE
Package suggested but not available for checking: ‘gputools’

checking dependencies in R code ... NOTE
Packages in Depends field not imported from:
  ‘RSQLite’ ‘lattice’ ‘plyr’ ‘reshape’
  These packages need to be imported from (in the NAMESPACE file)
  for when this namespace is loaded but not attached.

checking R code for possible problems ... NOTE
createDatabase: no visible global function definition for ‘dbDriver’
createDatabase: no visible global function definition for
  ‘dbBuildTableDefinition’
createDatabase: no visible global function definition for ‘dbConnect’
createDatabase: no visible global function definition for ‘dbGetQuery’
createDatabase: no visible global function definition for
  ‘dbDisconnect’
databaseResult: no visible global function definition for ‘dbConnect’
databaseResult: no visible global function definition for ‘dbDriver’
... 74 lines ...
qrBenchmarkgputools: no visible global function definition for ‘gpuQr’
svdBenchmarkgputools: no visible global function definition for
  ‘gpuSvd’
Undefined global functions or variables:
  coef dbBuildTableDefinition dbConnect dbDisconnect dbDriver
  dbGetQuery dbWriteTable ddply gpuMatMult gpuQr gpuSvd legend lm lu
  matplot melt par rnorm trellis.par.get trellis.par.set
Consider adding
  importFrom("graphics", "legend", "matplot", "par")
  importFrom("stats", "coef", "lm", "rnorm")
to your NAMESPACE file.
```

## maGUI (1.0)
Maintainer: Dhammapal Bharne <dhammapalb@uohyd.ac.in>

1 error  | 0 warnings | 0 notes

```
checking package dependencies ... ERROR
Packages required but not available:
  ‘pdInfoBuilder’ ‘convert’ ‘marray’ ‘GEOquery’ ‘GEOmetadb’ ‘RBGL’
  ‘limma’ ‘genefilter’ ‘simpleaffy’ ‘impute’ ‘oligo’ ‘beadarray’ ‘lumi’
  ‘GOstats’ ‘globaltest’ ‘WGCNA’ ‘ssize’

See section ‘The DESCRIPTION file’ in the ‘Writing R Extensions’
manual.
```

## oce (0.9-18)
Maintainer: Dan Kelley <Dan.Kelley@Dal.Ca>  
Bug reports: https://github.com/dankelley/oce/issues?
        sort=created&direction=desc&state=open

2 errors | 0 warnings | 0 notes

```
checking examples ... ERROR
Running examples in ‘oce-Ex.R’ failed
The error most likely occurred in:

> base::assign(".ptime", proc.time(), pos = "CheckExEnv")
> ### Name: read.oce
> ### Title: Read an oceanographic data file
> ### Aliases: read.oce
> ### Keywords: misc
> 
> ### ** Examples
> 
> library(oce)
> x <- read.oce(system.file("extdata", "ctd.cnv", package="oce"))
Warning in read.ctd.sbe(file, processingLog = processingLog, ...) :
  converted temperature from IPTS-68 to ITS-90
> plot(x) # summary with TS and profiles
Error in if (!is.null(x@metadata$startTime) && 4 < nchar(x@metadata$startTime)) mtext(format(x@metadata$startTime,  : 
  missing value where TRUE/FALSE needed
Calls: plot -> plot -> .local
Execution halted

checking tests ... ERROR
Running the tests in ‘tests/testthat.R’ failed.
Last 13 lines of output:
  `cs` not equal to `cs2`.
  Component "longitude": names for current but not for target
  Component "latitude": names for current but not for target
  
  
  testthat results ================================================================
  OK: 538 SKIPPED: 1 FAILED: 1
  1. Failure: lonlat2map() near Cape Split (@test_map.R#62) 
  
  Error: testthat unit tests failed
  In addition: Warning message:
  Deprecated: please use `expect_lt()` instead 
  Execution halted
```

## pitchRx (1.8.2)
Maintainer: Carson Sievert <cpsievert1@gmail.com>  
Bug reports: http://github.com/cpsievert/pitchRx/issues

1 error  | 0 warnings | 1 note 

```
checking whether package ‘pitchRx’ can be installed ... ERROR
Installation failed.
See ‘/home/muelleki/git/R/RSQLite/revdep/checks/pitchRx.Rcheck/00install.out’ for details.

checking package dependencies ... NOTE
Package suggested but not available for checking: ‘ggsubplot’
```

## ProjectTemplate (0.6)
Maintainer: Kirill Mueller <krlmlr+r@mailbox.org>  
Bug reports: https://github.com/johnmyleswhite/ProjectTemplate/issues

1 error  | 0 warnings | 2 notes

```
checking tests ... ERROR
Running the tests in ‘tests/run-all.R’ failed.
Last 13 lines of output:
  
  
  testthat results ================================================================
  OK: 307 SKIPPED: 0 FAILED: 6
  1. Error: All elements have length 1 (@test-load.R#4) 
  2. Failure: Test full project into existing directory (@test-overwrite.R#5) 
  3. Error: Test full project into existing directory (@test-overwrite.R#9) 
  4. Failure: Test minimal project into existing directory with an unrelated entry (@test-overwrite.R#45) 
  5. Error: Test minimal project into existing directory with an unrelated entry (@test-overwrite.R#53) 
  6. Failure: Test failure creating project into existing directory with an unrelated entry if merge.existing is not set (@test-overwrite.R#75) 
  
  Error: testthat unit tests failed
  Execution halted

checking DESCRIPTION meta-information ... NOTE
Malformed Title field: should not end in a period.

checking R code for possible problems ... NOTE
.check.version: no visible global function definition for
  ‘compareVersion’
create.project: no visible global function definition for ‘untar’
csv.reader: no visible global function definition for ‘unzip’
csv.reader: no visible global function definition for ‘read.csv’
csv2.reader: no visible global function definition for ‘unzip’
csv2.reader: no visible global function definition for ‘read.csv’
sql.reader: no visible global function definition for ‘modifyList’
test.project: no visible global function definition for
... 6 lines ...
wsv.reader: no visible global function definition for ‘unzip’
wsv.reader: no visible global function definition for ‘read.table’
Undefined global functions or variables:
  compareVersion download.file modifyList packageVersion read.csv
  read.table setNames untar unzip
Consider adding
  importFrom("stats", "setNames")
  importFrom("utils", "compareVersion", "download.file", "modifyList",
             "packageVersion", "read.csv", "read.table", "untar",
             "unzip")
to your NAMESPACE file.
```

## rplexos (1.1.4)
Maintainer: Eduardo Ibanez <edu.ibanez@gmail.com>  
Bug reports: https://github.com/NREL/rplexos/issues

1 error  | 1 warning  | 0 notes

```
checking examples ... ERROR
Running examples in ‘rplexos-Ex.R’ failed
The error most likely occurred in:

> base::assign(".ptime", proc.time(), pos = "CheckExEnv")
> ### Name: process_folder
> ### Title: Convert PLEXOS files to SQLite databases
> ### Aliases: process_folder process_input process_solution
> 
> ### ** Examples
> 
> # Process the folder with the solution file provided by rplexos
> location <- location_solution_rplexos()
> process_folder(location)
Warning: `rbind_list()` is deprecated. Please use `bind_rows()` instead.
> 
> # Process the folder with the input file provided by rplexos
> location2 <- location_input_rplexos()
> process_folder(location2)
Error in sqliteSendQuery(con, statement, bind.data) : 
  error in statement: no such column: comp_collection
Calls: process_folder ... .local -> sqliteGetQuery -> sqliteSendQuery -> .Call
Execution halted

checking re-building of vignette outputs ... WARNING
Error in re-building vignettes:
  ...
Quitting from lines 186-187 (rplexos.Rmd) 
Error: processing vignette 'rplexos.Rmd' failed with diagnostics:
error in statement: no such column: comp_collection
Execution halted

```

## RQDA (0.2-7)
Maintainer: HUANG Ronggui <ronggui.huang@gmail.com>

1 error  | 0 warnings | 1 note 

```
checking whether package ‘RQDA’ can be installed ... ERROR
Installation failed.
See ‘/home/muelleki/git/R/RSQLite/revdep/checks/RQDA.Rcheck/00install.out’ for details.

checking package dependencies ... NOTE
Package which this enhances but not available for checking: ‘rjpod’
```

## smnet (2.0)
Maintainer: Alastair Rushworth <alastair.rushworth@strath.ac.uk>

1 error  | 0 warnings | 0 notes

```
checking whether package ‘smnet’ can be installed ... ERROR
Installation failed.
See ‘/home/muelleki/git/R/RSQLite/revdep/checks/smnet.Rcheck/00install.out’ for details.
```

## sqldf (0.4-10)
Maintainer: G. Grothendieck <ggrothendieck@gmail.com>  
Bug reports: http://groups.google.com/group/sqldf

0 errors | 1 warning  | 2 notes

```
checking whether package ‘sqldf’ can be installed ... WARNING
Found the following significant warnings:
  Warning: no DISPLAY variable so Tk is not available
See ‘/home/muelleki/git/R/RSQLite/revdep/checks/sqldf.Rcheck/00install.out’ for details.

checking dependencies in R code ... NOTE
'library' or 'require' call to ‘tcltk’ in package code.
  Please use :: or requireNamespace() instead.
  See section 'Suggested packages' in the 'Writing R Extensions' manual.

checking R code for possible problems ... NOTE
read.csv.sql: no visible global function definition for ‘download.file’
sqldf: no visible global function definition for ‘modifyList’
sqldf: no visible global function definition for ‘head’
Undefined global functions or variables:
  download.file head modifyList
Consider adding
  importFrom("utils", "download.file", "head", "modifyList")
to your NAMESPACE file.
```

## SSN (1.1.7)
Maintainer: Jay Ver Hoef <ver.hoef@SpatialStreamNetworks.com>

1 error  | 0 warnings | 0 notes

```
checking whether package ‘SSN’ can be installed ... ERROR
Installation failed.
See ‘/home/muelleki/git/R/RSQLite/revdep/checks/SSN.Rcheck/00install.out’ for details.
```

## stream (1.2-2)
Maintainer: Michael Hahsler <mhahsler@lyle.smu.edu>  
Bug reports: https://r-forge.r-project.org/projects/clusterds/

1 error  | 0 warnings | 0 notes

```
checking whether package ‘stream’ can be installed ... ERROR
Installation failed.
See ‘/home/muelleki/git/R/RSQLite/revdep/checks/stream.Rcheck/00install.out’ for details.
```

## survey (3.30-3)
Maintainer: "Thomas Lumley" <t.lumley@auckland.ac.nz>

0 errors | 1 warning  | 2 notes

```
checking Rd cross-references ... WARNING
Missing link or links in documentation object 'svycoplot.Rd':
  ‘xyplot’

Missing link or links in documentation object 'svycoxph.Rd':
  ‘coxph’ ‘predict.coxph’

Missing link or links in documentation object 'svylogrank.Rd':
  ‘strata’

See section 'Cross-references' in the 'Writing R Extensions' manual.


checking dependencies in R code ... NOTE
'library' or 'require' calls in package code:
  ‘CompQuadForm’ ‘KernSmooth’ ‘MASS’ ‘Matrix’ ‘RODBC’ ‘hexbin’
  ‘lattice’ ‘parallel’ ‘quantreg’ ‘splines’ ‘survival’
  Please use :: or requireNamespace() instead.
  See section 'Suggested packages' in the 'Writing R Extensions' manual.
Package in Depends field not imported from: ‘grid’
  These packages need to be imported from (in the NAMESPACE file)
  for when this namespace is loaded but not attached.

checking R code for possible problems ... NOTE
.biglogrank: no visible global function definition for ‘coxph’
.biglogrank: no visible global function definition for ‘coxph.detail’
.logrank: no visible global function definition for ‘coxph’
.logrank: no visible global function definition for ‘coxph.detail’
Dcheck_multi_subset: no visible global function definition for ‘as’
HRDcheck: no visible global function definition for ‘as’
[.pps : <anonymous>: no visible global function definition for ‘Matrix’
[.twophase2 : <anonymous>: no visible global function definition for
  ‘Matrix’
... 151 lines ...
  coxph.detail coxph.fit current.viewport davies dbConnect dbDisconnect
  dbDriver dbGetQuery dpik dpill farebrother getS3method ginv
  gplot.hexbin grey grid.hexagons hexbin is is.Surv isIdCurrent locpoly
  mclapply odbcConnect odbcDriverConnect odbcReConnect panel.xyplot
  polr rgb rq sqlQuery survSplit untangle.specials xyplot
Consider adding
  importFrom("grDevices", "col2rgb", "grey", "rgb")
  importFrom("methods", "as", "is")
  importFrom("utils", "getS3method")
to your NAMESPACE file (and ensure that your DESCRIPTION Imports field
contains 'methods').
```

## trackeR (0.0.3)
Maintainer: Hannah Frick <h.frick@ucl.ac.uk>

1 error  | 0 warnings | 0 notes

```
checking whether package ‘trackeR’ can be installed ... ERROR
Installation failed.
See ‘/home/muelleki/git/R/RSQLite/revdep/checks/trackeR.Rcheck/00install.out’ for details.
```

## TSdata (2015.4-2)
Maintainer: Paul Gilbert <pgilbert.ttv9z@ncf.ca>

0 errors | 1 warning  | 0 notes

```
checking re-building of vignette outputs ... WARNING
Error in re-building vignettes:
  ...
SDMX meaning: No results matching the query.
Jul 07, 2016 12:45:07 AM it.bancaditalia.oss.sdmx.client.custom.RestSdmx20Client getData
SEVERE: Exception caught parsing results from call to provider OECD
Jul 07, 2016 12:45:07 AM it.bancaditalia.oss.sdmx.client.custom.RestSdmx20Client getData
INFO: Exception: 
it.bancaditalia.oss.sdmx.util.SdmxException: Connection failed. HTTP error code : 404, message: Not Found
SDMX meaning: No results matching the query.
... 8 lines ...
	at sun.reflect.NativeMethodAccessorImpl.invoke(NativeMethodAccessorImpl.java:62)
	at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
	at java.lang.reflect.Method.invoke(Method.java:498)
	at RJavaTools.invokeMethod(RJavaTools.java:386)


Error: processing vignette 'Guide.Stex' failed with diagnostics:
 chunk 3 
Error in .local(serIDs, con, ...) : 
  QNA.CAN.PPPGDP.CARSA.Q error: java.lang.NullPointerException
Execution halted
```

## tweet2r (1.0)
Maintainer: Pau Aragó <parago@uji.es>

1 error  | 0 warnings | 0 notes

```
checking whether package ‘tweet2r’ can be installed ... ERROR
Installation failed.
See ‘/home/muelleki/git/R/RSQLite/revdep/checks/tweet2r.Rcheck/00install.out’ for details.
```

## vmsbase (2.1.3)
Maintainer: Lorenzo D'Andrea <support@vmsbase.org>

1 error  | 0 warnings | 0 notes

```
checking whether package ‘vmsbase’ can be installed ... ERROR
Installation failed.
See ‘/home/muelleki/git/R/RSQLite/revdep/checks/vmsbase.Rcheck/00install.out’ for details.
```

