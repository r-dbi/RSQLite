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
64 packages

## APSIM (0.9.0)
Maintainer: Justin Fainges <Justin.Fainges@csiro.au>

0 errors | 0 warnings | 0 notes

## archivist (2.0.4)
Maintainer: Przemyslaw Biecek <przemyslaw.biecek@gmail.com>  
Bug reports: https://github.com/pbiecek/archivist/issues

0 errors | 0 warnings | 2 notes

```
checking package dependencies ... NOTE
Package which this enhances but not available for checking: ‘archivist.github’

checking Rd cross-references ... NOTE
Package unavailable to check Rd xrefs: ‘archivist.github’
```

## BatchExperiments (1.4.1)
Maintainer: Michel Lang <michellang@gmail.com>  
Bug reports: https://github.com/tudo-r/BatchExperiments/issues

0 errors | 0 warnings | 2 notes

```
checking dependencies in R code ... NOTE
Unexported objects imported by ':::' calls:
  ‘BatchJobs:::addIntModulo’ ‘BatchJobs:::buffer’
  ‘BatchJobs:::checkDir’ ‘BatchJobs:::checkId’ ‘BatchJobs:::checkIds’
  ‘BatchJobs:::checkPart’ ‘BatchJobs:::createShardedDirs’
  ‘BatchJobs:::dbConnectToJobsDB’ ‘BatchJobs:::dbCreateJobStatusTable’
  ‘BatchJobs:::dbDoQuery’ ‘BatchJobs:::dbFindDone’
  ‘BatchJobs:::dbFindRunning’ ‘BatchJobs:::dbRemoveJobs’
  ‘BatchJobs:::dbSelectWithIds’ ‘BatchJobs:::getJobDirs’
  ‘BatchJobs:::getJobInfoInternal’ ‘BatchJobs:::getKillJob’
  ‘BatchJobs:::getListJobs’ ‘BatchJobs:::getRandomSeed’
  ‘BatchJobs:::getResult’ ‘BatchJobs:::isRegistryDir’
  ‘BatchJobs:::makeRegistryInternal’ ‘BatchJobs:::saveRegistry’
  ‘BatchJobs:::seeder’ ‘BatchJobs:::syncRegistry’
  See the note in ?`:::` about the use of this operator.

checking R code for possible problems ... NOTE
addExperiments.ExperimentRegistry: no visible global function
  definition for ‘is’
applyJobFunction.ExperimentRegistry: no visible global function
  definition for ‘setNames’
calcDynamic: no visible global function definition for ‘setNames’
checkExperimentRegistry: no visible global function definition for
  ‘head’
dbSummarizeExperiments: no visible global function definition for
  ‘setNames’
designIterator: no visible global function definition for ‘setNames’
getIndex : exprToIndex: no visible global function definition for
  ‘capture.output’
getProblemFilePaths: no visible global function definition for
  ‘setNames’
updateRegistry.ExperimentRegistry: no visible global function
  definition for ‘packageVersion’
Undefined global functions or variables:
  capture.output head is packageVersion setNames
Consider adding
  importFrom("methods", "is")
  importFrom("stats", "setNames")
  importFrom("utils", "capture.output", "head", "packageVersion")
to your NAMESPACE file (and ensure that your DESCRIPTION Imports field
contains 'methods').
```

## BatchJobs (1.6)
Maintainer: Bernd Bischl <bernd_bischl@gmx.net>  
Bug reports: https://github.com/tudo-r/BatchJobs/issues

0 errors | 0 warnings | 0 notes

## bibliospec (0.0.4)
Maintainer: Witold E. Wolski <wew@fgcz.ethz.ch>  
Bug reports: https://github.com/protViz/bibliospec/issues

0 errors | 0 warnings | 0 notes

## biglm (0.9-1)
Maintainer: Thomas Lumley <tlumley@u.washington.edu>

0 errors | 0 warnings | 5 notes

