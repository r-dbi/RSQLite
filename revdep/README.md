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
|date     |2016-09-07                   |

## Packages

|package  |*  |version    |date       |source                           |
|:--------|:--|:----------|:----------|:--------------------------------|
|DBI      |   |0.5        |2016-09-01 |Github (rstats-db/DBI@bc730b9)   |
|RSQLite  |   |1.0.0      |2016-09-07 |local (rstats-db/RSQLite@NA)     |
|testthat |   |1.0.2.9000 |2016-08-25 |Github (hadley/testthat@46d15da) |

# Check results

10 packages

|package       |version | errors| warnings| notes|
|:-------------|:-------|------:|--------:|-----:|
|AnnotationHub |2.4.2   |      0|        0|     0|
|cummeRbund    |2.14.0  |      0|        0|     7|
|DECIPHER      |2.0.2   |      0|        2|     2|
|GWASTools     |1.18.0  |      0|        0|     2|
|mgsa          |1.20.0  |      0|        1|     4|
|poplite       |0.99.16 |      0|        0|     1|
|rangeMapper   |0.3-0   |      0|        0|     0|
|RObsDat       |16.03   |      0|        0|     0|
|specL         |1.6.2   |      0|        1|     4|
|tcpl          |1.2.2   |      0|        0|     1|

Slowest checks

|   |package       | check_time|
|:--|:-------------|----------:|
|2  |cummeRbund    |      498.6|
|4  |GWASTools     |      248.9|
|3  |DECIPHER      |      244.5|
|1  |AnnotationHub |        193|
|7  |rangeMapper   |      140.1|
|10 |tcpl          |         64|

## AnnotationHub (2.4.2)
Maintainer: Bioconductor Package Maintainer <maintainer@bioconductor.org>

0 errors | 0 warnings | 0 notes

## cummeRbund (2.14.0)
Maintainer: Loyal A. Goff <lgoff@csail.mit.edu>

0 errors | 0 warnings | 7 notes

```
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

## GWASTools (1.18.0)
Maintainer: Stephanie M. Gogarten <sdmorris@u.washington.edu>, Adrienne Stilp <amstilp@u.washington.edu>

0 errors | 0 warnings | 2 notes

```
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

## rangeMapper (0.3-0)
Maintainer: Mihai Valcu <valcu@orn.mpg.de>

0 errors | 0 warnings | 0 notes

## RObsDat (16.03)
Maintainer: Dominik Reusser <reusser@pik-potsdam.de>

0 errors | 0 warnings | 0 notes

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

## tcpl (1.2.2)
Maintainer: Dayne L Filer <dayne.filer@gmail.com>

0 errors | 0 warnings | 1 note 

```
checking installed package size ... NOTE
  installed size is  9.9Mb
  sub-directories of 1Mb or more:
    sql   8.7Mb
```

