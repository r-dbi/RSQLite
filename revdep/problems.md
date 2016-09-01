# Setup

## Platform

|setting  |value                        |
|:--------|:----------------------------|
|version  |R version 3.3.1 (2016-06-21) |
|system   |x86_64, linux-gnu            |
|ui       |X11                          |
|language |(EN)                         |
|collate  |en_US.UTF-8                  |
|tz       |Zulu                         |
|date     |2016-09-01                   |

## Packages

|package   |*  |version    |date       |source                             |
|:---------|:--|:----------|:----------|:----------------------------------|
|BH        |   |1.60.0-2   |2016-05-07 |cran (@1.60.0-)                    |
|DBI       |   |0.5        |2016-09-01 |Github (rstats-db/DBI@bc730b9)     |
|DBItest   |   |1.3-6      |2016-08-25 |Github (rstats-db/DBItest@aa3339a) |
|knitr     |   |1.14       |2016-08-13 |cran (@1.14)                       |
|Rcpp      |   |0.12.6     |2016-07-19 |cran (@0.12.6)                     |
|rmarkdown |   |1.0        |2016-07-08 |cran (@1.0)                        |
|RSQLite   |   |1.0.9007   |2016-09-01 |local (rstats-db/RSQLite@NA)       |
|testthat  |   |1.0.2.9000 |2016-08-25 |Github (hadley/testthat@46d15da)   |

# Check results

22 packages with problems

|package          |version | errors| warnings| notes|
|:----------------|:-------|------:|--------:|-----:|
|AnnotationDbi    |1.34.4  |      0|        2|     5|
|BatchExperiments |1.4.1   |      0|        1|     2|
|BatchJobs        |1.6     |      0|        1|     0|
|bioassayR        |1.10.15 |      0|        1|     1|
|Category         |2.38.0  |      1|        0|     1|
|cummeRbund       |2.14.0  |      1|        1|     7|
|DECIPHER         |2.0.2   |      1|        3|     3|
|GWASTools        |1.18.0  |      2|        0|     2|
|mgsa             |1.20.0  |      2|        2|     4|
|oligo            |1.36.1  |      1|        0|     8|
|PAnnBuilder      |1.36.0  |      0|        3|     1|
|plethy           |1.10.0  |      2|        1|     3|
|poplite          |0.99.16 |      1|        1|     1|
|rangeMapper      |0.3-0   |      2|        1|     0|
|RecordLinkage    |0.4-10  |      0|        1|     0|
|RObsDat          |16.03   |      1|        0|     0|
|rplexos          |1.1.8   |      0|        1|     0|
|specL            |1.6.2   |      1|        1|     4|
|sqldf            |0.4-10  |      1|        1|     2|
|tcpl             |1.2.2   |      1|        1|     1|
|TFBSTools        |1.10.3  |      2|        1|     2|
|VariantFiltering |1.8.6   |      0|        3|     4|

## AnnotationDbi (1.34.4)
Maintainer: Bioconductor Package Maintainer
 <maintainer@bioconductor.org>

0 errors | 2 warnings | 5 notes

```
checking examples ... WARNING
Found the following significant warnings:

  Warning: 'dbSendPreparedQuery' is deprecated.
  Warning: 'dbSendPreparedQuery' is deprecated.
  Warning: 'dbSendPreparedQuery' is deprecated.
Deprecated functions may be defunct as soon as of the next release of
R.
See ?Deprecated.
Examples with CPU or elapsed time > 5s
                   user system elapsed
AnnDbPkg-checker 33.588  0.348  33.979
Bimap-direction   4.764  0.404   5.166

checking for unstated dependencies in ‘tests’ ... WARNING
'library' or 'require' call not declared from: ‘org.testing.db’

checking installed package size ... NOTE
  installed size is  8.6Mb
  sub-directories of 1Mb or more:
    extdata   6.0Mb

checking DESCRIPTION meta-information ... NOTE
Packages listed in more than one of Depends, Imports, Suggests, Enhances:
  ‘methods’ ‘utils’ ‘stats4’ ‘BiocGenerics’ ‘Biobase’ ‘IRanges’ ‘DBI’ ‘RSQLite’
A package should be listed in only one of these fields.

checking dependencies in R code ... NOTE
'library' or 'require' calls in package code:
  ‘GO.db’ ‘KEGG.db’ ‘RSQLite’ ‘graph’
  Please use :: or requireNamespace() instead.
  See section 'Suggested packages' in the 'Writing R Extensions' manual.
Unexported object imported by a ':::' call: ‘BiocGenerics:::testPackage’
  See the note in ?`:::` about the use of this operator.

checking R code for possible problems ... NOTE
.selectInp8: no visible global function definition for ‘.resort’
annotMessage: no visible binding for global variable ‘pkgName’
createORGANISMSeeds: no visible global function definition for
  ‘makeAnnDbMapSeeds’
makeGOGraph: no visible binding for global variable ‘GOBPPARENTS’
makeGOGraph: no visible binding for global variable ‘GOMFPARENTS’
makeGOGraph: no visible binding for global variable ‘GOCCPARENTS’
makeGOGraph: no visible global function definition for ‘ftM2graphNEL’
Undefined global functions or variables:
  .resort GOBPPARENTS GOCCPARENTS GOMFPARENTS ftM2graphNEL
  makeAnnDbMapSeeds pkgName

checking Rd line widths ... NOTE
Rd file 'inpIDMapper.Rd':
  \examples lines wider than 100 characters:
       YeastUPSingles = inpIDMapper(ids, "HOMSA", "SACCE", destIDType="UNIPROT", keepMultDestIDMatches = FALSE)

These lines will be truncated in the PDF manual.
```

## BatchExperiments (1.4.1)
Maintainer: Michel Lang <michellang@gmail.com>  
Bug reports: https://github.com/tudo-r/BatchExperiments/issues

0 errors | 1 warning  | 2 notes

```
checking examples ... WARNING
Found the following significant warnings:

  Warning: 'dbGetPreparedQuery' is deprecated.
  Warning: 'dbGetPreparedQuery' is deprecated.
  Warning: 'dbGetPreparedQuery' is deprecated.
  Warning: 'dbGetPreparedQuery' is deprecated.
  Warning: 'dbGetPreparedQuery' is deprecated.
  Warning: 'dbGetPreparedQuery' is deprecated.
  Warning: 'dbGetPreparedQuery' is deprecated.
  Warning: 'dbGetPreparedQuery' is deprecated.
  Warning: 'dbGetPreparedQuery' is deprecated.
  Warning: 'dbGetPreparedQuery' is deprecated.
  Warning: 'dbGetPreparedQuery' is deprecated.
  Warning: 'dbGetPreparedQuery' is deprecated.
  Warning: 'dbGetPreparedQuery' is deprecated.
  Warning: 'dbGetPreparedQuery' is deprecated.
  Warning: 'dbGetPreparedQuery' is deprecated.
Deprecated functions may be defunct as soon as of the next release of
R.
See ?Deprecated.
Examples with CPU or elapsed time > 5s
                user system elapsed
addExperiments 5.492  0.076   5.642
getResultVars  5.484  0.040   5.616

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

0 errors | 1 warning  | 0 notes

```
checking examples ... WARNING
Found the following significant warnings:

  Warning: 'dbGetPreparedQuery' is deprecated.
  Warning: 'dbGetPreparedQuery' is deprecated.
  Warning: 'dbGetPreparedQuery' is deprecated.
  Warning: 'dbGetPreparedQuery' is deprecated.
  Warning: 'dbGetPreparedQuery' is deprecated.
  Warning: 'dbGetPreparedQuery' is deprecated.
  Warning: 'dbGetPreparedQuery' is deprecated.