```
checking DESCRIPTION meta-information ... NOTE
Malformed Description field: should contain one or more complete sentences.

checking top-level files ... NOTE
Non-standard file/directory found at top level:
  ‘test’

checking dependencies in R code ... NOTE
Packages in Depends field not imported from:
  ‘DBI’ ‘methods’
  These packages need to be imported from (in the NAMESPACE file)
  for when this namespace is loaded but not attached.

checking foreign function calls ... NOTE
Call with DUP:
   .Fortran("regcf", as.integer(p), as.integer(p * p/2), bigQR$D, 
       bigQR$rbar, bigQR$thetab, bigQR$tol, beta = numeric(p), nreq = as.integer(nvar), 
       ier = integer(1), DUP = FALSE)
DUP is no longer supported and will be ignored.

checking R code for possible problems ... NOTE
bigglm.RODBC: no visible global function definition for ‘odbcQuery’
bigglm.RODBC : chunk: no visible global function definition for
  ‘odbcQuery’
bigglm.RODBC : chunk: no visible global function definition for
  ‘sqlGetResults’
bigglm,ANY-DBIConnection: no visible global function definition for
  ‘dbSendQuery’
bigglm,ANY-DBIConnection: no visible global function definition for
  ‘dbClearResult’
bigglm,ANY-DBIConnection : chunk: no visible global function definition
  for ‘dbClearResult’
bigglm,ANY-DBIConnection : chunk: no visible global function definition
  for ‘dbSendQuery’
bigglm,ANY-DBIConnection : chunk: no visible global function definition
  for ‘fetch’
Undefined global functions or variables:
  dbClearResult dbSendQuery fetch odbcQuery sqlGetResults

Found the following calls to data() loading into the global environment:
File ‘biglm/R/bigglm.R’:
  data(reset = TRUE)
  data(reset = FALSE)
See section ‘Good practice’ in ‘?data’.
```

## caroline (0.7.6)
Maintainer: David Schruth <caroline@hominine.net>

0 errors | 0 warnings | 3 notes

```
checking dependencies in R code ... NOTE
'library' or 'require' calls in package code:
  ‘MASS’ ‘RSQLite’ ‘grid’ ‘sm’
  Please use :: or requireNamespace() instead.
  See section 'Suggested packages' in the 'Writing R Extensions' manual.

checking R code for possible problems ... NOTE
.ci.median: no visible global function definition for ‘qbinom’
.ci.median: no visible global function definition for ‘median’
.ci.median: no visible global function definition for ‘pbinom’
.description: no visible global function definition for ‘var’
.description: no visible global function definition for ‘shapiro.test’
.description: no visible global function definition for ‘quantile’
.huber.NR: no visible global function definition for ‘median’
.kurtosis: no visible global function definition for ‘var’
.kurtosys: no visible global function definition for ‘var’
... 104 lines ...
  importFrom("graphics", "axis", "box", "identify", "image", "lines",
             "locator", "mtext", "par", "plot", "plot.new",
             "plot.window", "points", "polygon", "rect", "segments",
             "text", "title")
  importFrom("methods", "as")
  importFrom("stats", "median", "pbinom", "qbinom", "qnorm", "quantile",
             "runif", "sd", "shapiro.test", "var")
  importFrom("utils", "browseURL", "count.fields", "head", "read.delim",
             "write.table")
to your NAMESPACE file (and ensure that your DESCRIPTION Imports field
contains 'methods').

checking Rd cross-references ... NOTE
Package unavailable to check Rd xrefs: ‘limma’
```

## chunked (0.3)
Maintainer: Edwin de Jonge <edwindjonge@gmail.com>  
Bug reports: https://github.com/edwindj/chunked/issues

0 errors | 0 warnings | 0 notes

## CITAN (2015.12-2)
Maintainer: Marek Gagolewski <gagolews@ibspan.waw.pl>  
Bug reports: https://github.com/Rexamine/CITAN/issues

0 errors | 0 warnings | 0 notes

## CollapsABEL (0.10.8)
Maintainer: Kaiyin Zhong <kindlychung@gmail.com>  
Bug reports: https://bitbucket.org/kindlychung/collapsabel2/issues

0 errors | 0 warnings | 0 notes

## DBI (0.4-1)
Maintainer: Kirill Müller <krlmlr+r@mailbox.org>  
Bug reports: https://github.com/rstats-db/DBI/issues

0 errors | 0 warnings | 1 note 

```
checking S3 generic/method consistency ... NOTE
Found the following apparent S3 methods exported but not registered:
  print.list.pairs
See section ‘Registering S3 methods’ in the ‘Writing R Extensions’
manual.
```

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

## emuR (0.1.8)
Maintainer: Raphael Winkelmann <raphael@phonetik.uni-muenchen.de>  
Bug reports: https://github.com/IPS-LMU/emuR/issues

