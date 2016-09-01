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

|package  |*  |version    |date       |source                           |
|:--------|:--|:----------|:----------|:--------------------------------|
|DBI      |   |0.5        |2016-08-25 |Github (rstats-db/DBI@1e37697)   |
|RSQLite  |   |1.0.0      |2016-09-01 |local (rstats-db/RSQLite@NA)     |
|testthat |   |1.0.2.9000 |2016-08-25 |Github (hadley/testthat@46d15da) |

# Check results
15 packages with problems

|package          |version | errors| warnings| notes|
|:----------------|:-------|------:|--------:|-----:|
|AnnotationDbi    |1.34.4  |      0|        1|     5|
|Category         |2.38.0  |      0|        1|     1|
|DECIPHER         |2.0.2   |      0|        2|     2|
|Genominator      |1.26.0  |      0|        1|     4|
|mgsa             |1.20.0  |      0|        1|     4|
|oligo            |1.36.1  |      1|        1|     8|
|PAnnBuilder      |1.36.0  |      0|        4|     1|
|pdInfoBuilder    |1.36.0  |      0|        1|     1|
|plethy           |1.10.0  |      2|        0|     3|
|specL            |1.6.2   |      0|        1|     4|
|sqldf            |0.4-10  |      0|        1|     2|
|TFBSTools        |1.10.3  |      0|        1|     1|
|tigre            |1.26.0  |      0|        1|     2|
|UniProt.ws       |2.12.0  |      0|        1|     1|
|VariantFiltering |1.8.6   |      0|        3|     3|

## AnnotationDbi (1.34.4)
Maintainer: Bioconductor Package Maintainer
 <maintainer@bioconductor.org>

0 errors | 1 warning  | 5 notes

```
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

## Category (2.38.0)
Maintainer: Bioconductor Package Maintainer <maintainer@bioconductor.org>

0 errors | 1 warning  | 1 note 

```
checking whether package ‘Category’ can be installed ... WARNING
Found the following significant warnings:
  Warning: namespace ‘Rcpp’ is not available and has been replaced
See ‘/home/muelleki/git/R/RSQLite/revdep/checks/Category.Rcheck/00install.out’ for details.

checking R code for possible problems ... NOTE
.linearMTestInternal: no visible global function definition for
  ‘setNames’
Undefined global functions or variables:
  setNames
Consider adding
  importFrom("stats", "setNames")
to your NAMESPACE file.
```

## DECIPHER (2.0.2)
Maintainer: Erik Wright <DECIPHER@cae.wisc.edu>

0 errors | 2 warnings | 2 notes

```
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

checking installed package size ... NOTE
  installed size is  9.2Mb
  sub-directories of 1Mb or more:
    data      2.5Mb
    doc       3.9Mb
    extdata   1.4Mb

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

## Genominator (1.26.0)
Maintainer: James Bullard <bullard@stat.berkeley.edu>

0 errors | 1 warning  | 4 notes

```
checking whether package ‘Genominator’ can be installed ... WARNING
Found the following significant warnings:
  Warning: namespace ‘Rcpp’ is not available and has been replaced
See ‘/home/muelleki/git/R/RSQLite/revdep/checks/Genominator.Rcheck/00install.out’ for details.

checking dependencies in R code ... NOTE
'library' or 'require' calls to packages already attached by Depends:
  ‘GenomeGraphs’ ‘IRanges’
  Please remove these calls from your code.
'library' or 'require' call to ‘ShortRead’ in package code.
  Please use :: or requireNamespace() instead.
  See section 'Suggested packages' in the 'Writing R Extensions' manual.
Packages in Depends field not imported from:
  ‘GenomeGraphs’ ‘RSQLite’
  These packages need to be imported from (in the NAMESPACE file)
  for when this namespace is loaded but not attached.

checking S3 generic/method consistency ... NOTE
Found the following apparent S3 methods exported but not registered:
  plot.genominator.coverage plot.genominator.goodness.of.fit
See section ‘Registering S3 methods’ in the ‘Writing R Extensions’
manual.

checking R code for possible problems ... NOTE
addPrimingWeights: no visible global function definition for
  ‘varLabels’
addPrimingWeights: no visible global function definition for
  ‘alignData’
addPrimingWeights: no visible global function definition for ‘subseq’
addPrimingWeights: no visible global function definition for ‘sread’
addPrimingWeights: no visible global function definition for
  ‘AlignedDataFrame’
addPrimingWeights: no visible global function definition for ‘pData’
... 46 lines ...
  function definition for ‘qunif’
plot.genominator.goodness.of.fit : <anonymous>: no visible global
  function definition for ‘qqplot’
Undefined global functions or variables:
  AlignedDataFrame DisplayPars alignData chromosome gdPlot
  geneRegionBiomart makeAnnotationTrack makeBaseTrack makeGenericArray
  makeGenomeAxis mkAllStrings pData position ppoints qchisq qqplot
  qunif readAligned sread subseq tables varLabels varMetadata
Consider adding
  importFrom("stats", "ppoints", "qchisq", "qqplot", "qunif")
to your NAMESPACE file.

checking Rd line widths ... NOTE
Rd file 'makeGeneRepresentation.Rd':
  \usage lines wider than 90 characters:
     "background"), gene.id = "ensembl_gene_id", transcript.id = "ensembl_transcript_id", bind.columns, ignoreStrand = TRUE, verbose = getOp ... [TRUNCATED]

These lines will be truncated in the PDF manual.
```