... 14 lines ...
  Warning: 'dbGetPreparedQuery' is deprecated.
  Warning: 'dbGetPreparedQuery' is deprecated.
  Warning: 'dbGetPreparedQuery' is deprecated.
  Warning: 'dbGetPreparedQuery' is deprecated.
  Warning: 'dbGetPreparedQuery' is deprecated.
  Warning: 'dbGetPreparedQuery' is deprecated.
  Warning: 'dbGetPreparedQuery' is deprecated.
  Warning: 'dbGetPreparedQuery' is deprecated.
Deprecated functions may be defunct as soon as of the next release of
R.
See ?Deprecated.
```

## bioassayR (1.10.15)
Maintainer: Tyler Backman <tbackman@ucr.edu>  
Bug reports: https://github.com/TylerBackman/bioassayR/issues

0 errors | 1 warning  | 1 note 

```
checking examples ... WARNING
Found the following significant warnings:

  Warning: 'dbGetPreparedQuery' is deprecated.
  Warning: 'dbGetPreparedQuery' is deprecated.
  Warning: 'dbGetPreparedQuery' is deprecated.
  Warning: 'dbGetPreparedQuery' is deprecated.
  Warning: 'dbGetPreparedQuery' is deprecated.
  Warning: 'dbGetPreparedQuery' is deprecated.
  Warning: 'dbGetPreparedQuery' is deprecated.
... 34 lines ...
  Warning: 'dbGetPreparedQuery' is deprecated.
  Warning: 'dbGetPreparedQuery' is deprecated.
  Warning: 'dbGetPreparedQuery' is deprecated.
  Warning: 'dbGetPreparedQuery' is deprecated.
  Warning: 'dbGetPreparedQuery' is deprecated.
  Warning: 'dbGetPreparedQuery' is deprecated.
  Warning: 'dbGetPreparedQuery' is deprecated.
  Warning: 'dbGetPreparedQuery' is deprecated.
Deprecated functions may be defunct as soon as of the next release of
R.
See ?Deprecated.

checking R code for possible problems ... NOTE
crossReactivityPrior: no visible global function definition for ‘sd’
crossReactivityProbability : <anonymous>: no visible global function
  definition for ‘pbeta’
Undefined global functions or variables:
  pbeta sd
Consider adding
  importFrom("stats", "pbeta", "sd")
to your NAMESPACE file.
```

## Category (2.38.0)
Maintainer: Bioconductor Package Maintainer <maintainer@bioconductor.org>

1 error  | 0 warnings | 1 note 

```
checking tests ... ERROR
Running the tests in ‘tests/runTests.R’ failed.
Last 13 lines of output:
  ERROR in test_basic_regression_YEAST: Error in getGoToEntrezMap_db(p) : could not find function "dbGetQuery"
  ERROR in test_basic_regression_hgu95av2: Error in getGoToEntrezMap_db(p) : could not find function "dbGetQuery"
  
  Test files with failing tests
  
     hyperGTest_test.R 
       test_basic_regression_YEAST 
       test_basic_regression_hgu95av2 
  
  
  Error in BiocGenerics:::testPackage("Category", "UnitTests", ".*_test\\.R$") : 
    unit tests failed for package Category
  Execution halted

checking R code for possible problems ... NOTE
.linearMTestInternal: no visible global function definition for
  ‘setNames’
getGoToEntrezMap_db: no visible global function definition for
  ‘dbGetQuery’
getUniverseViaKegg_db: no visible global function definition for
  ‘dbGetQuery’
getUniverseViaPfam_db: no visible global function definition for
  ‘dbGetQuery’
GO2AllProbes,Org.XX.egDatPkg: no visible global function definition for
  ‘dbGetQuery’
Undefined global functions or variables:
  dbGetQuery setNames
Consider adding
  importFrom("stats", "setNames")
to your NAMESPACE file.
```

## cummeRbund (2.14.0)
Maintainer: Loyal A. Goff <lgoff@csail.mit.edu>

1 error  | 1 warning  | 7 notes

```
checking examples ... ERROR
Running examples in ‘cummeRbund-Ex.R’ failed
The error most likely occurred in:

> base::assign(".ptime", proc.time(), pos = "CheckExEnv")
> ### Name: MAplot
> ### Title: MAplot
> ### Aliases: MAplot MAplot,CuffData-method
> ### Keywords: heatmap
> 
... 28 lines ...
Reading /home/muelleki/git/R/RSQLite/revdep/checks/cummeRbund.Rcheck/cummeRbund/extdata/genes.fpkm_tracking
Checking samples table...
Warning: 'make.db.names' is deprecated.
Use 'dbQuoteIdentifier' instead.
See help("Deprecated")
Populating samples table...
Warning: 'make.db.names' is deprecated.
Use 'dbQuoteIdentifier' instead.
See help("Deprecated")
Error: table samples has no column named index
Execution halted

checking re-building of vignette outputs ... WARNING
Error in re-building vignettes:
  ...

Loading required package: IRanges
Loading required package: GenomeInfoDb
Loading required package: Gviz
Loading required package: grid

Attaching package: 'cummeRbund'
... 8 lines ...
    promoters

The following object is masked from 'package:BiocGenerics':

    conditions


Error: processing vignette 'cummeRbund-example-workflow.Rnw' failed with diagnostics:
 chunk 4 (label = model_fit_1) 
Error in eval(expr, envir, enclos) : near ")": syntax error
Execution halted

checking package dependencies ... NOTE
Depends: includes the non-default packages:
  ‘BiocGenerics’ ‘RSQLite’ ‘ggplot2’ ‘reshape2’ ‘fastcluster’
  ‘rtracklayer’ ‘Gviz’
Adding so many packages to the search path is excessive and importing
selectively is preferable.

checking installed package size ... NOTE
  installed size is 11.3Mb
  sub-directories of 1Mb or more:
    R         3.7Mb
    doc       1.8Mb
    extdata   5.6Mb

checking DESCRIPTION meta-information ... NOTE
Malformed Title field: should not end in a period.
Packages listed in more than one of Depends, Imports, Suggests, Enhances:
  ‘BiocGenerics’ ‘plyr’
A package should be listed in only one of these fields.

checking dependencies in R code ... NOTE
'library' or 'require' calls in package code:
  'NMFN' 'cluster' 'rjson' 'stringr'
  Please use :: or requireNamespace() instead.
  See section 'Suggested packages' in the 'Writing R Extensions' manual.
Packages in Depends field not imported from:
  'Gviz' 'RSQLite' 'fastcluster' 'ggplot2' 'reshape2' 'rtracklayer'
  These packages need to be imported from (in the NAMESPACE file)
  for when this namespace is loaded but not attached.