0 errors | 0 warnings | 0 notes

## etl (0.3.1)
Maintainer: Ben Baumer <ben.baumer@gmail.com>  
Bug reports: https://github.com/beanumber/etl/issues

0 errors | 0 warnings | 0 notes

## ETLUtils (1.3)
Maintainer: Jan Wijffels <jwijffels@bnosac.be>

0 errors | 0 warnings | 0 notes

## filehashSQLite (0.2-4)
Maintainer: Roger D. Peng <rpeng@jhsph.edu>

0 errors | 0 warnings | 3 notes

```
checking DESCRIPTION meta-information ... NOTE
Malformed Description field: should contain one or more complete sentences.
Packages listed in more than one of Depends, Imports, Suggests, Enhances:
  ‘filehash’ ‘DBI’
A package should be listed in only one of these fields.

checking dependencies in R code ... NOTE
Packages in Depends field not imported from:
  ‘RSQLite’ ‘methods’
  These packages need to be imported from (in the NAMESPACE file)
  for when this namespace is loaded but not attached.

checking R code for possible problems ... NOTE
createSQLite: no visible global function definition for ‘dbDriver’
createSQLite: no visible global function definition for ‘dbConnect’
createSQLite: no visible global function definition for
  ‘dbUnloadDriver’
createSQLite: no visible global function definition for ‘dbGetQuery’
initializeSQLite: no visible global function definition for ‘dbDriver’
initializeSQLite: no visible global function definition for ‘dbConnect’
initializeSQLite: no visible global function definition for ‘new’
dbDelete,filehashSQLite-character: no visible global function
... 7 lines ...
  definition for ‘dbGetQuery’
dbList,filehashSQLite: no visible global function definition for
  ‘dbGetQuery’
dbMultiFetch,filehashSQLite-character: no visible global function
  definition for ‘dbGetQuery’
Undefined global functions or variables:
  dbConnect dbDriver dbGetQuery dbUnloadDriver new
Consider adding
  importFrom("methods", "new")
to your NAMESPACE file (and ensure that your DESCRIPTION Imports field
contains 'methods').
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

## imputeMulti (0.5.3)
Maintainer: Alex Whitworth <whitworth.alex@gmail.com>

0 errors | 0 warnings | 1 note 

```
checking dependencies in R code ... NOTE
There are ::: calls to the package's namespace in its code. A package
  almost never needs to use ::: for its own objects:
  ‘count_compare’
```

## macleish (0.3.0)
Maintainer: Ben Baumer <ben.baumer@gmail.com>

0 errors | 0 warnings | 0 notes

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

## marmap (0.9.5)
Maintainer: Eric Pante <pante.eric@gmail.com>

0 errors | 0 warnings | 0 notes

## MonetDBLite (0.3.1)
Maintainer: Hannes Muehleisen <hannes@cwi.nl>  
Bug reports: https://github.com/hannesmuehleisen/MonetDBLite/issues

0 errors | 0 warnings | 1 note 

```
checking installed package size ... NOTE
  installed size is 24.6Mb
  sub-directories of 1Mb or more:
    libs  24.3Mb
```

## MUCflights (0.0-3)
Maintainer: Manuel Eugster <Manuel.Eugster@stat.uni-muenchen.de>

0 errors | 0 warnings | 3 notes

```
checking dependencies in R code ... NOTE
'library' or 'require' call to ‘XML’ which was already attached by Depends.
  Please remove these calls from your code.
Packages in Depends field not imported from:
  ‘NightDay’ ‘RSQLite’ ‘XML’ ‘geosphere’ ‘sp’
  These packages need to be imported from (in the NAMESPACE file)
  for when this namespace is loaded but not attached.

checking R code for possible problems ... NOTE
drawMap: no visible global function definition for ‘plot’
drawMap: no visible global function definition for ‘box’
drawMap: no visible global function definition for ‘points’
getFlights: no visible binding for global variable ‘htmlTreeParse’
getFlights: no visible binding for global variable ‘xpathSApply’
getFlights: no visible binding for global variable ‘xmlAttrs’
getFlights: no visible binding for global variable ‘free’
movie.routes: no visible global function definition for
  ‘txtProgressBar’
