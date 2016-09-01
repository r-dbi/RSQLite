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
|DBItest   |   |1.3-7      |2016-09-01 |Github (rstats-db/DBItest@75c8ebc) |
|knitr     |   |1.14       |2016-08-13 |cran (@1.14)                       |
|Rcpp      |   |0.12.6     |2016-07-19 |cran (@0.12.6)                     |
|rmarkdown |   |1.0        |2016-07-08 |cran (@1.0)                        |
|RSQLite   |   |1.0.9008   |2016-09-01 |local (rstats-db/RSQLite@4b16bda)  |
|testthat  |   |1.0.2.9000 |2016-08-25 |Github (hadley/testthat@46d15da)   |

# Check results

9 packages with problems

|package       |version | errors| warnings| notes|
|:-------------|:-------|------:|--------:|-----:|
|AnnotationHub |2.4.2   |      1|        1|     0|
|cummeRbund    |2.14.0  |      1|        1|     7|
|DECIPHER      |2.0.2   |      1|        3|     3|
|GWASTools     |1.18.0  |      2|        0|     2|
|mgsa          |1.20.0  |      2|        2|     4|
|poplite       |0.99.16 |      1|        1|     1|
|rangeMapper   |0.3-0   |      2|        1|     0|
|specL         |1.6.2   |      1|        1|     4|
|tcpl          |1.2.2   |      1|        1|     1|

## AnnotationHub (2.4.2)
Maintainer: Bioconductor Package Maintainer <maintainer@bioconductor.org>

1 error  | 1 warning  | 0 notes

```
checking tests ... ERROR
Running the tests in ‘tests/runTests.R’ failed.
Last 13 lines of output:
  FAILURE in test_cache_datapathIds: Error in checkIdentical(result, setNames(integer(), character())) : 
    FALSE 
   
  
  Test files with failing tests
  
     test_cache.R 
       test_cache_datapathIds 
  
  
  Error in BiocGenerics:::testPackage("AnnotationHub") : 
    unit tests failed for package AnnotationHub
  Execution halted

checking re-building of vignette outputs ... WARNING
Error in re-building vignettes:
  ...
Warning: It seems you should call rmarkdown::render() instead of knitr::knit2html() because AnnotationHub-HOWTO.Rmd appears to be an R Markdown v2 document.
loading from cache '/home/muelleki/.AnnotationHub/57158'
    '/home/muelleki/.AnnotationHub/57159'

 *** caught segfault ***
address (nil), cause 'memory not mapped'

Traceback:
 1: .Call(rmd_render_markdown, file, output, text, renderer, renderer.options,     extensions)
 2: renderMarkdown(file, output = NULL, text, renderer = "HTML",     renderer.options = options, extensions = extensions, encoding = encoding)
 3: markdown::markdownToHTML(out, output, encoding = encoding, ...)
 4: (if (grepl("\\.[Rr]md$", file)) knit2html else if (grepl("\\.[Rr]rst$",     file)) knit2pdf else knit)(file, encoding = encoding, quiet = quiet,     envir = globalenv())
 5: vweave(...)
 6: engine$weave(file, quiet = quiet, encoding = enc)
 7: doTryCatch(return(expr), name, parentenv, handler)
 8: tryCatchOne(expr, names, parentenv, handlers[[1L]])
 9: tryCatchList(expr, classes, parentenv, handlers)
10: tryCatch({    engine$weave(file, quiet = quiet, encoding = enc)    setwd(startdir)    find_vignette_product(name, by = "weave", engine = engine)}, error = function(e) {    stop(gettextf("processing vignette '%s' failed with diagnostics:\n%s",         file, conditionMessage(e)), domain = NA, call. = FALSE)})
11: buildVignettes(dir = "/home/muelleki/git/R/RSQLite/revdep/checks/AnnotationHub.Rcheck/vign_test/AnnotationHub")
An irrecoverable exception occurred. R is aborting now ...
Segmentation fault (core dumped)

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
New session 2016-09-01 20:04:14
PROJECT: test.sqlite 
DIRECTORY: /tmp/RtmpaPeHx6
> global.bbox.save(con = dbcon, bbox = X)
Error: table bbox has no column named min
Execution halted

checking tests ... ERROR
Running the tests in ‘tests/testthat.R’ failed.
Last 13 lines of output:
  PROJECT: wrens.sqlite 
  DIRECTORY: /tmp/RtmpFHmzgd
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
Warning: It seems you should call rmarkdown::render() instead of knitr::knit2html() because Appendix_S3_Valcu_et_al_2012.Rmd appears to be an R Markdown v2 document.
Quitting from lines 27-35 (Appendix_S3_Valcu_et_al_2012.Rmd) 
Error: processing vignette 'Appendix_S3_Valcu_et_al_2012.Rmd' failed with diagnostics:
table bbox has no column named min
Execution halted

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
  ERROR in /tmp/RtmpWceZxP/RLIBS_3e684ee5a1cf/specL/unitTests/test_read.bibliospec.R: Error while sourcing  /tmp/RtmpWceZxP/RLIBS_3e684ee5a1cf/specL/unitTests/test_read.bibliospec.R : Error in msg$errorMsg : $ operator is invalid for atomic vectors
  
  Test files with failing tests
  
     test_read.bibliospec.R 
       /tmp/RtmpWceZxP/RLIBS_3e684ee5a1cf/specL/unitTests/test_read.bibliospec.R 
  
  
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

## tcpl (1.2.2)
Maintainer: Dayne L Filer <dayne.filer@gmail.com>

1 error  | 1 warning  | 1 note 

```
checking examples ... ERROR
Running examples in ‘tcpl-Ex.R’ failed
The error most likely occurred in:

> base::assign(".ptime", proc.time(), pos = "CheckExEnv")
> ### Name: tcplPlotM4ID
> ### Title: Plot fit summary plot by m4id
> ### Aliases: tcplPlotM4ID
> 
> ### ** Examples
> 
> ## Store the current config settings, so they can be reloaded at the end 
> ## of the examples
> conf_store <- tcplConfList()
> tcplConfDefault()
>  
> tcplPlotM4ID(m4id = 686, lvl = 4) ## Create a level 4 plot
Error in signif(c(gnls_tp_sd, gnls_ga_sd, gnls_gw_sd, gnls_la_sd, gnls_lw_sd),  : 
  non-numeric argument to mathematical function
Calls: tcplPlotM4ID ... tcplPlotFits -> .plotFit -> with -> with.default -> eval -> eval
Execution halted

checking re-building of vignette outputs ... WARNING
Error in re-building vignettes:
  ...
Loading required package: data.table
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

