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

|package   |*  |version    |date       |source                             |
|:---------|:--|:----------|:----------|:----------------------------------|
|BH        |   |1.60.0-2   |2016-05-07 |cran (@1.60.0-)                    |
|DBI       |   |0.4-2      |2016-07-07 |Github (rstats-db/DBI@a1367f7)     |
|DBItest   |   |1.2-4      |2016-07-07 |Github (rstats-db/DBItest@0b3d46b) |
|knitr     |   |1.13       |2016-05-09 |cran (@1.13)                       |
|Rcpp      |   |0.12.5     |2016-05-14 |cran (@0.12.5)                     |
|rmarkdown |   |0.9.6      |2016-05-01 |cran (@0.9.6)                      |
|RSQLite   |   |1.0.9004   |2016-07-07 |local (rstats-db/RSQLite@NA)       |
|testthat  |   |1.0.2.9000 |2016-07-07 |Github (hadley/testthat@1f196a6)   |

# Check results
36 packages with problems

## BatchExperiments (1.4.1)
Maintainer: Michel Lang <michellang@gmail.com>  
Bug reports: https://github.com/tudo-r/BatchExperiments/issues

2 errors | 0 warnings | 2 notes

```
checking examples ... ERROR
Running examples in ‘BatchExperiments-Ex.R’ failed
The error most likely occurred in:

> base::assign(".ptime", proc.time(), pos = "CheckExEnv")
> ### Name: addExperiments
> ### Title: Add experiemts to the registry.
> ### Aliases: Experiment addExperiments
> 
> ### ** Examples
... 51 lines ...
> pars = list(ntree = c(100, 500))
> forest.design = makeDesign("forest", exhaustive = pars)
> 
> # Add experiments to the registry:
> # Use  previously defined experimental designs.
> addExperiments(reg, prob.designs = iris.design,
+                algo.designs = list(tree.design, forest.design),
+                repls = 2) # usually you would set repls to 100 or more.
Adding 12 experiments / 24 jobs to DB.
Error: Please use dbGetQuery instead
Execution halted

checking tests ... ERROR
Running the tests in ‘tests/run-all.R’ failed.
Last 13 lines of output:
  1. Error: addExperiments (@test_addExperiments.R#12) 
  2. Error: skip.defined works (@test_addExperiments.R#172) 
  3. Error: findExperiments (@test_findExperiments.R#9) 
  4. Error: regexp works (@test_findExperiments.R#58) 
  5. Error: getIndex (@test_getIndex.R#9) 
  6. Error: getJob (@test_getJob.R#9) 
  7. Error: getJobInfo (@test_getJobInfo.R#9) 
  8. Error: reduceResults (@test_reduceResults.R#9) 
  9. Error: reduceResultsExperiments works on empty id sets (@test_reduceResults.R#88) 
  1. ...
  
  Error: testthat unit tests failed
  Execution halted

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

2 errors | 0 warnings | 0 notes

```
checking examples ... ERROR
Running examples in ‘BatchJobs-Ex.R’ failed
The error most likely occurred in:

> base::assign(".ptime", proc.time(), pos = "CheckExEnv")
> ### Name: batchExpandGrid
> ### Title: Map function over all combinations.
> ### Aliases: batchExpandGrid
> 
> ### ** Examples
> 
> reg = makeRegistry(id = "BatchJobsExample", file.dir = tempfile(), seed = 123)
Creating dir: /tmp/RtmpzcsN32/file289741c0585f
Saving registry: /tmp/RtmpzcsN32/file289741c0585f/registry.RData
> f = function(x, y, z) x * y  + z
> # lets store the param grid
> grid = batchExpandGrid(reg, f, x = 1:2, y = 1:3, more.args = list(z = 10))
Adding 6 jobs to DB.
Error : Please use dbGetQuery instead
Error in dbAddData(reg, "job_def", data = data.frame(fun_id = fun.id,  : 
  Error in dbAddData: Error : Please use dbGetQuery instead
Calls: batchExpandGrid -> do.call -> <Anonymous> -> dbAddData -> stopf
Execution halted

checking tests ... ERROR
Running the tests in ‘tests/run-all.R’ failed.
Last 13 lines of output:
  1. Error: batchExpandGrid (@test_batchExpandGrid.R#5) 
  2. Error: batchMap (@test_batchMap.R#5) 
  3. Failure: batchMapQuick (@test_batchMapQuick.R#7) 
  4. Failure: batchMapQuick (@test_batchMapQuick.R#12) 
  5. Failure: batchMapQuick (@test_batchMapQuick.R#17) 
  6. Failure: batchMapQuick (@test_batchMapQuick.R#21) 
  7. Error: batchMapQuick (@test_batchMapQuick.R#22) 
  8. Failure: batchMapQuick chunks properly (@test_batchMapQuick.R#33) 
  9. Error: batchMapResults (@test_batchMapResults.R#5) 
  1. ...
  
  Error: testthat unit tests failed
  Execution halted
```

## caroline (0.7.6)
Maintainer: David Schruth <caroline@hominine.net>

1 error  | 0 warnings | 3 notes

```
checking examples ... ERROR
Running examples in ‘caroline-Ex.R’ failed
The error most likely occurred in:

> base::assign(".ptime", proc.time(), pos = "CheckExEnv")
> ### Name: bestBy
> ### Title: Find the "best" record within subgroups of a dataframe.
> ### Aliases: bestBy
> 
> ### ** Examples
... 9 lines ...
  score query target
y    34     y      c
z    23     z      g
x     5     x      e
> ## or using SQLite
> best.hits.sql <- bestBy(blast.results, by='query', best='score', inverse=TRUE, sql=TRUE)
Loading required package: RSQLite
Error in dbConnect(dbDriver("SQLite"), dbname = tmpfile) : 
  could not find function "dbDriver"
Calls: bestBy -> dbConnect
Execution halted

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

## CITAN (2015.12-2)
Maintainer: Marek Gagolewski <gagolews@ibspan.waw.pl>  
Bug reports: https://github.com/Rexamine/CITAN/issues

1 error  | 0 warnings | 0 notes

```
checking whether package ‘CITAN’ can be installed ... ERROR
Installation failed.
See ‘/home/muelleki/git/R/RSQLite/revdep/checks/CITAN.Rcheck/00install.out’ for details.
```

## CollapsABEL (0.10.8)
Maintainer: Kaiyin Zhong <kindlychung@gmail.com>  
Bug reports: https://bitbucket.org/kindlychung/collapsabel2/issues

1 error  | 0 warnings | 0 notes

```
checking whether package ‘CollapsABEL’ can be installed ... ERROR
Installation failed.
See ‘/home/muelleki/git/R/RSQLite/revdep/checks/CollapsABEL.Rcheck/00install.out’ for details.
```

## dplyr (0.5.0)
Maintainer: Hadley Wickham <hadley@rstudio.com>  
Bug reports: https://github.com/hadley/dplyr/issues

0 errors | 1 warning  | 1 note 

```
checking Rd cross-references ... WARNING
package ‘microbenchmark’ exists but was not installed under R >= 2.10.0 so xrefs cannot be checked

checking installed package size ... NOTE
  installed size is 15.9Mb
  sub-directories of 1Mb or more:
    libs  13.8Mb
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

1 error  | 1 warning  | 0 notes

```
checking tests ... ERROR
Running the tests in ‘tests/testthat.R’ failed.
Last 13 lines of output:
    |==============================                                        |  43%
    |                                                                            
    |========================================                              |  57%
    |                                                                            
    |==================================================                    |  71%
    |                                                                            
    |============================================================          |  86%
    |                                                                            
    |======================================================================| 100%
  Error: table labels has no column named itemID
  testthat results ================================================================
  OK: 0 SKIPPED: 0 FAILED: 0
  Execution halted

checking re-building of vignette outputs ... WARNING
Error in re-building vignettes:
  ...

Attaching package: 'emuR'

The following object is masked from 'package:base':

    norm

Quitting from lines 30-41 (EQL.Rmd) 
Error: processing vignette 'EQL.Rmd' failed with diagnostics:
table labels has no column named itemID
Execution halted

```

## etl (0.3.1)
Maintainer: Ben Baumer <ben.baumer@gmail.com>  
Bug reports: https://github.com/beanumber/etl/issues

2 errors | 0 warnings | 0 notes

```
checking examples ... ERROR
Running examples in ‘etl-Ex.R’ failed
The error most likely occurred in:

> base::assign(".ptime", proc.time(), pos = "CheckExEnv")
> ### Name: etl_cleanup
> ### Title: ETL functions for working with medium sized data
> ### Aliases: etl_cleanup etl_cleanup.default etl_create etl_create.default
> ###   etl_extract etl_extract.default etl_extract.etl_mtcars etl_load
> ###   etl_load.default etl_load.etl_mtcars etl_transform
... 49 lines ...
>  # do it all in one step, and peek at the SQL creation script
>  cars %>%
+    etl_create(echo = TRUE)
Extracting raw data...
Transforming raw data...
Loading processed data...
Loading SQL script at /home/muelleki/git/R/RSQLite/revdep/checks/etl.Rcheck/etl/sql/mtcars.sqlite3
<SQL> DROP TABLE IF EXISTS mtcars
<SQL>   CREATE TABLE mtcars(   "makeModel" TEXT,   "mpg" REAL,   "cyl" INTEGER,   "disp" REAL,   "hp" INTEGER,   "drat" REAL,   "wt" REAL,   "qsec" REAL,   "vs" INTEGER,   "am" INTEGER,   "gear" INTEGER,   "carb" INTEGER )
Error: table mtcars has no column named X
Execution halted

checking tests ... ERROR
Running the tests in ‘tests/testthat.R’ failed.
Last 13 lines of output:
  26: dbSendQuery(conn, sql)
  27: .local(conn, statement, ...)
  28: new("SQLiteResult", sql = statement, ptr = rsqlite_send_query(conn@ptr, statement)) at /home/muelleki/git/R/RSQLite/R/query.R:58
  29: initialize(value, ...)
  30: initialize(value, ...)
  31: rsqlite_send_query(conn@ptr, statement)
  
  testthat results ================================================================
  OK: 3 SKIPPED: 0 FAILED: 1
  1. Error: dplyr works (@test-etl.R#14) 
  
  Error: testthat unit tests failed
  Execution halted
```

## ETLUtils (1.3)
Maintainer: Jan Wijffels <jwijffels@bnosac.be>

1 error  | 0 warnings | 0 notes

```
checking examples ... ERROR
Running examples in ‘ETLUtils-Ex.R’ failed
The error most likely occurred in:

> base::assign(".ptime", proc.time(), pos = "CheckExEnv")
> ### Name: read.dbi.ffdf
> ### Title: Read data from a DBI connection into an ffdf.
> ### Aliases: read.dbi.ffdf
> 
> ### ** Examples
> 
> require(ff)
> 
> ##
> ## Example query using data in sqlite
> ##
> require(RSQLite)
Loading required package: RSQLite
> dbfile <- system.file("smalldb.sqlite3", package="ETLUtils")
> drv <- dbDriver("SQLite")
Error: could not find function "dbDriver"
Execution halted
```

## filematrix (1.1.0)
Maintainer: Andrey A Shabalin <ashabalin@vcu.edu>  
Bug reports: https://github.com/andreyshabalin/filematrix/issues

1 error  | 0 warnings | 0 notes

```
checking whether package ‘filematrix’ can be installed ... ERROR
Installation failed.
See ‘/home/muelleki/git/R/RSQLite/revdep/checks/filematrix.Rcheck/00install.out’ for details.
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
Loading required package: plyr
Loading required package: reshape

Attaching package: ‘reshape’

The following objects are masked from ‘package:plyr’:

    rename, round_any

Loading required package: lattice

Error: processing vignette 'gcbd.Rnw' failed with diagnostics:
 chunk 2 (label = data) 
Error in dbConnect(dbDriver("SQLite"), dbname = system.file("sql", "gcbd.sqlite",  : 
  could not find function "dbDriver"
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

## nutshell.bbdb (1.0)
Maintainer: Joseph Adler <rinanutshell@gmail.com>

1 error  | 0 warnings | 2 notes

```
checking examples ... ERROR
Running examples in ‘nutshell.bbdb-Ex.R’ failed
The error most likely occurred in:

> base::assign(".ptime", proc.time(), pos = "CheckExEnv")
> ### Name: bb.db
> ### Title: 2008 Baseball Databank Database
> ### Aliases: bb.db
> ### Keywords: datasets
> 
> ### ** Examples
> 
> library(RSQLite)
> drv <- dbDriver("SQLite")
Error: could not find function "dbDriver"
Execution halted

checking installed package size ... NOTE
  installed size is 39.0Mb
  sub-directories of 1Mb or more:
    extdata  38.9Mb

checking DESCRIPTION meta-information ... NOTE
Malformed Description field: should contain one or more complete sentences.
Deprecated license: CC BY-NC-ND 3.0 US
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

## poplite (0.99.16)
Maintainer: Daniel Bottomly <bottomly@ohsu.edu>

2 errors | 1 warning  | 1 note 

```
checking examples ... ERROR
Running examples in ‘poplite-Ex.R’ failed
The error most likely occurred in:

> base::assign(".ptime", proc.time(), pos = "CheckExEnv")
> ### Name: Database-class
> ### Title: Class '"Database"'
> ### Aliases: Database Database-class columns,Database-method dbFile
> ###   dbFile,Database-method populate populate,Database-method schema
> ###   schema,Database-method tables,Database-method
... 25 lines ...
+  head(dbReadTable(examp.con, "teams"))
+  head(dbReadTable(examp.con, "team_franch"))
+  
+  dbDisconnect(examp.con)
+  
+ }
Loading required package: Lahman
Loading required package: RSQLite
Starting team_franch
Error: Please use dbGetQuery instead
Execution halted

checking tests ... ERROR
Running the tests in ‘tests/testthat.R’ failed.
Last 13 lines of output:
  OK: 101 SKIPPED: 0 FAILED: 9
  1. Failure: createTable (@test-poplite.R#252) 
  2. Failure: createTable (@test-poplite.R#252) 
  3. Failure: createTable (@test-poplite.R#252) 
  4. Failure: createTable (@test-poplite.R#252) 
  5. Failure: insertStatement (@test-poplite.R#330) 
  6. Error: insertStatement (@test-poplite.R#350) 
  7. Error: Database population (@test-poplite.R#451) 
  8. Error: Querying with Database objects (@test-poplite.R#561) 
  9. Error: sample tracking example but with direct keys between dna and samples (@test-poplite.R#795) 
  
  Error: testthat unit tests failed
  Execution halted

checking re-building of vignette outputs ... WARNING
Error in re-building vignettes:
  ...
    filter, lag

The following objects are masked from ‘package:base’:

    intersect, setdiff, setequal, union


... 8 lines ...

    filter

Error in makeSchemaFromData(dna, "dna") : 
  ERROR: The names of the supplied data.frame need to be modified for the database see correct.df.names
Starting clinical

Error: processing vignette 'poplite.Rnw' failed with diagnostics:
 chunk 8 
Error : Please use dbGetQuery instead
Execution halted

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
  DONE ===========================================================================
  .
  DONE ===========================================================================
  1. Error: Example 29: SQLite3 Support with .sql Extension with query = "SELECT * FROM ..." (@test-readers.R#576) 
  $ operator is invalid for atomic vectors
  1: ProjectTemplate:::sql.reader(data.file, filename, variable.name) at testthat/test-readers.R:576
  
  testthat results ================================================================
  OK: 330 SKIPPED: 0 FAILED: 1
  1. Error: Example 29: SQLite3 Support with .sql Extension with query = "SELECT * FROM ..." (@test-readers.R#576) 
  
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

## rangeMapper (0.3-0)
Maintainer: Mihai Valcu <valcu@orn.mpg.de>

2 errors | 1 warning  | 1 note 

```
checking examples ... ERROR
Running examples in ‘rangeMapper-Ex.R’ failed
The error most likely occurred in:

> base::assign(".ptime", proc.time(), pos = "CheckExEnv")
> ### Name: WKT2SpatialPolygonsDataFrame
> ### Title: Convert WKT polygons to SpatialPolygonsDataFrame
> ### Aliases: WKT2SpatialPolygonsDataFrame vertices
> ###   vertices,SpatialPolygons-method
> 
... 22 lines ...
> d = data.frame( nam = sample(letters, n, TRUE),
+                range = mapply(randPoly, mean = sample(1:2, n, TRUE),
+                sd = sample(1:2/5, n, TRUE) ))
> 
> 
> X = WKT2SpatialPolygonsDataFrame(d, 'range', 'nam')
> 
> 
> dbcon = rangeMap.start(file = "test.sqlite", overwrite = TRUE, dir = tempdir() )
Error: could not find function "dbGetQuery"
Execution halted

checking tests ... ERROR
Running the tests in ‘tests/testthat.R’ failed.
Last 13 lines of output:
  Calls: test_check ... ramp -> rangeMap.start -> rangeMapStart -> rangeMapStart
  testthat results ================================================================
  OK: 0 SKIPPED: 0 FAILED: 7
  1. Error: Building blocks are in place (@test-1_projectINI.R#7) 
  2. Error: Pipeline works forward only (@test-1_projectINI.R#30) 
  3. Error: Range overlay returns a data.frame (@test-1_projectINI.R#64) 
  4. Error: reprojecting on the fly (@test-2_processRanges.R#9) 
  5. Error: ONE SpPolyDF NO metadata (@test-2_processRanges.R#21) 
  6. Error: ONE SpPolyDF WITH metadata (@test-2_processRanges.R#39) 
  7. Error: MULTIPLE SpPolyDF-s WITH metadata (@test-2_processRanges.R#66) 
  
  Error: testthat unit tests failed
  Execution halted

checking re-building of vignette outputs ... WARNING
Error in re-building vignettes:
  ...
Quitting from lines 27-33 (Appendix_S2_Valcu_et_al_2012.Rmd) 
Error: processing vignette 'Appendix_S2_Valcu_et_al_2012.Rmd' failed with diagnostics:
could not find function "dbGetQuery"
Execution halted


checking R code for possible problems ... NOTE
.rangeMapSaveData: no visible global function definition for
  ‘dbGetQuery’
bio.merge: no visible global function definition for ‘dbGetQuery’
bio.merge : <anonymous>: no visible global function definition for
  ‘dbGetQuery’
dbRemoveField: no visible global function definition for ‘dbGetQuery’
dbRemoveField : <anonymous>: no visible global function definition for
  ‘dbGetQuery’
dbfield.exists: no visible global function definition for ‘dbGetQuery’
... 41 lines ...
rangeMapSave,rangeMapSave-missing-missing: no visible global function
  definition for ‘dbGetQuery’
rangeMapStart,rangeMapStart: no visible global function definition for
  ‘dbGetQuery’
show,rangeMap: no visible global function definition for ‘dbGetQuery’
tables,SQLiteConnection: no visible global function definition for
  ‘dbGetQuery’
tables,SQLiteConnection : <anonymous>: no visible global function
  definition for ‘dbGetQuery’
Undefined global functions or variables:
  dbGetQuery
```

## RecordLinkage (0.4-9)
Maintainer: Andreas Borg <borga@uni-mainz.de>

0 errors | 1 warning  | 1 note 

```
checking examples ... WARNING
Found the following significant warnings:

  Warning: 'make.db.names' is deprecated.
  Warning: 'make.db.names' is deprecated.
  Warning: 'make.db.names' is deprecated.
  Warning: 'make.db.names' is deprecated.
  Warning: 'make.db.names' is deprecated.
  Warning: 'make.db.names' is deprecated.
  Warning: 'make.db.names' is deprecated.
  Warning: 'make.db.names' is deprecated.
  Warning: 'make.db.names' is deprecated.
  Warning: 'make.db.names' is deprecated.
  Warning: 'make.db.names' is deprecated.
  Warning: 'make.db.names' is deprecated.
  Warning: 'make.db.names' is deprecated.
  Warning: 'make.db.names' is deprecated.
  Warning: 'make.db.names' is deprecated.
  Warning: 'make.db.names' is deprecated.
  Warning: 'make.db.names' is deprecated.
  Warning: 'make.db.names' is deprecated.
  Warning: 'make.db.names' is deprecated.
Deprecated functions may be defunct as soon as of the next release of
R.
See ?Deprecated.

checking DESCRIPTION meta-information ... NOTE
'LinkingTo' for ‘RSQLite’ is unused as it has no 'include' directory
```

## RObsDat (16.03)
Maintainer: Dominik Reusser <reusser@pik-potsdam.de>

1 error  | 0 warnings | 1 note 

```
checking examples ... ERROR
Running examples in ‘RObsDat-Ex.R’ failed
The error most likely occurred in:

> base::assign(".ptime", proc.time(), pos = "CheckExEnv")
> ### Name: RObsDat-package
> ### Title: R-Package to the observations Data Model from CUAHSI
> ### Aliases: RObsDat-package RObsDat
> ### Keywords: package
> 
... 125 lines ...

addDtV> ver3 <- inDB

addDtV> if(NROW(ver3@data)>=32){
addDtV+    ver3@data[30:32,] <- 33
addDtV+    updateDataValues(ver3, "Ups, I used 60 instead of 33 by mistake")
addDtV+ }
Error in `[.data.frame`(getDataResult@DerivedFromIDs@data, selectMeta) : 
  undefined columns selected
Calls: example ... IupdateDataValues -> .local -> paste -> sv -> [ -> [.data.frame
Execution halted

checking package dependencies ... NOTE
Package suggested but not available for checking: ‘SSOAP’
```

## rplexos (1.1.4)
Maintainer: Eduardo Ibanez <edu.ibanez@gmail.com>  
Bug reports: https://github.com/NREL/rplexos/issues

2 errors | 1 warning  | 1 note 

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
Error: Please use dbGetQuery instead
Execution halted

checking tests ... ERROR
Running the tests in ‘tests/testthat.R’ failed.
Last 13 lines of output:
  
  Type 'demo()' for some demos, 'help()' for on-line help, or
  'help.start()' for an HTML browser interface to help.
  Type 'q()' to quit R.
  
  > library(testthat)
  > library(rplexos)
  > 
  > test_check("rplexos")
  Error: Please use dbGetQuery instead
  testthat results ================================================================
  OK: 0 SKIPPED: 4 FAILED: 0
  Execution halted

checking re-building of vignette outputs ... WARNING
Error in re-building vignettes:
  ...
Quitting from lines 42-43 (rplexos.Rmd) 
Error: processing vignette 'rplexos.Rmd' failed with diagnostics:
Please use dbGetQuery instead
Execution halted


checking dependencies in R code ... NOTE
Missing or unexported object: ‘RSQLite::dbGetQuery’
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

## SGP (1.5-0.0)
Maintainer: Damian W. Betebenner <dbetebenner@nciea.org>  
Bug reports: https://github.com/CenterForAssessment/SGP/issues

1 error  | 0 warnings | 0 notes

```
checking whether package ‘SGP’ can be installed ... ERROR
Installation failed.
See ‘/home/muelleki/git/R/RSQLite/revdep/checks/SGP.Rcheck/00install.out’ for details.
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

1 error  | 1 warning  | 2 notes

```
checking examples ... ERROR
Running examples in ‘sqldf-Ex.R’ failed
The error most likely occurred in:

> base::assign(".ptime", proc.time(), pos = "CheckExEnv")
> ### Name: sqldf
> ### Title: SQL select on data frames
> ### Aliases: sqldf
> ### Keywords: manip
> 
> ### ** Examples
> 
> 
> #
> # These examples show how to run a variety of data frame manipulations
> # in R without SQL and then again with SQL
> #
> 
> # head
> a1r <- head(warpbreaks)
> a1s <- sqldf("select * from warpbreaks limit 6")
Loading required package: tcltk
Error: no such table: warpbreaks
Execution halted

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

## storr (1.0.1)
Maintainer: Rich FitzJohn <rich.fitzjohn@gmail.com>

0 errors | 1 warning  | 0 notes

```
checking re-building of vignette outputs ... WARNING
Error in re-building vignettes:
  ...
Quitting from lines 101-109 (drivers.Rmd) 
Error: processing vignette 'drivers.Rmd' failed with diagnostics:
Please use dbGetQuery instead
Execution halted

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

1 error  | 1 warning  | 2 notes

```
checking tests ... ERROR
Running the tests in ‘tests/DBIcheck.R’ failed.
Last 13 lines of output:
  
  > library(RSQLite)
  > 
  > data(api)
  > apiclus1$api_stu<-apiclus1$api.stu
  > apiclus1$comp_imp<-apiclus1$comp.imp
  > dclus1<-svydesign(id=~dnum, weights=~pw, fpc=~fpc,data=apiclus1)
  > dbclus1<-svydesign(id=~dnum, weights=~pw, fpc=~fpc,
  + data="apiclus1",dbtype="SQLite", dbname=system.file("api.db",package="survey"))
  Error in svydesign.character(id = ~dnum, weights = ~pw, fpc = ~fpc, data = "apiclus1",  : 
    could not find function "dbDriver"
  Calls: svydesign -> svydesign.character
  Execution halted

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

## tcpl (1.2.2)
Maintainer: Dayne L Filer <dayne.filer@gmail.com>

1 error  | 1 warning  | 1 note 

```
checking examples ... ERROR
Running examples in ‘tcpl-Ex.R’ failed
The error most likely occurred in:

> base::assign(".ptime", proc.time(), pos = "CheckExEnv")
> ### Name: tcplCytoPt
> ### Title: Calculate the cytotoxicity point based on the "burst" endpoints
> ### Aliases: tcplCytoPt
> 
> ### ** Examples
> 
> ## Store the current config settings, so they can be reloaded at the end 
> ## of the examples
> conf_store <- tcplConfList()
> tcplConfDefault()
> 
> ## Load the "burst" endpoints -- none are defined in the example dataset
> tcplLoadAeid(fld = "burst_assay", val = 1)
Empty data.table (0 rows) of 3 cols: burst_assay,aeid,aenm
> 
> ## Calculate the cytotoxicity distributions using both example endpoints
> tcplCytoPt(aeid = 1:2)
Error in x - center : non-numeric argument to binary operator
Calls: tcplCytoPt -> [ -> [.data.table -> mad -> median
Execution halted

checking re-building of vignette outputs ... WARNING
Error in re-building vignettes:
  ...
  TCPL_HOST:  NA
  TCPL_DRVR:  SQLite
Default settings stored in TCPL.conf. See ?tcplConf for more information.
Warning in rsqlite_disconnect(conn@ptr) :
  There are 1 result in use. The connection will be released when they are closed
Warning in rsqlite_disconnect(conn@ptr) :
  There are 1 result in use. The connection will be released when they are closed
... 8 lines ...
  There are 1 result in use. The connection will be released when they are closed
Warning in rsqlite_disconnect(conn@ptr) :
  There are 1 result in use. The connection will be released when they are closed
Warning in rsqlite_disconnect(conn@ptr) :
  There are 1 result in use. The connection will be released when they are closed

Error: processing vignette 'tcpl_Overview.Rnw' failed with diagnostics:
 chunk 31 (label = l4plt) 
Error in signif(c(gnls_tp_sd, gnls_ga_sd, gnls_gw_sd, gnls_la_sd, gnls_lw_sd),  : 
  non-numeric argument to mathematical function
Execution halted

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
Jul 07, 2016 10:31:53 AM it.bancaditalia.oss.sdmx.client.custom.RestSdmx20Client getData
SEVERE: Exception caught parsing results from call to provider OECD
Jul 07, 2016 10:31:53 AM it.bancaditalia.oss.sdmx.client.custom.RestSdmx20Client getData
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