... 16 lines ...
routes: no visible global function definition for ‘gcIntermediate’
Undefined global functions or variables:
  box data dev.off distHaversine free gcIntermediate htmlTreeParse jpeg
  lines mtext plot points setTxtProgressBar text txtProgressBar
  xmlAttrs xpathSApply
Consider adding
  importFrom("grDevices", "dev.off", "jpeg")
  importFrom("graphics", "box", "lines", "mtext", "plot", "points",
             "text")
  importFrom("utils", "data", "setTxtProgressBar", "txtProgressBar")
to your NAMESPACE file.

checking Rd line widths ... NOTE
Rd file 'flights.Rd':
  \usage lines wider than 90 characters:
     flights(from = NULL, to = NULL, path = system.file("MUCflights.RData", package = "MUCflights"))

These lines will be truncated in the PDF manual.
```

## nutshell.bbdb (1.0)
Maintainer: Joseph Adler <rinanutshell@gmail.com>

0 errors | 0 warnings | 2 notes

```
checking installed package size ... NOTE
  installed size is 39.0Mb
  sub-directories of 1Mb or more:
    extdata  38.9Mb

checking DESCRIPTION meta-information ... NOTE
Malformed Description field: should contain one or more complete sentences.
Deprecated license: CC BY-NC-ND 3.0 US
```

## nutshell (2.0)
Maintainer: Joseph Adler <rinanutshell@gmail.com>

0 errors | 0 warnings | 3 notes

```
checking installed package size ... NOTE
  installed size is  8.8Mb
  sub-directories of 1Mb or more:
    data   8.7Mb

checking DESCRIPTION meta-information ... NOTE
Malformed Description field: should contain one or more complete sentences.
Deprecated license: CC BY-NC-ND 3.0 US

checking dependencies in R code ... NOTE
Packages in Depends field not imported from:
  ‘nutshell.audioscrobbler’ ‘nutshell.bbdb’
  These packages need to be imported from (in the NAMESPACE file)
  for when this namespace is loaded but not attached.
```

## oai (0.2.0)
Maintainer: Scott Chamberlain <myrmecocystus@gmail.com>  
Bug reports: https://github.com/sckott/oai/issues

0 errors | 0 warnings | 0 notes

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

## poplite (0.99.16)
Maintainer: Daniel Bottomly <bottomly@ohsu.edu>

0 errors | 0 warnings | 1 note 

```
checking R code for possible problems ... NOTE
filter_.Database: no visible global function definition for ‘stack’
get.starting.point : <anonymous>: no visible global function definition
  for ‘na.omit’
select_.Database: no visible global function definition for ‘stack’
tsl.to.graph: no visible global function definition for ‘stack’
join,Database: no visible global function definition for ‘stack’
join,Database : .get.select.cols: no visible global function definition
  for ‘setNames’
join,Database: no visible binding for global variable ‘new.ancil’
join,Database: no visible global function definition for ‘setNames’
Undefined global functions or variables:
  na.omit new.ancil setNames stack
Consider adding
  importFrom("stats", "na.omit", "setNames")
  importFrom("utils", "stack")
to your NAMESPACE file.
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

## quantmod (0.4-5)
Maintainer: Joshua M. Ulrich <josh.m.ulrich@gmail.com>  
Bug reports: https://github.com/joshuaulrich/quantmod/issues

0 errors | 0 warnings | 1 note 

```
checking R code for possible problems ... NOTE
Found the following calls to attach():
File ‘quantmod/R/attachSymbols.R’:
  attach(NULL, pos = pos, name = DB$name)
  attach(NULL, pos = pos, name = DB$name)
See section ‘Good practice’ in ‘?attach’.
```

## rangeMapper (0.3-0)
Maintainer: Mihai Valcu <valcu@orn.mpg.de>

0 errors | 0 warnings | 0 notes

## RecordLinkage (0.4-9)
Maintainer: Andreas Borg <borga@uni-mainz.de>

0 errors | 0 warnings | 0 notes

## refGenome (1.7.0)
Maintainer: Wolfgang Kaisers <kaisers@med.uni-duesseldorf.de>

0 errors | 0 warnings | 0 notes

## rgrass7 (0.1-8)
Maintainer: Roger Bivand <Roger.Bivand@nhh.no>

0 errors | 0 warnings | 0 notes

## RObsDat (16.03)
Maintainer: Dominik Reusser <reusser@pik-potsdam.de>

0 errors | 0 warnings | 1 note 