checking R code for possible problems ... NOTE
.CVdensity: no visible global function definition for 'ggplot'
.CVdensity: no visible global function definition for 'geom_density'
.CVdensity: no visible global function definition for 'aes'
.CVdensity: no visible binding for global variable 'CV'
.CVdensity: no visible binding for global variable 'sample_name'
.CVdensity: no visible global function definition for 'scale_x_log10'
.MAplot: no visible global function definition for 'ggplot'
.MAplot: no visible global function definition for 'geom_point'
.MAplot: no visible global function definition for 'aes'
... 1188 lines ...
  scale_y_log10 seqnames significant stat_density stat_smooth stat_sum
  stat_summary stdev str_split_fixed strand theme theme_bw toJSON
  tracking_id tracks unit v1 v2 value variable varnames write.table x
  xlab xlim y ylab
Consider adding
  importFrom("graphics", "plot")
  importFrom("stats", "as.dendrogram", "as.dist", "as.formula",
             "cmdscale", "dist", "hclust", "order.dendrogram",
             "p.adjust", "prcomp")
  importFrom("utils", "read.delim", "read.table", "write.table")
to your NAMESPACE file.

checking Rd line widths ... NOTE
Rd file 'MAplot.Rd':
  \examples lines wider than 100 characters:
             a<-readCufflinks(system.file("extdata", package="cummeRbund")) #Create CuffSet object from sample data

Rd file 'QCplots.Rd':
  \examples lines wider than 100 characters:
             a<-readCufflinks(system.file("extdata", package="cummeRbund")) #Read cufflinks data and create CuffSet object

Rd file 'csBoxplot.Rd':
... 96 lines ...
                                     isoformFPKM = "isoforms.fpkm_tracking", isoformDiff = "isoform_exp.diff", isoformCount="isoforms.count_ ... [TRUNCATED]
                                     TSSFPKM = "tss_groups.fpkm_tracking", TSSDiff = "tss_group_exp.diff", TSSCount="tss_groups.count_tracki ... [TRUNCATED]
                                     CDSFPKM = "cds.fpkm_tracking", CDSExpDiff = "cds_exp.diff", CDSCount="cds.count_tracking", CDSRep="cds. ... [TRUNCATED]
  \examples lines wider than 100 characters:
             a<-readCufflinks(system.file("extdata", package="cummeRbund")) #Read cufflinks data in sample directory and creates CuffSet obj ... [TRUNCATED]

Rd file 'sigMatrix.Rd':
  \examples lines wider than 100 characters:
             a<-readCufflinks(system.file("extdata", package="cummeRbund")) #Create CuffSet object from sample data

These lines will be truncated in the PDF manual.

checking sizes of PDF files under ‘inst/doc’ ... NOTE
  ‘qpdf’ made some significant size reductions:
     compacted ‘cummeRbund-manual.pdf’ from 1.5Mb to 1.3Mb
  consider running tools::compactPDF() on these files
```

## DECIPHER (2.0.2)
Maintainer: Erik Wright <DECIPHER@cae.wisc.edu>

1 error  | 3 warnings | 3 notes

```
checking examples ... ERROR
Running examples in ‘DECIPHER-Ex.R’ failed
The error most likely occurred in:

> base::assign(".ptime", proc.time(), pos = "CheckExEnv")
> ### Name: Add2DB
> ### Title: Add Data to a Database
> ### Aliases: Add2DB
> 
> ### ** Examples
> 
> # Create a sequence database
> gen <- system.file("extdata", "Bacteria_175seqs.gen", package="DECIPHER")
> dbConn <- dbConnect(SQLite(), ":memory:")
> Seqs2DB(gen, "GenBank", dbConn, "Bacteria")

Reading GenBank file chunk 1Error: Unsupported type
Execution halted

checking foreign function calls ... WARNING
Registration problems:
  symbol ‘functionCall’ in the local frame:
   .Call(functionCall, myXStringSet, as.numeric(subMatrix), gapOpening, 
       gapExtension, gapLetter, shiftPenalty, threshold, weight, 
       PACKAGE = "DECIPHER")
  symbol ‘functionCall’ in the local frame:
   .Call(functionCall, seqs, sM, GO, gapExtensionMax, weights/mean(weights), 
       structs, structureMatrix)
  call to ‘"consensusProfileAA"’ with 2 parameters, expected 3:
   .Call("consensusProfileAA", myXStringSet, rep(1, length(myXStringSet)), 
       PACKAGE = "DECIPHER")
See chapter ‘System and foreign language interfaces’ in the ‘Writing R
Extensions’ manual.

checking sizes of PDF files under ‘inst/doc’ ... WARNING
  ‘gs+qpdf’ made some significant size reductions:
     compacted ‘ArtOfAlignmentInR.pdf’ from 968Kb to 635Kb
  consider running tools::compactPDF(gs_quality = "ebook") on these files

checking re-building of vignette outputs ... WARNING
Error in re-building vignettes:
  ...

    Filter, Find, Map, Position, Reduce, anyDuplicated, append,
    as.data.frame, cbind, colnames, do.call, duplicated, eval, evalq,
    get, grep, grepl, intersect, is.unsorted, lapply, lengths, mapply,
    match, mget, order, paste, pmax, pmax.int, pmin, pmin.int, rank,
    rbind, rownames, sapply, setdiff, sort, table, tapply, union,
    unique, unsplit
... 8 lines ...

    colMeans, colSums, expand.grid, rowMeans, rowSums

Loading required package: IRanges
Loading required package: XVector
Loading required package: RSQLite

Error: processing vignette 'DECIPHERing.Rnw' failed with diagnostics:
 chunk 3 (label = expr1) 
Error : Unsupported type
Execution halted

checking installed package size ... NOTE
  installed size is  9.2Mb
  sub-directories of 1Mb or more:
    data      2.5Mb
    doc       3.9Mb
    extdata   1.4Mb

checking DESCRIPTION meta-information ... NOTE
'LinkingTo' for ‘RSQLite’ is unused as it has no 'include' directory

checking R code for possible problems ... NOTE
.CalculateEfficiencyFISH: no visible global function definition for
  ‘uniroot’
.midpointRoot : .containsZero: no visible global function definition
  for ‘is.leaf’
.midpointRoot : .findMax: no visible global function definition for
  ‘is.leaf’
.midpointRoot : .containsMax: no visible global function definition for
  ‘is.leaf’
.midpointRoot : .findMidpoint: no visible global function definition
... 171 lines ...
  importFrom("grDevices", "colorRampPalette", "colors", "dev.flush",
             "dev.hold", "dev.size", "rainbow")
  importFrom("graphics", "abline", "axis", "box", "legend", "mtext",
             "par", "plot", "points", "rect", "segments", "strheight",
             "strwidth", "text")
  importFrom("stats", "dendrapply", "dist", "is.leaf", "nlminb",
             "optimize", "order.dendrogram", "pbinom", "reorder",
             "setNames", "step", "uniroot")
  importFrom("utils", "browseURL", "data", "flush.console",
             "object.size", "setTxtProgressBar", "txtProgressBar")
to your NAMESPACE file.
```

## GWASTools (1.18.0)
Maintainer: Stephanie M. Gogarten <sdmorris@u.washington.edu>, Adrienne Stilp <amstilp@u.washington.edu>

2 errors | 0 warnings | 2 notes

```
checking examples ... ERROR
Running examples in ‘GWASTools-Ex.R’ failed
The error most likely occurred in:

> base::assign(".ptime", proc.time(), pos = "CheckExEnv")
> ### Name: SnpAnnotationSQLite
> ### Title: Class SnpAnotationSQLite
> ### Aliases: SnpAnnotationSQLite-class SnpAnnotationSQLite
> ###   hasVariable,SnpAnnotationSQLite-method
> ###   getVariable,SnpAnnotationSQLite-method
... 20 lines ...
> 
> ### ** Examples
> 
> library(GWASdata)
> dbpath <- tempfile()
> snpAnnot <- SnpAnnotationSQLite(dbpath)
Warning: Closing open result set, pending rows
Error in validObject(.Object) : 
  invalid class “SnpAnnotationSQLite” object: snpID must be a unique integer vector
Calls: SnpAnnotationSQLite -> new -> initialize -> initialize -> validObject
Execution halted

checking tests ... ERROR
Running the tests in ‘tests/test.R’ failed.
Last 13 lines of output:
  ERROR in test_SnpAnnotationSQLite: Error in validObject(.Object) : 
    invalid class "SnpAnnotationSQLite" object: snpID must be a unique integer vector
  
  Test files with failing tests
  
     SnpAnnotationSQLite_test.R 
       test_SnpAnnotationSQLite 
  
  
  Error in BiocGenerics:::testPackage("GWASTools", pattern = ".*_test\\.R$") : 
    unit tests failed for package GWASTools
  In addition: There were 50 or more warnings (use warnings() to see the first 50)
  Execution halted

checking R code for possible problems ... NOTE
.CI: no visible global function definition for ‘qnorm’
.LOHbase: no visible global function definition for ‘mad’
.LOHbase: no visible global function definition for ‘median’
.LOHbase: no visible global function definition for ‘sd’
.LOHlocalMad: no visible global function definition for ‘median’
.LOHlocalMad: no visible global function definition for ‘mad’
.LOHselectAnoms: no visible global function definition for ‘median’
.orderBySelection: no visible global function definition for ‘na.omit’
.permuteGenotypes: no visible global function definition for ‘runif’
... 161 lines ...
Consider adding
  importFrom("graphics", "abline", "axis", "layout", "legend", "lines",
             "par", "plot", "points", "polygon", "rect", "segments")
  importFrom("stats", "as.formula", "binomial", "coef", "complete.cases",
             "cor", "dbinom", "fisher.test", "glm", "lm", "mad",
             "median", "model.matrix", "na.omit", "pchisq", "poisson",
             "qbeta", "qchisq", "qnorm", "rbinom", "rnorm", "runif",
             "sd", "setNames", "vcov")
  importFrom("utils", "combn", "count.fields", "data", "head",
             "read.table", "write.table")
to your NAMESPACE file.

checking Rd line widths ... NOTE
Rd file 'assocRegression.Rd':
  \examples lines wider than 100 characters:
     scanAnnot$blood.pressure[scanAnnot$case.cntl.status==1] <- rnorm(sum(scanAnnot$case.cntl.status==1), mean=100, sd=10)
     scanAnnot$blood.pressure[scanAnnot$case.cntl.status==0] <- rnorm(sum(scanAnnot$case.cntl.status==0), mean=90, sd=5)

Rd file 'createDataFile.Rd':
  \usage lines wider than 90 characters:
                    precision="single", compress="ZIP_RA:8M", compress.geno="ZIP_RA", compress.annot="ZIP_RA",

These lines will be truncated in the PDF manual.
```

## mgsa (1.20.0)
Maintainer: Sebastian Bauer <mail@sebastianbauer.info>

2 errors | 2 warnings | 4 notes

```
checking examples ... ERROR
Running examples in ‘mgsa-Ex.R’ failed
The error most likely occurred in:

> base::assign(".ptime", proc.time(), pos = "CheckExEnv")
> ### Name: readGAF
> ### Title: Read a Gene Ontology annotation file
> ### Aliases: readGAF
> 
> ### ** Examples
... 47 lines ...

The following objects are masked from ‘package:base’:

    colMeans, colSums, expand.grid, rowMeans, rowSums


Loading required package: RSQLite
Loading required package: DBI
Error in guessRowName(df, row.names) : Unknown input
Calls: readGAF ... sqlCreateTable -> sqlRownamesToColumn -> guessRowName
Execution halted