## mgsa (1.20.0)
Maintainer: Sebastian Bauer <mail@sebastianbauer.info>

0 errors | 1 warning  | 4 notes

```
checking for GNU extensions in Makefiles ... WARNING
Found the following file(s) containing GNU extensions:
  src/Makevars
  src/Makevars.in
Portable Makefiles do not use GNU extensions such as +=, :=, $(shell),
$(wildcard), ifeq ... endif. See section ‘Writing portable packages’ in
the ‘Writing R Extensions’ manual.

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

1 error  | 1 warning  | 8 notes

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

checking whether package ‘oligo’ can be installed ... WARNING
Found the following significant warnings:
  Warning: namespace ‘Rcpp’ is not available and has been replaced
See ‘/home/muelleki/git/R/RSQLite/revdep/checks/oligo.Rcheck/00install.out’ for details.

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

0 errors | 4 warnings | 1 note 

```
checking whether package ‘PAnnBuilder’ can be installed ... WARNING
Found the following significant warnings:
  Warning: namespace ‘Rcpp’ is not available and has been replaced
See ‘/home/muelleki/git/R/RSQLite/revdep/checks/PAnnBuilder.Rcheck/00install.out’ for details.

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
             if(length(xx) > 0){
                     # Get the value of the first key
                     xx[[1]]
                     # Get the values for a few keys
                     if(length(xx) >= 3){
                             xx[1:3]
                     }
... 8 lines ...

Warning in .local(conn, ...) : Closing open result set
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

## pdInfoBuilder (1.36.0)
Maintainer: Benilton Carvalho <beniltoncarvalho@gmail.com>

0 errors | 1 warning  | 1 note 

```
checking whether package ‘pdInfoBuilder’ can be installed ... WARNING
Found the following significant warnings:
  Warning: namespace ‘Rcpp’ is not available and has been replaced
See ‘/home/muelleki/git/R/RSQLite/revdep/checks/pdInfoBuilder.Rcheck/00install.out’ for details.

checking R code for possible problems ... NOTE
cdf2table: no visible global function definition for ‘getDoParWorkers’
cdf2table: no visible global function definition for ‘%dopar%’
cdf2table: no visible global function definition for ‘foreach’
cdf2table: no visible binding for global variable ‘unitLst’
cdfUnits2table: no visible global function definition for ‘%do%’
cdfUnits2table: no visible global function definition for ‘foreach’
cdfUnits2table: no visible binding for global variable ‘i’
createChrDict: no visible global function definition for ‘na.omit’
getAllFSetMpsTables: no visible global function definition for
  ‘%dopar%’
getAllFSetMpsTables: no visible global function definition for
  ‘foreach’
getAllFSetMpsTables: no visible binding for global variable ‘i’
parseBpmapCel: no visible global function definition for ‘aggregate’
parseCdfSeqAnnotSnp: no visible global function definition for
  ‘aggregate’
parseNgsTrio: no visible global function definition for ‘aggregate’
Undefined global functions or variables:
  %do% %dopar% aggregate foreach getDoParWorkers i na.omit unitLst
Consider adding
  importFrom("stats", "aggregate", "na.omit")
to your NAMESPACE file.
```

## plethy (1.10.0)
Maintainer: Daniel Bottomly <bottomly@ohsu.edu>

2 errors | 0 warnings | 3 notes

```
checking examples ... ERROR
Running examples in ‘plethy-Ex.R’ failed
The error most likely occurred in:

> base::assign(".ptime", proc.time(), pos = "CheckExEnv")
> ### Name: Utility functions
> ### Title: Utility functions to assist with QA/QC and analysis of
> ###   plethysmography data
> ### Aliases: add.labels.by.sample get.err.breaks adjust.labels proc.sanity
> ### Keywords: Utilities
... 21 lines ...
> temp.db.file <- tempfile()
> write(sim.bux.lines, file=temp.file)
> test.bux.db <- parse.buxco(file.name=temp.file, db.name=temp.db.file, chunk.size=10000)
Processing /tmp/Rtmp246wIW/file28ce495c6045 in chunks of 10000
Starting chunk 1
Reached breakpoint change
Processing breakpoint 1
Starting sample sample_1
Error in if (sum(which.gt) > 0) { : missing value where TRUE/FALSE needed
Calls: parse.buxco ... write.sample.breaks -> write.sample.db -> sanity.check.time
Execution halted

checking tests ... ERROR
Running the tests in ‘tests/runTests.R’ failed.
Last 13 lines of output:
  
     test_check_helpers.R 
       test.add.labels.by.sample 
       test.dbImport 
       test.get.err.breaks 
       test.summaryMeasures 
  
  
  Error in BiocGenerics:::testPackage("plethy") : 
    unit tests failed for package plethy
  In addition: Warning message:
  closing unused connection 3 (/tmp/RtmprZEkSz/file29f06d4b194c) 
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

## specL (1.6.2)
Maintainer: Christian Panse <cp@fgcz.ethz.ch>, Witold E. Wolski <wewolski@gmail.com>  
Bug reports: https://github.com/fgcz/specL/issues

0 errors | 1 warning  | 4 notes

```
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

## TFBSTools (1.10.3)
Maintainer: Ge Tan <ge.tan09@imperial.ac.uk>  
Bug reports: https://github.com/ge11232002/TFBSTools/issues

0 errors | 1 warning  | 1 note 

```
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
```

## tigre (1.26.0)
Maintainer: Antti Honkela <antti.honkela@hiit.fi>  
Bug reports: https://github.com/ahonkela/tigre/issues

0 errors | 1 warning  | 2 notes

```
checking whether package ‘tigre’ can be installed ... WARNING
Found the following significant warnings:
  Warning: namespace ‘Rcpp’ is not available and has been replaced
See ‘/home/muelleki/git/R/RSQLite/revdep/checks/tigre.Rcheck/00install.out’ for details.

checking top-level files ... NOTE
Non-standard file/directory found at top level:
  ‘demos’

checking R code for possible problems ... NOTE
GPPlot: no visible global function definition for ‘polygon’
export.scores: no visible global function definition for ‘png’
export.scores: no visible global function definition for ‘dev.off’
gpdisimLogLikeGradients: no visible global function definition for
  ‘tail’
Undefined global functions or variables:
  dev.off png polygon tail
Consider adding
  importFrom("grDevices", "dev.off", "png")
  importFrom("graphics", "polygon")
  importFrom("utils", "tail")
to your NAMESPACE file.
```

## UniProt.ws (2.12.0)
Maintainer: Bioconductor Package Maintainer <maintainer@bioconductor.org>

0 errors | 1 warning  | 1 note 

```
checking whether package ‘UniProt.ws’ can be installed ... WARNING
Found the following significant warnings:
  Warning: namespace ‘Rcpp’ is not available and has been replaced
See ‘/home/muelleki/git/R/RSQLite/revdep/checks/UniProt.ws.Rcheck/00install.out’ for details.

checking R code for possible problems ... NOTE
.getSomeUniprotGoodies: no visible global function definition for
  ‘head’
.tryReadResult: no visible global function definition for ‘read.delim’
.tryReadResult: no visible global function definition for ‘URLencode’
availableUniprotSpecies: no visible global function definition for
  ‘read.delim’
availableUniprotSpecies: no visible global function definition for
  ‘head’
lookupUniprotSpeciesFromTaxId: no visible global function definition
  for ‘read.delim’
Undefined global functions or variables:
  URLencode head read.delim
Consider adding
  importFrom("utils", "URLencode", "head", "read.delim")
to your NAMESPACE file.
```

## VariantFiltering (1.8.6)
Maintainer: Robert Castelo <robert.castelo@upf.edu>  
Bug reports: https://github.com/rcastelo/VariantFiltering/issues

0 errors | 3 warnings | 3 notes

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

Attaching package: ‘VariantAnnotation’

The following object is masked from ‘package:base’:

    tabulate

... 8 lines ...
Error in sqliteSendQuery(con, statement, bind.data) : 
  error in statement: database disk image is malformed
Error : .onLoad failed in loadNamespace() for 'MafDb.1Kgenomes.phase3.hs37d5', details:
  call: sqliteSendQuery(con, statement, bind.data)
  error: error in statement: database disk image is malformed

Error: processing vignette 'usingVariantFiltering.Rnw' failed with diagnostics:
 chunk 3 
Error in VariantFilteringParam(vcfFilenames = CEUvcf) : 
  package MafDb.1Kgenomes.phase3.hs37d5 could not be loaded.
Execution halted

checking installed package size ... NOTE
  installed size is  7.7Mb
  sub-directories of 1Mb or more:
    R         3.4Mb
    extdata   3.5Mb

checking dependencies in R code ... NOTE
Unexported objects imported by ':::' calls:
  'S4Vectors:::labeledLine' 'VariantAnnotation:::.checkArgs'
  'VariantAnnotation:::.consolidateHits'
  'VariantAnnotation:::.returnEmpty'
  See the note in ?`:::` about the use of this operator.

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