```
checking package dependencies ... NOTE
Package suggested but not available for checking: ‘SSOAP’
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

## rvertnet (0.4.4)
Maintainer: Scott Chamberlain <myrmecocystus@gmail.com>  
Bug reports: https://github.com/ropensci/rvertnet/issues

0 errors | 0 warnings | 0 notes

## scrime (1.3.3)
Maintainer: Holger Schwender <holger.schw@gmx.de>

0 errors | 0 warnings | 3 notes

```
checking package dependencies ... NOTE
Package suggested but not available for checking: ‘oligoClasses’

checking dependencies in R code ... NOTE
'library' or 'require' calls in package code:
  ‘MASS’ ‘oligoClasses’
  Please use :: or requireNamespace() instead.
  See section 'Suggested packages' in the 'Writing R Extensions' manual.

checking R code for possible problems ... NOTE
abf: no visible global function definition for ‘qnorm’
abf: no visible global function definition for ‘dnorm’
analyse.models: no visible global function definition for ‘read.table’
buildSNPannotation: no visible global function definition for ‘db’
buildSNPannotation: no visible global function definition for
  ‘dbListFields’
buildSNPannotation: no visible global function definition for
  ‘dbGetQuery’
chisqClass2: no visible global function definition for ‘pchisq’
... 48 lines ...
Undefined global functions or variables:
  as.dist db dbGetQuery dbListFields dist dnorm glm is mvrnorm pchisq
  pnorm predict qnorm rbinom read.table rgamma runif sd write.table
Consider adding
  importFrom("methods", "is")
  importFrom("stats", "as.dist", "dist", "dnorm", "glm", "pchisq",
             "pnorm", "predict", "qnorm", "rbinom", "rgamma", "runif",
             "sd")
  importFrom("utils", "read.table", "write.table")
to your NAMESPACE file (and ensure that your DESCRIPTION Imports field
contains 'methods').
```

## SEERaBomb (2016.1)
Maintainer: Tomas Radivoyevitch <radivot@ccf.org>

0 errors | 0 warnings | 0 notes

## SGP (1.5-0.0)
Maintainer: Damian W. Betebenner <dbetebenner@nciea.org>  
Bug reports: https://github.com/CenterForAssessment/SGP/issues

0 errors | 0 warnings | 0 notes

## smnet (2.0)
Maintainer: Alastair Rushworth <alastair.rushworth@strath.ac.uk>

1 error  | 0 warnings | 0 notes

```
checking whether package ‘smnet’ can be installed ... ERROR
Installation failed.
See ‘/home/muelleki/git/R/RSQLite/revdep/checks/smnet.Rcheck/00install.out’ for details.
```

## snplist (0.15)
Maintainer: Alexander Sibley <alexander.sibley@dm.duke.edu>

0 errors | 0 warnings | 0 notes

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

## sqliter (0.1.0)
Maintainer: Wilson Freitas <wilson.freitas@gmail.com>

0 errors | 0 warnings | 0 notes

## SSN (1.1.7)
Maintainer: Jay Ver Hoef <ver.hoef@SpatialStreamNetworks.com>

1 error  | 0 warnings | 0 notes

```
checking whether package ‘SSN’ can be installed ... ERROR
Installation failed.
See ‘/home/muelleki/git/R/RSQLite/revdep/checks/SSN.Rcheck/00install.out’ for details.
```

## storr (1.0.1)
Maintainer: Rich FitzJohn <rich.fitzjohn@gmail.com>

0 errors | 0 warnings | 0 notes

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

## taRifx (1.0.6)
Maintainer: Ari B. Friedman <abfriedman@gmail.com>

0 errors | 0 warnings | 4 notes

```
checking DESCRIPTION meta-information ... NOTE
Malformed Title field: should not end in a period.

checking dependencies in R code ... NOTE
'library' or 'require' calls in package code:
  ‘gdata’ ‘ggplot2’ ‘grid’ ‘lattice’ ‘xtable’
  Please use :: or requireNamespace() instead.
  See section 'Suggested packages' in the 'Writing R Extensions' manual.

checking S3 generic/method consistency ... NOTE
Found the following apparent S3 methods exported but not registered:
  as.matrix.by stack.list
See section ‘Registering S3 methods’ in the ‘Writing R Extensions’
manual.

checking R code for possible problems ... NOTE
as.data.frame.by: no visible global function definition for ‘na.omit’
autoplot.microbenchmark : uq: no visible global function definition for
  ‘quantile’