checking tests ... ERROR
Running the tests in ‘tests/testthat.R’ failed.
Last 13 lines of output:
  6: sqlCreateTable(conn, name, value, row.names = row.names) at /home/muelleki/git/R/RSQLite/R/table.R:70
  7: sqlCreateTable(conn, name, value, row.names = row.names) at /tmp/RtmpFisqKr/devtools13d37bd5f7c7/rstats-db-DBI-bc730b9/R/table-create.R:36
  8: sqlRownamesToColumn(fields, row.names) at /tmp/RtmpFisqKr/devtools13d37bd5f7c7/rstats-db-DBI-bc730b9/R/table-create.R:46
  9: guessRowName(df, row.names) at /tmp/RtmpFisqKr/devtools13d37bd5f7c7/rstats-db-DBI-bc730b9/R/rownames.R:38
  10: stop("Unknown input") at /tmp/RtmpFisqKr/devtools13d37bd5f7c7/rstats-db-DBI-bc730b9/R/rownames.R:84
  
  testthat results ================================================================
  OK: 16 SKIPPED: 0 FAILED: 2
  1. Error: readGAF() works (@test-readGAF.R#2) 
  2. Error: readGAF() with aspect works (@test-readGAF.R#7) 
  
  Error: testthat unit tests failed
  Execution halted

checking for GNU extensions in Makefiles ... WARNING
Found the following file(s) containing GNU extensions:
  src/Makevars
  src/Makevars.in
Portable Makefiles do not use GNU extensions such as +=, :=, $(shell),
$(wildcard), ifeq ... endif. See section ‘Writing portable packages’ in
the ‘Writing R Extensions’ manual.

checking re-building of vignette outputs ... WARNING
Error in re-building vignettes:
  ...
    Vignettes contain introductory material; view with
    'browseVignettes()'. To cite Bioconductor, see
    'citation("Biobase")', and for packages 'citation("pkgname")'.

Loading required package: IRanges
Loading required package: S4Vectors

... 8 lines ...

    colMeans, colSums, expand.grid, rowMeans, rowSums


Loading required package: RSQLite
Loading required package: DBI

Error: processing vignette 'mgsa.Rnw' failed with diagnostics:
 chunk 6 (label = readGAF) 
Error in guessRowName(df, row.names) : Unknown input
Execution halted

checking top-level files ... NOTE
Non-standard files/directories found at top level:
  ‘acinclude.m4’ ‘aclocal.m4’ ‘script’

checking whether the namespace can be loaded with stated dependencies ... NOTE
Warning: no function found corresponding to methods exports from ‘mgsa’ for: ‘show’

A namespace must be able to be loaded with just the base namespace
loaded: otherwise if the namespace gets loaded by a saved object, the
session will be unable to start.

Probably some imports need to be declared in the NAMESPACE file.

checking dependencies in R code ... NOTE
'library' or 'require' call to ‘gplots’ which was already attached by Depends.
  Please remove these calls from your code.
'library' or 'require' calls in package code:
  ‘DBI’ ‘GO.db’ ‘RSQLite’
  Please use :: or requireNamespace() instead.
  See section 'Suggested packages' in the 'Writing R Extensions' manual.
Packages in Depends field not imported from:
  ‘gplots’ ‘methods’
  These packages need to be imported from (in the NAMESPACE file)
  for when this namespace is loaded but not attached.

checking R code for possible problems ... NOTE
createMgsaGoSets: no visible global function definition for ‘new’
mcmcSummary: no visible binding for global variable ‘sd’
mgsa.wrapper: no visible global function definition for ‘str’
mgsa.wrapper: no visible global function definition for ‘new’
readGAF: no visible global function definition for ‘read.delim’
readGAF: no visible global function definition for ‘na.omit’
readGAF: no visible global function definition for ‘new’
initialize,MgsaSets: no visible global function definition for
  ‘callNextMethod’
... 10 lines ...
  ‘close.screen’
Undefined global functions or variables:
  barplot2 callNextMethod close.screen na.omit new par read.delim
  relist screen sd split.screen str
Consider adding
  importFrom("graphics", "close.screen", "par", "screen", "split.screen")
  importFrom("methods", "callNextMethod", "new")
  importFrom("stats", "na.omit", "sd")
  importFrom("utils", "read.delim", "relist", "str")
to your NAMESPACE file (and ensure that your DESCRIPTION Imports field
contains 'methods').
```

## oligo (1.36.1)
Maintainer: Benilton Carvalho <benilton@unicamp.br>

1 error  | 0 warnings | 8 notes

```
checking examples ... ERROR
Running examples in ‘oligo-Ex.R’ failed
The error most likely occurred in:

> base::assign(".ptime", proc.time(), pos = "CheckExEnv")
> ### Name: MAplot
> ### Title: MA plots
> ### Aliases: MAplot MAplot-methods MAplot,FeatureSet-method
> ###   MAplot,TilingFeatureSet-method MAplot,PLMset-method
> ###   MAplot,ExpressionSet-method MAplot,matrix-method
... 8 lines ...
+   groups <- factor(rep(c('brain', 'UnivRef'), each=3))
+   data.frame(sampleNames(nimbleExpressionFS), groups)
+   MAplot(nimbleExpressionFS, pairs=TRUE, ylim=c(-.5, .5), groups=groups)
+ }
Loading required package: oligoData
Loading required package: pd.hg18.60mer.expr
Loading required package: RSQLite
Loading required package: DBI
Error in loadNamespace(name) : there is no package called ‘KernSmooth’
Calls: MAplot ... tryCatch -> tryCatchList -> tryCatchOne -> <Anonymous>
Execution halted

checking package dependencies ... NOTE
Packages which this enhances but not available for checking: ‘doMC’ ‘doMPI’

checking installed package size ... NOTE
  installed size is 30.1Mb
  sub-directories of 1Mb or more:
    doc      12.9Mb
    scripts  15.7Mb

checking DESCRIPTION meta-information ... NOTE
Packages listed in more than one of Depends, Imports, Suggests, Enhances:
  ‘biomaRt’ ‘AnnotationDbi’ ‘GenomeGraphs’ ‘RCurl’ ‘ff’
A package should be listed in only one of these fields.

checking top-level files ... NOTE
Non-standard file/directory found at top level:
  ‘TODO.org’

checking dependencies in R code ... NOTE
Unexported object imported by a ':::' call: ‘Biobase:::annotatedDataFrameFromMatrix’
  See the note in ?`:::` about the use of this operator.

checking foreign function calls ... NOTE
Foreign function calls to a different package:
  .Call("ReadHeader", ..., PACKAGE = "affyio")
  .Call("read_abatch", ..., PACKAGE = "affyio")
See chapter ‘System and foreign language interfaces’ in the ‘Writing R
Extensions’ manual.

checking R code for possible problems ... NOTE
image,FeatureSet: warning in matrix(NA, nr = geom[1], nc = geom[2]):
  partial argument match of 'nr' to 'nrow'
image,FeatureSet: warning in matrix(NA, nr = geom[1], nc = geom[2]):
  partial argument match of 'nc' to 'ncol'
NUSE: no visible global function definition for ‘abline’
RLE: no visible global function definition for ‘abline’
basicMvApairsPlot: no visible binding for global variable
  ‘smoothScatter’
basicMvApairsPlot: no visible global function definition for ‘frame’
... 36 lines ...
Undefined global functions or variables:
  IQR abline aggregate approx complete.cases data frame intensities
  loess man_fsetid mtext predict rnorm smooth.spline smoothScatter
  splinefun text
Consider adding
  importFrom("graphics", "abline", "frame", "mtext", "smoothScatter",
             "text")
  importFrom("stats", "IQR", "aggregate", "approx", "complete.cases",
             "loess", "predict", "rnorm", "smooth.spline", "splinefun")
  importFrom("utils", "data")
to your NAMESPACE file.

checking Rd line widths ... NOTE
Rd file 'basicRMA.Rd':
  \usage lines wider than 90 characters:
     basicRMA(pmMat, pnVec, normalize = TRUE, background = TRUE, bgversion = 2, destructive = FALSE, verbose = TRUE, ...)

Rd file 'fitProbeLevelModel.Rd':
  \usage lines wider than 90 characters:
     fitProbeLevelModel(object, background=TRUE, normalize=TRUE, target="core", method="plm", verbose=TRUE, S4=TRUE, ...)

Rd file 'getProbeInfo.Rd':
  \usage lines wider than 90 characters:
     getProbeInfo(object, field, probeType = "pm", target = "core", sortBy = c("fid", "man_fsetid", "none"), ...)
  \examples lines wider than 100 characters:
        agenGene <- getProbeInfo(affyGeneFS, field=c('fid', 'fsetid', 'type'), target='probeset', subset= type == 'control->bgp->antigenomic ... [TRUNCATED]

Rd file 'preprocessTools.Rd':
  \usage lines wider than 90 characters:
     backgroundCorrect(object, method=backgroundCorrectionMethods(), copy=TRUE, extra, subset=NULL, target='core', verbose=TRUE)
     normalize(object, method=normalizationMethods(), copy=TRUE, subset=NULL,target='core', verbose=TRUE, ...)

These lines will be truncated in the PDF manual.
```

## PAnnBuilder (1.36.0)
Maintainer: Li Hong <sysptm@gmail.com>

0 errors | 3 warnings | 1 note 

```
checking dependencies in R code ... WARNING
'library' or 'require' call to ‘Biobase’ which was already attached by Depends.
  Please remove these calls from your code.
':::' calls which should be '::':
  ‘AnnotationDbi:::as.list’ ‘base:::get’ ‘tools:::list_files_with_type’
  See the note in ?`:::` about the use of this operator.
Unexported objects imported by ':::' calls:
  ‘AnnotationDbi:::createAnnDbBimaps’
  ‘AnnotationDbi:::prefixAnnObjNames’ ‘tools:::makeLazyLoadDB’
  See the note in ?`:::` about the use of this operator.
  Including base/recommended package(s):
  ‘tools’
There are ::: calls to the package's namespace in its code. A package
  almost never needs to use ::: for its own objects:
  ‘getShortSciName’ ‘twoStepSplit’

checking R code for possible problems ... WARNING
Found an obsolete/platform-specific call in the following function:
  ‘makeLLDB’
Found the defunct/removed function:
  ‘.saveRDS’

In addition to the above warning(s), found the following notes:

File ‘PAnnBuilder/R/zzz.R’:
  .onLoad calls:
    require(Biobase)

Package startup functions should not change the search path.
See section ‘Good practice’ in '?.onAttach'.

Found the following calls to data() loading into the global environment:
File ‘PAnnBuilder/R/writeManPage.R’:
  data("descriptionInfo")
  data("descriptionInfo")
See section ‘Good practice’ in ‘?data’.

checking re-building of vignette outputs ... WARNING
Error in re-building vignettes:
  ...
             }
     

trying URL 'http://gpcr2.biocomp.unibo.it/bacello/dataset.htm'
Content type 'text/html; charset=iso-8859-1' length 5062 bytes
==================================================
downloaded 5062 bytes
... 8 lines ...
Warning in rsqlite_disconnect(conn@ptr) :
  There are 1 result in use. The connection will be released when they are closed
Error in texi2dvi(file = file, pdf = TRUE, clean = clean, quiet = quiet,  : 
  Running 'texi2dvi' on 'PAnnBuilder.tex' failed.
LaTeX errors:
! Package auto-pst-pdf Error: 
    "shell escape" (or "write18") is not enabled:
    auto-pst-pdf will not work!
.
Calls: buildVignettes -> texi2pdf -> texi2dvi
Execution halted

checking DESCRIPTION meta-information ... NOTE
Packages listed in more than one of Depends, Imports, Suggests, Enhances:
  ‘methods’ ‘utils’ ‘Biobase’ ‘RSQLite’ ‘AnnotationDbi’
A package should be listed in only one of these fields.
```

## plethy (1.10.0)
Maintainer: Daniel Bottomly <bottomly@ohsu.edu>

2 errors | 1 warning  | 3 notes

```
checking examples ... ERROR
Running examples in ‘plethy-Ex.R’ failed
The error most likely occurred in:

> base::assign(".ptime", proc.time(), pos = "CheckExEnv")
> ### Name: BuxcoDB-class
> ### Title: Class '"BuxcoDB"'
> ### Aliases: BuxcoDB-class BuxcoDB addAnnotation,BuxcoDB-method
> ###   addAnnotation annoTable,BuxcoDB-method annoTable
> ###   annoCols,BuxcoDB-method annoCols annoLevels,BuxcoDB-method annoLevels
... 53 lines ...
> 
> tables(bux.db)
[1] "WBPth"
> 
> variables(bux.db)
 [1] "f"     "TVb"   "MVb"   "Penh"  "PAU"   "Rpef"  "Comp"  "PIFb"  "PEFb" 
[10] "Ti"    "Te"    "EF50"  "Tr"    "Tbody" "Tc"    "RH"    "Rinx" 
> 
> addAnnotation(bux.db, query=day.infer.query, index=FALSE)
Error: is.null(dbGetQuery(db.con, i)) is not TRUE
Execution halted

checking tests ... ERROR
Running the tests in ‘tests/runTests.R’ failed.
Last 13 lines of output:
       test.db.insert.autoincrement 
       test.dbImport 
       test.examine.table.lines 
       test.get.err.breaks 
       test.parse.buxco 
       test.retrieveData 
       test.summaryMeasures 
       test.write.sample.db 
  
  
  Error in BiocGenerics:::testPackage("plethy") : 
    unit tests failed for package plethy
  Execution halted

checking re-building of vignette outputs ... WARNING
Error in re-building vignettes:
  ...

    IQR, mad, xtabs

The following objects are masked from ‘package:base’:

    Filter, Find, Map, Position, Reduce, anyDuplicated, append, as.data.frame,
    cbind, colnames, do.call, duplicated, eval, evalq, get, grep, grepl,
... 8 lines ...
Attaching package: ‘S4Vectors’

The following objects are masked from ‘package:base’:

    colMeans, colSums, expand.grid, rowMeans, rowSums


Error: processing vignette 'plethy.Rnw' failed with diagnostics:
 chunk 3 
Error : is.null(dbGetQuery(db.con, query.list[[i]])) is not TRUE
Execution halted

checking dependencies in R code ... NOTE
There are ::: calls to the package's namespace in its code. A package
  almost never needs to use ::: for its own objects:
  ‘csv.to.table’ ‘find.break.ranges.integer’ ‘fix.time’ ‘multi.grep’

checking R code for possible problems ... NOTE
generate.sample.buxco : <anonymous> : <anonymous> : <anonymous> :
  <anonymous>: no visible global function definition for ‘rnorm’
make.db.package: no visible global function definition for
  ‘packageDescription’
mvtsplot.data.frame: no visible global function definition for ‘colors’
mvtsplot.data.frame: no visible global function definition for ‘par’
mvtsplot.data.frame: no visible global function definition for ‘layout’
mvtsplot.data.frame: no visible global function definition for
  ‘strwidth’
... 14 lines ...
tsplot,BuxcoDB: no visible binding for global variable ‘Sample_Name’
Undefined global functions or variables:
  Axis Days Sample_Name Value abline bxp colors layout legend lines
  median mtext packageDescription par plot rnorm strwidth terms
Consider adding
  importFrom("grDevices", "colors")
  importFrom("graphics", "Axis", "abline", "bxp", "layout", "legend",
             "lines", "mtext", "par", "plot", "strwidth")
  importFrom("stats", "median", "rnorm", "terms")
  importFrom("utils", "packageDescription")
to your NAMESPACE file.

checking Rd line widths ... NOTE
Rd file 'parsing.Rd':
  \usage lines wider than 90 characters:
     parse.buxco(file.name = NULL, table.delim = "Table", burn.in.lines = c("Measurement", "Create measurement", "Waiting for", "Site Acknow ... [TRUNCATED]
       chunk.size = 500, db.name = "bux_test.db", max.run.time.minutes = 60, overwrite = TRUE, verbose=TRUE, make.package = F, author = NULL ... [TRUNCATED]
     parse.buxco.basic(file.name=NULL, table.delim="Table", burn.in.lines=c("Measurement", "Create measurement", "Waiting for", "Site Acknow ... [TRUNCATED]

Rd file 'utilities.Rd':
  \usage lines wider than 90 characters:
     get.err.breaks(bux.db, max.exp.count=150, max.acc.count=900, vary.perc=.1, label.val="ERR")
     proc.sanity(bux.db, max.exp.time=300, max.acc.time=1800, max.exp.count=150, max.acc.count=900)
  \examples lines wider than 100 characters:
     err.dta <- data.frame(samples=samples, count=count, measure_break=measure_break, table_break=table_break, phase=phase, stringsAsFactors ... [TRUNCATED]
     sample.labels <- data.frame(samples=c("sample_1","sample_3"), response_type=c("high", "low"),stringsAsFactors=FALSE)

These lines will be truncated in the PDF manual.
```

## poplite (0.99.16)
Maintainer: Daniel Bottomly <bottomly@ohsu.edu>

1 error  | 1 warning  | 1 note 

```
checking tests ... ERROR
Running the tests in ‘tests/testthat.R’ failed.
Last 13 lines of output:
  1. Failure: createTable (@test-poplite.R#252) 
  2. Failure: createTable (@test-poplite.R#252) 
  3. Failure: createTable (@test-poplite.R#252) 
  4. Failure: createTable (@test-poplite.R#252) 
  5. Failure: insertStatement (@test-poplite.R#330) 
  6. Failure: insertStatement (@test-poplite.R#350) 
  7. Failure: insertStatement (@test-poplite.R#330) 
  8. Failure: insertStatement (@test-poplite.R#350) 
  9. Failure: insertStatement (@test-poplite.R#330) 
  1. ...
  
  Error: testthat unit tests failed
  Execution halted

checking examples ... WARNING
Found the following significant warnings:

  Warning: 'dbGetPreparedQuery' is deprecated.
  Warning: 'dbGetPreparedQuery' is deprecated.
  Warning: 'dbGetPreparedQuery' is deprecated.
  Warning: 'dbGetPreparedQuery' is deprecated.
Deprecated functions may be defunct as soon as of the next release of
R.
See ?Deprecated.

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

## rangeMapper (0.3-0)
Maintainer: Mihai Valcu <valcu@orn.mpg.de>

2 errors | 1 warning  | 0 notes

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
... 26 lines ...
> 
> X = WKT2SpatialPolygonsDataFrame(d, 'range', 'nam')
> 
> 
> dbcon = rangeMap.start(file = "test.sqlite", overwrite = TRUE, dir = tempdir() )
New session 2016-09-01 10:31:37
PROJECT: test.sqlite 
DIRECTORY: /tmp/RtmpyuE6jZ
> global.bbox.save(con = dbcon, bbox = X)
Error: table bbox has no column named min
Execution halted

checking tests ... ERROR
Running the tests in ‘tests/testthat.R’ failed.
Last 13 lines of output:
  PROJECT: wrens.sqlite 
  DIRECTORY: /tmp/RtmppFFiCl
  Error: table bbox has no column named min
  testthat results ================================================================
  OK: 9 SKIPPED: 0 FAILED: 5
  1. Error: Pipeline works forward only (@test-1_projectINI.R#35) 
  2. Error: Range overlay returns a data.frame (@test-1_projectINI.R#67) 
  3. Error: reprojecting on the fly (@test-2_processRanges.R#10) 
  4. Error: ONE SpPolyDF NO metadata (@test-2_processRanges.R#22) 
  5. Error: ONE SpPolyDF WITH metadata (@test-2_processRanges.R#41) 
  
  Error: testthat unit tests failed
  Execution halted

checking re-building of vignette outputs ... WARNING
Error in re-building vignettes:
  ...
Warning: It seems you should call rmarkdown::render() instead of knitr::knit2html() because Appendix_S2_Valcu_et_al_2012.Rmd appears to be an R Markdown v2 document.
Quitting from lines 74-86 (Appendix_S2_Valcu_et_al_2012.Rmd) 
Error: processing vignette 'Appendix_S2_Valcu_et_al_2012.Rmd' failed with diagnostics:
non-numeric argument to binary operator
Execution halted

```

## RecordLinkage (0.4-10)
Maintainer: Andreas Borg <borga@uni-mainz.de>

0 errors | 1 warning  | 0 notes

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
```

## RObsDat (16.03)
Maintainer: Dominik Reusser <reusser@pik-potsdam.de>

1 error  | 0 warnings | 0 notes

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
```

## rplexos (1.1.8)
Maintainer: Clayton Barrows <clayton.barrows@nrel.gov>  
Bug reports: https://github.com/NREL/rplexos/issues

0 errors | 1 warning  | 0 notes

```
checking examples ... WARNING
Found the following significant warnings:

  Warning: 'dbGetPreparedQuery' is deprecated.
  Warning: 'dbGetPreparedQuery' is deprecated.
  Warning: 'dbGetPreparedQuery' is deprecated.
  Warning: 'dbGetPreparedQuery' is deprecated.
  Warning: 'dbGetPreparedQuery' is deprecated.
  Warning: 'dbGetPreparedQuery' is deprecated.
  Warning: 'dbGetPreparedQuery' is deprecated.
... 244 lines ...
  Warning: 'dbGetPreparedQuery' is deprecated.
  Warning: 'dbGetPreparedQuery' is deprecated.
  Warning: 'dbGetPreparedQuery' is deprecated.
  Warning: 'dbGetPreparedQuery' is deprecated.
  Warning: 'dbGetPreparedQuery' is deprecated.
  Warning: 'dbGetPreparedQuery' is deprecated.
  Warning: 'dbGetPreparedQuery' is deprecated.
  Warning: 'dbGetPreparedQuery' is deprecated.
Deprecated functions may be defunct as soon as of the next release of
R.
See ?Deprecated.
```

## specL (1.6.2)
Maintainer: Christian Panse <cp@fgcz.ethz.ch>, Witold E. Wolski <wewolski@gmail.com>  
Bug reports: https://github.com/fgcz/specL/issues

1 error  | 1 warning  | 4 notes

```
checking tests ... ERROR
Running the tests in ‘tests/runTests.R’ failed.
Last 13 lines of output:
  1 Test Suite : 
  specL RUnit Tests - 9 test functions, 1 error, 0 failures
  ERROR in /tmp/RtmpwmOxEE/RLIBS_7ccd70c9d294/specL/unitTests/test_read.bibliospec.R: Error while sourcing  /tmp/RtmpwmOxEE/RLIBS_7ccd70c9d294/specL/unitTests/test_read.bibliospec.R : Error in msg$errorMsg : $ operator is invalid for atomic vectors
  
  Test files with failing tests
  
     test_read.bibliospec.R 
       /tmp/RtmpwmOxEE/RLIBS_7ccd70c9d294/specL/unitTests/test_read.bibliospec.R 
  
  
  Error in BiocGenerics:::testPackage("specL") : 
    unit tests failed for package specL
  Execution halted

checking re-building of vignette outputs ... WARNING
Error in re-building vignettes:
  ...
Warning: It seems you should call rmarkdown::render() instead of knitr::knit2html() because cdsw.Rmd appears to be an R Markdown v2 document.
Quitting from lines 2-25 (cdsw.Rmd) 
Error: processing vignette 'cdsw.Rmd' failed with diagnostics:
could not find function "doc_date"
Execution halted


checking for hidden files and directories ... NOTE
Found the following hidden files and directories:
  .travis.yml
These were most likely included in error. See section ‘Package
structure’ in the ‘Writing R Extensions’ manual.

checking S3 generic/method consistency ... NOTE
Found the following apparent S3 methods exported but not registered:
  merge.specLSet plot.psm plot.psmSet summary.psmSet
See section ‘Registering S3 methods’ in the ‘Writing R Extensions’
manual.

checking R code for possible problems ... NOTE
plot,specLSet: no visible global function definition for ‘draw.circle’
summary,specLSet : <anonymous>: no visible binding for global variable
  ‘iRTpeptides’
Undefined global functions or variables:
  draw.circle iRTpeptides

checking Rd files ... NOTE
prepare_Rd: ms1.p2069.Rd:28-32: Dropping empty section \references
prepare_Rd: ms1.p2069.Rd:23-26: Dropping empty section \examples
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
Loading required package: data.table
No methods found in "RSQLite" for requests: dbGetQuery
tcpl (v1.2.2) loaded with the following settings:
  TCPL_DB:    /home/muelleki/git/R/RSQLite/revdep/checks/tcpl.Rcheck/tcpl/sql/tcpldb.sqlite
  TCPL_USER:  NA
  TCPL_HOST:  NA
  TCPL_DRVR:  SQLite
Default settings stored in TCPL.conf. See ?tcplConf for more information.
Warning: Closing open result set, pending rows
Warning: Closing open result set, pending rows
Warning: Closing open result set, pending rows
Warning: Closing open result set, pending rows
Warning: Closing open result set, pending rows
Warning: Closing open result set, pending rows
Warning: Closing open result set, pending rows
Warning: Closing open result set, pending rows

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

## TFBSTools (1.10.3)
Maintainer: Ge Tan <ge.tan09@imperial.ac.uk>  
Bug reports: https://github.com/ge11232002/TFBSTools/issues

2 errors | 1 warning  | 2 notes

```
checking examples ... ERROR
Running examples in ‘TFBSTools-Ex.R’ failed
The error most likely occurred in:

> base::assign(".ptime", proc.time(), pos = "CheckExEnv")
> ### Name: PFMSimilarity-methods
> ### Title: PFMSimilarity method
> ### Aliases: PFMSimilarity PFMSimilarity-methods
> ###   PFMSimilarity,matrix,character-method
> ###   PFMSimilarity,matrix,matrix-method
... 59 lines ...
+     nrow=4, byrow=TRUE, dimnames=list(DNA_BASES))
>   pfmQuery <- PFMatrix(profileMatrix=profileMatrix)
>   pfmSubjects <- getMatrixSet(JASPAR2016,
+                               opts=list(ID=c("MA0500", "MA0499", "MA0521",
+                                              "MA0697", "MA0048", "MA0751",
+                                              "MA0832")))
Error in .get_latest_version(con, baseID) : 
  could not find function "dbGetQuery"
Calls: getMatrixSet ... getMatrixSet -> .get_IDlist_by_query -> .get_latest_version
Execution halted
** found \donttest examples: check also with --run-donttest

checking tests ... ERROR
Running the tests in ‘tests/testthat.R’ failed.
Last 13 lines of output:
  3: getMatrixSet(x@db, opts)
  4: getMatrixSet(x@db, opts)
  5: getMatrixSet(con, opts)
  6: getMatrixSet(con, opts)
  7: .get_IDlist_by_query(x, opts)
  8: .get_latest_version(con, baseID)
  
  testthat results ================================================================
  OK: 26 SKIPPED: 0 FAILED: 1
  1. Error: test_PFMSimilarity (@test_PFM.R#11) 
  
  Error: testthat unit tests failed
  Execution halted

checking re-building of vignette outputs ... WARNING
Error in re-building vignettes:
  ...
Warning: It seems you should call rmarkdown::render() instead of knitr::knit2html() because TFBSTools.Rmd appears to be an R Markdown v2 document.
Quitting from lines 2-16 (TFBSTools.Rmd) 
Error: processing vignette 'TFBSTools.Rmd' failed with diagnostics:
could not find function "doc_date"
Execution halted


checking dependencies in R code ... NOTE
Unexported objects imported by ':::' calls:
  ‘S4Vectors:::new_SimpleList_from_list’ ‘seqLogo:::pwm2ic’
  See the note in ?`:::` about the use of this operator.

checking R code for possible problems ... NOTE
.TAXIDToSpecies: no visible global function definition for ‘dbGetQuery’
.create_tables: no visible global function definition for ‘dbGetQuery’
.fixTAXID: no visible global function definition for ‘dbGetQuery’
.get_IDlist_by_query: no visible global function definition for
  ‘dbGetQuery’
.get_Matrix_by_int_id: no visible global function definition for
  ‘dbGetQuery’
.get_internal_id: no visible global function definition for
  ‘dbGetQuery’
... 9 lines ...
  ‘dbGetQuery’
.store_matrix_data: no visible global function definition for
  ‘dbGetQuery’
.store_matrix_species: no visible global function definition for
  ‘dbGetQuery’
deleteMatrixHavingID,SQLiteConnection: no visible global function
  definition for ‘dbGetQuery’
getMatrixByName,SQLiteConnection: no visible global function definition
  for ‘dbGetQuery’
Undefined global functions or variables:
  dbGetQuery
```

## VariantFiltering (1.8.6)
Maintainer: Robert Castelo <robert.castelo@upf.edu>  
Bug reports: https://github.com/rcastelo/VariantFiltering/issues

0 errors | 3 warnings | 4 notes

```
checking Rd cross-references ... WARNING
package ‘MafDb.1Kgenomes.phase3.hs37d5’ exists but was not installed under R >= 2.10.0 so xrefs cannot be checked
Packages unavailable to check Rd xrefs: ‘MafDb.1Kgenomes.phase1.hs37d5’, ‘phastCons100way.UCSC.hg38’

checking sizes of PDF files under ‘inst/doc’ ... WARNING
  ‘gs+qpdf’ made some significant size reductions:
     compacted ‘usingVariantFiltering.pdf’ from 436Kb to 154Kb
  consider running tools::compactPDF(gs_quality = "ebook") on these files

checking re-building of vignette outputs ... WARNING
Error in re-building vignettes:
  ...
Loading required package: XVector

Attaching package: ‘VariantAnnotation’

The following object is masked from ‘package:base’:

    tabulate
... 8 lines ...
Error in eval(expr, envir, enclos) : database disk image is malformed
Error in eval(expr, envir, enclos) : database disk image is malformed
Error : .onLoad failed in loadNamespace() for 'MafDb.1Kgenomes.phase3.hs37d5', details:
  call: eval(expr, envir, enclos)
  error: database disk image is malformed

Error: processing vignette 'usingVariantFiltering.Rnw' failed with diagnostics:
 chunk 3 
Error in VariantFilteringParam(vcfFilenames = CEUvcf) : 
  package MafDb.1Kgenomes.phase3.hs37d5 could not be loaded.
Execution halted

checking installed package size ... NOTE
  installed size is  7.7Mb
  sub-directories of 1Mb or more:
    R         3.3Mb
    extdata   3.5Mb

checking dependencies in R code ... NOTE
Unexported objects imported by ':::' calls:
  'S4Vectors:::labeledLine' 'VariantAnnotation:::.checkArgs'
  'VariantAnnotation:::.consolidateHits'
  'VariantAnnotation:::.returnEmpty'
  See the note in ?`:::` about the use of this operator.

checking R code for possible problems ... NOTE
.dbEasyQuery: no visible global function definition for 'dbGetQuery'
Undefined global functions or variables:
  dbGetQuery

checking Rd line widths ... NOTE
Rd file 'MafDb-class.Rd':
  \examples lines wider than 100 characters:
       ## founder mutation in a regulatory element located within the HERC2 gene inhibiting OCA2 expression.

Rd file 'MafDb2-class.Rd':
  \examples lines wider than 100 characters:
       ## founder mutation in a regulatory element located within the HERC2 gene inhibiting OCA2 expression.

Rd file 'VariantFilteringParam-class.Rd':
... 17 lines ...

Rd file 'autosomalRecessiveHeterozygous.Rd':
  \usage lines wider than 90 characters:
                                                                      BPPARAM=bpparam("SerialParam"))

Rd file 'autosomalRecessiveHomozygous.Rd':
  \usage lines wider than 90 characters:
                                                                    use=c("everything", "complete.obs", "all.obs"),
                                                                    BPPARAM=bpparam("SerialParam"))

These lines will be truncated in the PDF manual.
```