autoplot.microbenchmark : lq: no visible global function definition for
  ‘quantile’
autoplot.microbenchmark: no visible global function definition for
  ‘ggplot’
autoplot.microbenchmark: no visible global function definition for
  ‘aes’
... 90 lines ...
  grid.points grid.polyline grid.rect grid.segments grid.text
  interleave label<- latticeParseFormula median na.omit opts
  panel.densityplot panel.lines panel.xyplot par pf plot.new
  popViewport pushViewport quantile sd seekViewport stat_summary terms
  text theme_text time unit upViewport viewport write.csv xtable
Consider adding
  importFrom("graphics", "barplot", "par", "plot.new", "text")
  importFrom("stats", "ecdf", "median", "na.omit", "pf", "quantile",
             "sd", "terms", "time")
  importFrom("utils", "write.csv")
to your NAMESPACE file.
```

## tcpl (1.2.2)
Maintainer: Dayne L Filer <dayne.filer@gmail.com>

0 errors | 0 warnings | 1 note 

```
checking installed package size ... NOTE
  installed size is  9.9Mb
  sub-directories of 1Mb or more:
    sql   8.7Mb
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

## TSsql (2015.1-2)
Maintainer: Paul Gilbert <pgilbert.ttv9z@ncf.ca>

0 errors | 0 warnings | 1 note 

```
checking R code for possible problems ... NOTE
TSgetSQL: no visible global function definition for ‘ts’
TSputSQL: no visible global function definition for ‘is.ts’
TSputSQL: no visible global function definition for ‘frequency’
TSputSQL: no visible global function definition for ‘time’
TSquery: no visible global function definition for ‘ts’
Undefined global functions or variables:
  frequency is.ts time ts
Consider adding
  importFrom("stats", "frequency", "is.ts", "time", "ts")
to your NAMESPACE file.
```

## TSSQLite (2015.4-1)
Maintainer: Paul Gilbert <pgilbert.ttv9z@ncf.ca>

0 errors | 0 warnings | 0 notes

## tweet2r (1.0)
Maintainer: Pau Aragó <parago@uji.es>

1 error  | 0 warnings | 0 notes

```
checking whether package ‘tweet2r’ can be installed ... ERROR
Installation failed.
See ‘/home/muelleki/git/R/RSQLite/revdep/checks/tweet2r.Rcheck/00install.out’ for details.
```

## twitteR (1.1.9)
Maintainer: Jeff Gentry <geoffjentry@gmail.com>

0 errors | 0 warnings | 0 notes

## UPMASK (1.0)
Maintainer: Alberto Krone-Martins <algol@sim.ul.pt>

0 errors | 0 warnings | 1 note 

```
checking R code for possible problems ... NOTE
UPMASKfile: no visible global function definition for ‘read.table’
UPMASKfile: no visible global function definition for ‘write.table’
analyse_randomKde2d: no visible global function definition for ‘hist’
analyse_randomKde2d: no visible global function definition for ‘lines’
analyse_randomKde2d_AutoCalibrated: no visible global function
  definition for ‘hist’
analyse_randomKde2d_AutoCalibrated: no visible global function
  definition for ‘lines’
create_randomKde2d: no visible global function definition for ‘image’
... 18 lines ...
kde2dForSubset: no visible global function definition for ‘image’
kde2dForSubset: no visible global function definition for ‘points’
Undefined global functions or variables:
  contour dev.new hist image lines pairs par plot points rainbow
  read.table rgb write.table
Consider adding
  importFrom("grDevices", "dev.new", "rainbow", "rgb")
  importFrom("graphics", "contour", "hist", "image", "lines", "pairs",
             "par", "plot", "points")
  importFrom("utils", "read.table", "write.table")
to your NAMESPACE file.
```

## vegdata (0.8.9)
Maintainer: Florian Jansen <jansen@uni-greifswald.de>

0 errors | 0 warnings | 0 notes

## vmsbase (2.1.3)
Maintainer: Lorenzo D'Andrea <support@vmsbase.org>

1 error  | 0 warnings | 0 notes

```
checking whether package ‘vmsbase’ can be installed ... ERROR
Installation failed.
See ‘/home/muelleki/git/R/RSQLite/revdep/checks/vmsbase.Rcheck/00install.out’ for details.
```

