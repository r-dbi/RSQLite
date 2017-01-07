# Setup

## Platform

|setting  |value                        |
|:--------|:----------------------------|
|version  |R version 3.3.2 (2016-10-31) |
|system   |x86_64, linux-gnu            |
|ui       |X11                          |
|language |(EN)                         |
|collate  |en_US.UTF-8                  |
|tz       |Zulu                         |
|date     |2017-01-07                   |

## Packages

|package   |*  |version    |date       |source                             |
|:---------|:--|:----------|:----------|:----------------------------------|
|BH        |   |1.62.0-1   |2016-11-19 |cran (@1.62.0-)                    |
|DBI       |   |0.5-14     |2016-12-24 |Github (rstats-db/DBI@8afe845)     |
|DBItest   |   |1.4        |2016-12-24 |Github (rstats-db/DBItest@0549703) |
|knitr     |   |1.15.1     |2016-11-22 |cran (@1.15.1)                     |
|memoise   |   |1.0.0      |2016-01-29 |CRAN (R 3.3.1)                     |
|plogr     |   |0.1-1      |2016-09-24 |cran (@0.1-1)                      |
|Rcpp      |   |0.12.8     |2016-11-17 |cran (@0.12.8)                     |
|rmarkdown |   |1.3        |2016-12-21 |cran (@1.3)                        |
|RSQLite   |   |1.1-1      |2016-12-10 |cran (@1.1-1)                      |
|testthat  |   |1.0.2.9000 |2016-12-24 |Github (hadley/testthat@3b2f225)   |

# Check results

29 packages with problems

|package            |version  | errors| warnings| notes|
|:------------------|:--------|------:|--------:|-----:|
|AnnotationDbi      |1.36.0   |      0|        1|     5|
|ChemmineR          |2.26.1   |      1|        0|     0|
|clstutils          |1.22.0   |      0|        2|     5|
|CNEr               |1.10.1   |      0|        2|     2|
|filematrix         |1.1.0    |      0|        1|     0|
|GeneAnswers        |2.16.0   |      1|        3|     6|
|lumi               |2.26.3   |      0|        1|     3|
|maGUI              |1.0      |      1|        0|     0|
|metagenomeFeatures |1.4.0    |      0|        2|     2|
|metaseqR           |1.14.0   |      1|        1|     4|
|mgsa               |1.22.0   |      0|        1|     4|
|oce                |0.9-20   |      1|        0|     1|
|oligoClasses       |1.36.0   |      0|        1|     4|
|oligo              |1.38.0   |      1|        0|     9|
|PAnnBuilder        |1.38.0   |      0|        3|     1|
|plethy             |1.12.1   |      2|        0|     3|
|poplite            |0.99.16  |      1|        0|     1|
|rangeMapper        |0.3-0    |      1|        0|     0|
|recoup             |1.2.0    |      2|        0|     1|
|RImmPort           |1.2.0    |      0|        1|     1|
|RQDA               |0.2-8    |      1|        0|     1|
|specL              |1.8.0    |      0|        1|     3|
|sqldf              |0.4-10   |      0|        1|     2|
|TFBSTools          |1.12.1   |      0|        1|     2|
|trackeR            |0.0.4    |      0|        1|     0|
|TSdata             |2016.8-1 |      0|        1|     0|
|tweet2r            |1.0      |      1|        0|     0|
|VariantFiltering   |1.10.1   |      0|        1|     4|
|vmsbase            |2.1.3    |      1|        0|     0|

## AnnotationDbi (1.36.0)
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

## ChemmineR (2.26.1)
Maintainer: Thomas Girke <thomas.girke@ucr.edu>

1 error  | 0 warnings | 0 notes

```
checking whether package ‘ChemmineR’ can be installed ... ERROR
Installation failed.
See ‘/home/muelleki/git/R/RSQLite/revdep/checks/ChemmineR.Rcheck/00install.out’ for details.
```

## clstutils (1.22.0)
Maintainer: Noah Hoffman <ngh2@uw.edu>

0 errors | 2 warnings | 5 notes

```
checking for GNU extensions in Makefiles ... WARNING
Found the following file(s) containing GNU extensions:
  tests/unit/Makefile
Portable Makefiles do not use GNU extensions such as +=, :=, $(shell),
$(wildcard), ifeq ... endif. See section ‘Writing portable packages’ in
the ‘Writing R Extensions’ manual.

checking re-building of vignette outputs ... WARNING
Error in re-building vignettes:
  ...
Loading required package: clst
Loading required package: rjson
Loading required package: ape
Error in texi2dvi(file = file, pdf = TRUE, clean = clean, quiet = quiet,  : 
  Running 'texi2dvi' on 'pplacerDemo.tex' failed.
LaTeX errors:
! Package auto-pst-pdf Error: 
    "shell escape" (or "write18") is not enabled:
    auto-pst-pdf will not work!
.
Calls: buildVignettes -> texi2pdf -> texi2dvi
Execution halted


checking DESCRIPTION meta-information ... NOTE
Malformed Title field: should not end in a period.

checking top-level files ... NOTE
Non-standard file/directory found at top level:
  ‘devmakefile’

checking dependencies in R code ... NOTE
'library' or 'require' call to ‘rjson’ which was already attached by Depends.
  Please remove these calls from your code.
'library' or 'require' call to ‘RSVGTipsDevice’ in package code.
  Please use :: or requireNamespace() instead.
  See section 'Suggested packages' in the 'Writing R Extensions' manual.
Packages in Depends field not imported from:
  ‘ape’ ‘rjson’
  These packages need to be imported from (in the NAMESPACE file)
  for when this namespace is loaded but not attached.

checking foreign function calls ... NOTE
Foreign function call to a different package:
  .Call("seq_root2tip", ..., PACKAGE = "ape")
See chapter ‘System and foreign language interfaces’ in the ‘Writing R
Extensions’ manual.

checking R code for possible problems ... NOTE
edgeMap: no visible global function definition for ‘fromJSON’
findOutliers: no visible global function definition for ‘quantile’
findOutliers: no visible binding for global variable ‘median’
maxDists: no visible binding for global variable ‘median’
placeData: no visible global function definition for ‘read.table’
prettyTree: no visible binding for global variable ‘par’
prettyTree: no visible global function definition for ‘plot’
prettyTree: no visible binding for global variable ‘.PlotPhyloEnv’
prettyTree: no visible binding for global variable ‘points’
... 19 lines ...
taxonomyFromRefpkg: no visible global function definition for
  ‘read.csv’
Undefined global functions or variables:
  .PlotPhyloEnv dev.off devSVGTips fromJSON legend median par plot
  points quantile read.csv read.table setSVGShapeToolTip text
Consider adding
  importFrom("grDevices", "dev.off")
  importFrom("graphics", "legend", "par", "plot", "points", "text")
  importFrom("stats", "median", "quantile")
  importFrom("utils", "read.csv", "read.table")
to your NAMESPACE file.
```

## CNEr (1.10.1)
Maintainer: Ge Tan <ge.tan09@imperial.ac.uk>  
Bug reports: https://github.com/ge11232002/CNEr/issues

0 errors | 2 warnings | 2 notes

```
checking compiled code ... WARNING
File ‘CNEr/libs/CNEr.so’:
  Found ‘abort’, possibly from ‘abort’ (C)
    Object: ‘ucsc/errabort.o’
  Found ‘exit’, possibly from ‘exit’ (C)
    Objects: ‘ucsc/errabort.o’, ‘ucsc/pipeline.o’
  Found ‘puts’, possibly from ‘printf’ (C), ‘puts’ (C)
    Object: ‘ucsc/pipeline.o’
  Found ‘rand’, possibly from ‘rand’ (C)
    Object: ‘ucsc/obscure.o’
  Found ‘stderr’, possibly from ‘stderr’ (C)
    Objects: ‘ucsc/axt.o’, ‘ucsc/errabort.o’, ‘ucsc/obscure.o’,
      ‘ucsc/verbose.o’, ‘ucsc/os.o’
  Found ‘stdout’, possibly from ‘stdout’ (C)
    Objects: ‘ucsc/common.o’, ‘ucsc/errabort.o’, ‘ucsc/verbose.o’,
      ‘ucsc/os.o’

Compiled code should not call entry points which might terminate R nor
write to stdout/stderr instead of to the console, nor the system RNG.

See ‘Writing portable packages’ in the ‘Writing R Extensions’ manual.

checking re-building of vignette outputs ... WARNING
Error in re-building vignettes:
  ...
Warning in engine$weave(file, quiet = quiet, encoding = enc) :
  Pandoc (>= 1.12.3) and/or pandoc-citeproc not available. Falling back to R Markdown v1.
Quitting from lines 2-15 (CNEr.Rmd) 
Error: processing vignette 'CNEr.Rmd' failed with diagnostics:
could not find function "doc_date"
Execution halted


checking installed package size ... NOTE
  installed size is 28.9Mb
  sub-directories of 1Mb or more:
    R        11.0Mb
    extdata  15.9Mb
    libs      1.1Mb

checking dependencies in R code ... NOTE
Unexported objects imported by ':::' calls:
  ‘BiocGenerics:::replaceSlots’ ‘S4Vectors:::make_zero_col_DataFrame’
  See the note in ?`:::` about the use of this operator.
```

## filematrix (1.1.0)
Maintainer: Andrey A Shabalin <ashabalin@vcu.edu>  
Bug reports: https://github.com/andreyshabalin/filematrix/issues

0 errors | 1 warning  | 0 notes

```
checking re-building of vignette outputs ... WARNING
Error in re-building vignettes:
  ...
Warning in engine$weave(file, quiet = quiet, encoding = enc) :
  Pandoc (>= 1.12.3) and/or pandoc-citeproc not available. Falling back to R Markdown v1.
Quitting from lines 2-23 (Best_Prectices.Rmd) 
Error: processing vignette 'Best_Prectices.Rmd' failed with diagnostics:
could not find function "doc_date"
Execution halted

```

## GeneAnswers (2.16.0)
Maintainer: Lei Huang <lhuang7@uchicago.edu> and Gang Feng <gilbertfeng@gmail.com>

1 error  | 3 warnings | 6 notes

```
checking examples ... ERROR
Running examples in ‘GeneAnswers-Ex.R’ failed
The error most likely occurred in:

> base::assign(".ptime", proc.time(), pos = "CheckExEnv")
> ### Name: chartPlots
> ### Title: Pie Chart and Bar Plots
> ### Aliases: chartPlots
> ### Keywords: methods
> 
> ### ** Examples
> 
> x <- matrix(c(6,9,3,30,13,2,15,20), nrow = 4, ncol=2, byrow=FALSE,
+                dimnames = list(c("group1", "group2", "group3", "group4"),
+                                c("value1", "value2")))
> chartPlots(x, chartType='all', specifiedCol = "value2", top = 3)
Error in x11() : screen devices should not be used in examples etc
Calls: chartPlots -> x11
Execution halted

checking whether package ‘GeneAnswers’ can be installed ... WARNING
Found the following significant warnings:
  Warning: replacing previous import ‘stats::decompose’ by ‘igraph::decompose’ when loading ‘GeneAnswers’
  Warning: replacing previous import ‘stats::spectrum’ by ‘igraph::spectrum’ when loading ‘GeneAnswers’
See ‘/home/muelleki/git/R/RSQLite/revdep/checks/GeneAnswers.Rcheck/00install.out’ for details.

checking sizes of PDF files under ‘inst/doc’ ... WARNING
  ‘gs+qpdf’ made some significant size reductions:
     compacted ‘geneAnswers.pdf’ from 1373Kb to 600Kb
  consider running tools::compactPDF(gs_quality = "ebook") on these files

checking re-building of vignette outputs ... WARNING
Error in re-building vignettes:
  ...
Warning: replacing previous import ‘stats::spectrum’ by ‘igraph::spectrum’ when loading ‘GeneAnswers’
Loading required package: org.Hs.eg.db

Loading required package: GO.db

Loading required package: KEGG.db

... 8 lines ...
Loading required package: org.Mm.eg.db

Error in texi2dvi(file = file, pdf = TRUE, clean = clean, quiet = quiet,  : 
  Running 'texi2dvi' on 'geneAnswers.tex' failed.
LaTeX errors:
! Package auto-pst-pdf Error: 
    "shell escape" (or "write18") is not enabled:
    auto-pst-pdf will not work!
.
Calls: buildVignettes -> texi2pdf -> texi2dvi
Execution halted

checking package dependencies ... NOTE
Depends: includes the non-default packages:
  ‘igraph’ ‘RCurl’ ‘annotate’ ‘Biobase’ ‘XML’ ‘RSQLite’ ‘MASS’
  ‘Heatplus’ ‘RColorBrewer’
Adding so many packages to the search path is excessive and importing
selectively is preferable.

checking installed package size ... NOTE
  installed size is 36.1Mb
  sub-directories of 1Mb or more:
    External  32.4Mb
    data       1.1Mb
    doc        1.6Mb

checking DESCRIPTION meta-information ... NOTE
Package listed in more than one of Depends, Imports, Suggests, Enhances:
  ‘annotate’
A package should be listed in only one of these fields.

checking dependencies in R code ... NOTE
'library' or 'require' calls to packages already attached by Depends:
  ‘Biobase’ ‘Heatplus’ ‘MASS’ ‘RColorBrewer’ ‘XML’ ‘igraph’
  Please remove these calls from your code.
'library' or 'require' calls in package code:
  ‘GO.db’ ‘KEGG.db’ ‘biomaRt’ ‘reactome.db’
  Please use :: or requireNamespace() instead.
  See section 'Suggested packages' in the 'Writing R Extensions' manual.

checking R code for possible problems ... NOTE
Found an obsolete/platform-specific call in the following functions:
  ‘chartPlots’ ‘drawTable’
Found the platform-specific device:
  ‘x11’
dev.new() is the preferred way to open a new device, in the unlikely
event one is needed.
File ‘GeneAnswers/R/zzz.R’:
  .onLoad calls:
    require(Biobase)
... 78 lines ...
  data("DmIALite", package = "GeneAnswers")
File ‘GeneAnswers/R/getDOLiteTerms.R’:
  data("DOLiteTerm", package = "GeneAnswers")
File ‘GeneAnswers/R/zzz.R’:
  data("DOLite", package = "GeneAnswers")
  data("DOLiteTerm", package = "GeneAnswers")
  data("HsIALite", package = "GeneAnswers")
  data("MmIALite", package = "GeneAnswers")
  data("RnIALite", package = "GeneAnswers")
  data("DmIALite", package = "GeneAnswers")
See section ‘Good practice’ in ‘?data’.

checking Rd line widths ... NOTE
Rd file 'GeneAnswers-class.Rd':
  \examples lines wider than 100 characters:
     x <- geneAnswersBuilder(humanGeneInput, 'org.Hs.eg.db', categoryType='GO.BP', testType='hyperG', pvalueT=0.01, FDR.correct=TRUE, geneEx ... [TRUNCATED]

Rd file 'GeneAnswers-package.Rd':
  \examples lines wider than 100 characters:
     x <- geneAnswersBuilder(humanGeneInput, 'org.Hs.eg.db', categoryType='GO.BP', testType='hyperG', pvalueT=0.01, FDR.correct=TRUE, geneEx ... [TRUNCATED]

Rd file 'buildNet.Rd':
... 144 lines ...
     ## Not run: topDOLITEGenes(x, geneSymbol=TRUE, orderby='pvalue', top=10, topGenes='ALL', genesOrderBy='pValue', file=TRUE)

Rd file 'topPATHGenes.Rd':
  \examples lines wider than 100 characters:
     ## Not run: topPATHGenes(x, geneSymbol=TRUE, orderby='genenum', top=6, topGenes=8, genesOrderBy='foldChange')

Rd file 'topREACTOME.PATHGenes.Rd':
  \examples lines wider than 100 characters:
     ## Not run: topREACTOME.PATHGenes(x, geneSymbol=TRUE, orderby='pvalue', top=10, topGenes='ALL', genesOrderBy='pValue', file=TRUE)

These lines will be truncated in the PDF manual.
```

## lumi (2.26.3)
Maintainer: Pan Du <dupan.mail@gmail.com>

0 errors | 1 warning  | 3 notes

```
checking dependencies in R code ... WARNING
'::' or ':::' import not declared from: ‘bigmemoryExtras’

checking installed package size ... NOTE
  installed size is  6.8Mb
  sub-directories of 1Mb or more:
    R      2.8Mb
    data   3.6Mb

checking Rd line widths ... NOTE
Rd file 'IlluminaID2nuID.Rd':
  \usage lines wider than 90 characters:
     IlluminaID2nuID(IlluminaID, lib.mapping=NULL, species = c("Human", "Mouse", "Rat", "Unknown"), chipVersion = NULL, ...)

Rd file 'addAnnotationInfo.Rd':
  \usage lines wider than 90 characters:
     addAnnotationInfo(methyLumiM, lib = 'FDb.InfiniumMethylation.hg19', annotationColumn=c('COLOR_CHANNEL', 'CHROMOSOME', 'POSITION'))

Rd file 'addNuID2lumi.Rd':
... 177 lines ...
     smoothQuantileNormalization(dataMatrix, ref = NULL, adjData=NULL, logMode = TRUE, bandwidth = NULL, degree = 1, verbose = FALSE, ...)

Rd file 'ssn.Rd':
  \usage lines wider than 90 characters:
     ssn(x.lumi, targetArray = NULL, scaling = TRUE, bgMethod=c('density', 'mean', 'median', 'none'), fgMethod=c('mean', 'density', 'median' ... [TRUNCATED]

Rd file 'vst.Rd':
  \usage lines wider than 90 characters:
     vst(u, std, nSupport = min(length(u), 500), backgroundStd=NULL, fitMethod = c('linear', 'quadratic'), lowCutoff = 1/3, ifPlot = FALSE)

These lines will be truncated in the PDF manual.

checking Rd cross-references ... NOTE
Package unavailable to check Rd xrefs: ‘bigmemoryExtras’
```

## maGUI (1.0)
Maintainer: Dhammapal Bharne <dhammapalb@uohyd.ac.in>

1 error  | 0 warnings | 0 notes

```
checking whether package ‘maGUI’ can be installed ... ERROR
Installation failed.
See ‘/home/muelleki/git/R/RSQLite/revdep/checks/maGUI.Rcheck/00install.out’ for details.
```

## metagenomeFeatures (1.4.0)
Maintainer: Nathan D. Olson <nolson@umiacs.umd.edu>  
Bug reports: https://github.com/HCBravoLab/metagenomeFeatures/issues

0 errors | 2 warnings | 2 notes

```
checking for missing documentation entries ... WARNING
Undocumented S4 methods:
  generic 'taxa_columns' and siglist 'MgDb'
  generic 'taxa_keys' and siglist 'MgDb'
  generic 'taxa_keytypes' and siglist 'MgDb'
All user-level objects in a package (including S4 classes and methods)
should have documentation entries.
See chapter ‘Writing R documentation files’ in the ‘Writing R
Extensions’ manual.

checking Rd \usage sections ... WARNING
Undocumented arguments in documentation object 'annotateFeatures'
  ‘query_key’
Documented arguments not in \usage in documentation object 'annotateFeatures':
  ‘db_keys’ ‘query_df’

Functions with \usage entries need to have the appropriate \alias
entries, and all their arguments documented.
The \usage entries must correspond to syntactically valid R code.
See chapter ‘Writing R documentation files’ in the ‘Writing R
Extensions’ manual.

checking installed package size ... NOTE
  installed size is  6.3Mb
  sub-directories of 1Mb or more:
    R         1.1Mb
    extdata   3.4Mb

checking R code for possible problems ... NOTE
.mgDb_annotateFeatures: no visible binding for global variable
  ‘db_keys’
.select.taxa: no visible binding for global variable ‘Keys’
.select.taxa: no visible binding for global variable ‘.’
aggregate_taxa: no visible binding for global variable ‘.’
aggregate_taxa: no visible binding for global variable ‘index’
aggregate_taxa: no visible global function definition for
  ‘newMRexperiment’
vignette_pheno_data: no visible global function definition for
  ‘read.csv’
Undefined global functions or variables:
  . Keys db_keys index newMRexperiment read.csv
Consider adding
  importFrom("utils", "read.csv")
to your NAMESPACE file.
```

## metaseqR (1.14.0)
Maintainer: Panagiotis Moulos <moulos@fleming.gr>

1 error  | 1 warning  | 4 notes

```
checking tests ... ERROR
Running the tests in ‘tests/runTests.R’ failed.
Last 13 lines of output:
  
  Test files with failing tests
  
     test_estimate_aufc_weights.R 
       test_estimate_aufc_weights 
  
     test_metaseqr.R 
       test_metaseqr 
  
  
  Error in BiocGenerics:::testPackage("metaseqR") : 
    unit tests failed for package metaseqR
  Execution halted

checking re-building of vignette outputs ... WARNING
Error in re-building vignettes:
  ...

The following objects are masked from 'package:ShortRead':

    left, right

Loading required package: lattice
    Welcome to 'DESeq'. For improved performance, usability and
... 8 lines ...
    plotMA

The following object is masked from 'package:BiocGenerics':

    plotMA

Loading required package: qvalue
Quitting from lines 119-159 (metaseqr-pdf.Rnw) 
Error: processing vignette 'metaseqr-pdf.Rnw' failed with diagnostics:
13 simultaneous processes spawned
Execution halted

checking package dependencies ... NOTE
Package which this enhances but not available for checking: ‘TCC’

checking DESCRIPTION meta-information ... NOTE
Malformed Title field: should not end in a period.

checking dependencies in R code ... NOTE
'library' or 'require' calls in package code:
  ‘BSgenome’ ‘BiocInstaller’ ‘GenomicRanges’ ‘RMySQL’ ‘RSQLite’
  ‘Rsamtools’ ‘TCC’ ‘VennDiagram’ ‘parallel’ ‘rtracklayer’ ‘survcomp’
  ‘zoo’
  Please use :: or requireNamespace() instead.
  See section 'Suggested packages' in the 'Writing R Extensions' manual.

checking R code for possible problems ... NOTE
biasPlotToJSON: no visible binding for global variable ‘nams’
cddat: no visible global function definition for ‘assayData’
cddat: no visible global function definition for ‘ks.test’
cddat: no visible global function definition for ‘p.adjust’
cdplot: no visible global function definition for ‘plot’
cdplot: no visible global function definition for ‘lines’
countsBioToJSON: no visible binding for global variable ‘nams’
diagplot.avg.ftd : <anonymous>: no visible binding for global variable
  ‘sd’
... 246 lines ...
             "dev.off", "jpeg", "pdf", "png", "postscript", "tiff")
  importFrom("graphics", "abline", "arrows", "axis", "grid", "lines",
             "mtext", "par", "plot", "plot.new", "plot.window", "points",
             "text", "title")
  importFrom("methods", "as", "new")
  importFrom("stats", "as.dist", "cmdscale", "cor", "end", "ks.test",
             "mad", "median", "model.matrix", "na.exclude", "optimize",
             "p.adjust", "p.adjust.methods", "pchisq", "quantile",
             "rexp", "rnbinom", "runif", "sd", "start", "var")
to your NAMESPACE file (and ensure that your DESCRIPTION Imports field
contains 'methods').
```

## mgsa (1.22.0)
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

## oce (0.9-20)
Maintainer: Dan Kelley <Dan.Kelley@Dal.Ca>  
Bug reports: https://github.com/dankelley/oce/issues

1 error  | 0 warnings | 1 note 

```
checking examples ... ERROR
Running examples in ‘oce-Ex.R’ failed
The error most likely occurred in:

> base::assign(".ptime", proc.time(), pos = "CheckExEnv")
> ### Name: read.oce
> ### Title: Read an Oceanographic Data File
> ### Aliases: read.oce
> 
> ### ** Examples
> 
> 
> library(oce)
> x <- read.oce(system.file("extdata", "ctd.cnv", package="oce"))
> plot(x) # summary with TS and profiles
Error in if (!is.null(x@metadata$startTime) && 4 < nchar(x@metadata$startTime,  : 
  missing value where TRUE/FALSE needed
Calls: plot -> plot -> .local
Execution halted

checking installed package size ... NOTE
  installed size is  5.4Mb
  sub-directories of 1Mb or more:
    help   2.1Mb
```

## oligoClasses (1.36.0)
Maintainer: Benilton Carvalho <beniltoncarvalho@gmail.com> and Robert Scharpf <rscharpf@jhsph.edu>

0 errors | 1 warning  | 4 notes

```
checking for missing documentation entries ... WARNING
Undocumented S4 methods:
  generic '[' and siglist 'CNSet,ANY,ANY,ANY'
  generic '[' and siglist 'gSetList,ANY,ANY,ANY'
All user-level objects in a package (including S4 classes and methods)
should have documentation entries.
See chapter ‘Writing R documentation files’ in the ‘Writing R
Extensions’ manual.

checking package dependencies ... NOTE
Packages which this enhances but not available for checking:
  ‘doMPI’ ‘doSNOW’ ‘doRedis’

checking dependencies in R code ... NOTE
Unexported object imported by a ':::' call: ‘Biobase:::assayDataEnvLock’
  See the note in ?`:::` about the use of this operator.

checking R code for possible problems ... NOTE
getSequenceLengths: no visible binding for global variable ‘seqlengths’
pdPkgFromBioC: no visible binding for global variable ‘contrib.url’
pdPkgFromBioC: no visible global function definition for
  ‘available.packages’
pdPkgFromBioC: no visible global function definition for
  ‘install.packages’
chromosome,gSetList: no visible global function definition for
  ‘chromosomeList’
coerce,CNSet-CopyNumberSet: no visible global function definition for
  ‘totalCopynumber’
geometry,FeatureSet: no visible global function definition for ‘getPD’
Undefined global functions or variables:
  available.packages chromosomeList contrib.url getPD install.packages
  seqlengths totalCopynumber
Consider adding
  importFrom("utils", "available.packages", "contrib.url",
             "install.packages")
to your NAMESPACE file.

checking Rd line widths ... NOTE
Rd file 'AssayDataList.Rd':
  \examples lines wider than 100 characters:
     r <- lapply(r, function(x,dns) {dimnames(x) <- dns; return(x)}, dns=list(letters[1:5], LETTERS[1:5]))

Rd file 'GenomeAnnotatedDataFrameFrom-methods.Rd':
  \examples lines wider than 100 characters:
                                 dimnames=list(c("rs10000092","rs1000055", "rs100016", "rs10003241", "rs10004197"), NULL))

Rd file 'largeObjects.Rd':
  \usage lines wider than 90 characters:
     initializeBigMatrix(name=basename(tempfile()), nr=0L, nc=0L, vmode = "integer", initdata = NA)

Rd file 'oligoSetExample.Rd':
  \examples lines wider than 100 characters:
                                     copyNumber=integerMatrix(log2(locusLevelData[["copynumber"]]/100), 100),

These lines will be truncated in the PDF manual.
```

## oligo (1.38.0)
Maintainer: Benilton Carvalho <benilton@unicamp.br>

1 error  | 0 warnings | 9 notes

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
Package which this enhances but not available for checking: ‘doMPI’

checking installed package size ... NOTE
  installed size is 30.3Mb
  sub-directories of 1Mb or more:
    R         1.2Mb
    doc      12.9Mb
    scripts  15.7Mb

checking DESCRIPTION meta-information ... NOTE
Packages listed in more than one of Depends, Imports, Suggests, Enhances:
  ‘biomaRt’ ‘AnnotationDbi’ ‘GenomeGraphs’ ‘RCurl’ ‘ff’
A package should be listed in only one of these fields.

checking top-level files ... NOTE
Non-standard file/directory found at top level:
  ‘TODO.org’

checking whether the namespace can be loaded with stated dependencies ... NOTE
Warning: no function found corresponding to methods exports from ‘oligo’ for: ‘show’

A namespace must be able to be loaded with just the base namespace
loaded: otherwise if the namespace gets loaded by a saved object, the
session will be unable to start.

Probably some imports need to be declared in the NAMESPACE file.

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

## PAnnBuilder (1.38.0)
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

## plethy (1.12.1)
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
Processing /tmp/RtmpZyhprh/filee4cd4e71a1e4 in chunks of 10000
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
  closing unused connection 3 (/tmp/RtmpoW8w2r/filee66827ceb6fb) 
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

1 error  | 0 warnings | 1 note 

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

1 error  | 0 warnings | 0 notes

```
checking whether package ‘rangeMapper’ can be installed ... ERROR
Installation failed.
See ‘/home/muelleki/git/R/RSQLite/revdep/checks/rangeMapper.Rcheck/00install.out’ for details.
```

## recoup (1.2.0)
Maintainer: Panagiotis Moulos <moulos@fleming.gr>

2 errors | 0 warnings | 1 note 

```
checking examples ... ERROR
Running examples in ‘recoup-Ex.R’ failed
The error most likely occurred in:

> base::assign(".ptime", proc.time(), pos = "CheckExEnv")
> ### Name: calcCoverage
> ### Title: Calculate coverages over a genomic region
> ### Aliases: calcCoverage
> 
> ### ** Examples
> 
> # Load some data
> data("recoup_test_data",package="recoup")
> 
> # Calculate coverage Rle
> mask <- makeGRangesFromDataFrame(df=test.genome,
+     keep.extra.columns=TRUE)
> small.cov <- calcCoverage(test.input[[1]]$ranges,mask)
Error in .check_ncores(cores) : 16 simultaneous processes spawned
Calls: calcCoverage ... splitBySeqname -> cmclapply -> mclapply -> .check_ncores
Execution halted
** found \donttest examples: check also with --run-donttest

checking tests ... ERROR
Running the tests in ‘tests/runTests.R’ failed.
Last 13 lines of output:
  1 Test Suite : 
  recoup RUnit Tests - 1 test function, 1 error, 0 failures
  ERROR in test_recoup: Error in .check_ncores(cores) : 16 simultaneous processes spawned
  
  Test files with failing tests
  
     test_recoup.R 
       test_recoup 
  
  
  Error in BiocGenerics:::testPackage("recoup") : 
    unit tests failed for package recoup
  Execution halted

checking R code for possible problems ... NOTE
areColors : <anonymous>: no visible global function definition for
  ‘col2rgb’
buildAnnotationStore: no visible global function definition for
  ‘Seqinfo’
calcCoverage: no visible global function definition for ‘is’
calcDesignPlotProfiles : <anonymous>: no visible global function
  definition for ‘smooth.spline’
calcPlotProfiles : <anonymous>: no visible global function definition
  for ‘smooth.spline’
... 94 lines ...
Consider adding
  importFrom("grDevices", "bmp", "col2rgb", "dev.new", "dev.off", "jpeg",
             "pdf", "png", "postscript", "tiff")
  importFrom("graphics", "plot")
  importFrom("methods", "as", "is")
  importFrom("stats", "approx", "kmeans", "lowess", "quantile",
             "smooth.spline", "spline", "var")
  importFrom("utils", "download.file", "packageVersion", "read.delim",
             "unzip")
to your NAMESPACE file (and ensure that your DESCRIPTION Imports field
contains 'methods').
```

## RImmPort (1.2.0)
Maintainer: Ravi Shankar <rshankar@stanford.edu>

0 errors | 1 warning  | 1 note 

```
checking sizes of PDF files under ‘inst/doc’ ... WARNING
  ‘gs+qpdf’ made some significant size reductions:
     compacted ‘RImmPort_Article.pdf’ from 731Kb to 336Kb
  consider running tools::compactPDF(gs_quality = "ebook") on these files

checking R code for possible problems ... NOTE
getCellularQuantification: no visible binding for global variable
  ‘experiment_sample_accession’
getCellularQuantification: no visible binding for global variable
  ‘control_files_names’
getCellularQuantification: no visible binding for global variable
  ‘ZBREFIDP’
getGeneticsFindings: no visible binding for global variable
  ‘experiment_sample_accession’
getNucleicAcidQuantification: no visible binding for global variable
  ‘experiment_sample_accession’
getProteinQuantification: no visible binding for global variable
  ‘experiment_sample_accession’
getTiterAssayResults: no visible binding for global variable
  ‘experiment_sample_accession’
Undefined global functions or variables:
  ZBREFIDP control_files_names experiment_sample_accession
```

## RQDA (0.2-8)
Maintainer: HUANG Ronggui <ronggui.huang@gmail.com>

1 error  | 0 warnings | 1 note 

```
checking whether package ‘RQDA’ can be installed ... ERROR
Installation failed.
See ‘/home/muelleki/git/R/RSQLite/revdep/checks/RQDA.Rcheck/00install.out’ for details.

checking package dependencies ... NOTE
Packages which this enhances but not available for checking:
  ‘rjpod’ ‘d3Network’
```

## specL (1.8.0)
Maintainer: Christian Panse <cp@fgcz.ethz.ch>, Witold E. Wolski <wewolski@gmail.com>  
Bug reports: https://github.com/fgcz/specL/issues

0 errors | 1 warning  | 3 notes

```
checking re-building of vignette outputs ... WARNING
Error in re-building vignettes:
  ...
Warning in engine$weave(file, quiet = quiet, encoding = enc) :
  Pandoc (>= 1.12.3) and/or pandoc-citeproc not available. Falling back to R Markdown v1.
Quitting from lines 2-25 (cdsw.Rmd) 
Error: processing vignette 'cdsw.Rmd' failed with diagnostics:
could not find function "doc_date"
Execution halted


checking S3 generic/method consistency ... NOTE
Found the following apparent S3 methods exported but not registered:
  merge.specLSet plot.psm plot.psmSet summary.psmSet
See section ‘Registering S3 methods’ in the ‘Writing R Extensions’
manual.

checking R code for possible problems ... NOTE
.onAttach: no visible global function definition for ‘packageVersion’
plot,specLSet: no visible global function definition for ‘draw.circle’
summary,specLSet : <anonymous>: no visible binding for global variable
  ‘iRTpeptides’
Undefined global functions or variables:
  draw.circle iRTpeptides packageVersion
Consider adding
  importFrom("utils", "packageVersion")
to your NAMESPACE file.

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

## TFBSTools (1.12.1)
Maintainer: Ge Tan <ge.tan09@imperial.ac.uk>  
Bug reports: https://github.com/ge11232002/TFBSTools/issues

0 errors | 1 warning  | 2 notes

```
checking re-building of vignette outputs ... WARNING
Error in re-building vignettes:
  ...
Warning in engine$weave(file, quiet = quiet, encoding = enc) :
  Pandoc (>= 1.12.3) and/or pandoc-citeproc not available. Falling back to R Markdown v1.
Quitting from lines 2-16 (TFBSTools.Rmd) 
Error: processing vignette 'TFBSTools.Rmd' failed with diagnostics:
could not find function "doc_date"
Execution halted


checking installed package size ... NOTE
  installed size is 12.1Mb
  sub-directories of 1Mb or more:
    R  11.3Mb

checking dependencies in R code ... NOTE
Unexported objects imported by ':::' calls:
  ‘S4Vectors:::new_SimpleList_from_list’ ‘seqLogo:::pwm2ic’
  See the note in ?`:::` about the use of this operator.
```

## trackeR (0.0.4)
Maintainer: Hannah Frick <h.frick@ucl.ac.uk>  
Bug reports: https://github.com/hfrick/trackeR/issues

0 errors | 1 warning  | 0 notes

```
checking re-building of vignette outputs ... WARNING
Error in re-building vignettes:
  ...
Warning in engine$weave(file, quiet = quiet, encoding = enc) :
  Pandoc (>= 1.12.3) and/or pandoc-citeproc not available. Falling back to R Markdown v1.
Loading required package: zoo

Attaching package: 'zoo'

The following objects are masked from 'package:base':
... 6 lines ...
Attaching package: 'trackeR'

The following object is masked from 'package:base':

    append

Map from URL : http://maps.googleapis.com/maps/api/staticmap?center=57.157231,-2.104296&zoom=13&size=640x640&scale=2&maptype=terrain&sensor=false
Quitting from lines 90-91 (TourDetrackeR.Rmd) 
Error: processing vignette 'TourDetrackeR.Rmd' failed with diagnostics:
map grabbing failed - see details in ?get_openstreetmap.
Execution halted
```

## TSdata (2016.8-1)
Maintainer: Paul Gilbert <pgilbert.ttv9z@ncf.ca>

0 errors | 1 warning  | 0 notes

```
checking re-building of vignette outputs ... WARNING
Error in re-building vignettes:
  ...
Jan 07, 2017 6:34:40 PM it.bancaditalia.oss.sdmx.util.Configuration init
INFO: Configuration file: /home/muelleki/R/x86_64-pc-linux-gnu-library/3.3/RJSDMX/configuration.properties
Jan 07, 2017 6:34:40 PM it.bancaditalia.oss.sdmx.client.RestSdmxClient runQuery
INFO: Contacting web service with query: http://stats.oecd.org/restsdmx/sdmx.ashx//GetDataStructure/QNA
Jan 07, 2017 6:34:41 PM it.bancaditalia.oss.sdmx.client.RestSdmxClient runQuery
INFO: Contacting web service with query: http://stats.oecd.org/restsdmx/sdmx.ashx//GetDataStructure/QNA
Jan 07, 2017 6:34:42 PM it.bancaditalia.oss.sdmx.client.RestSdmxClient runQuery
... 8 lines ...
Jan 07, 2017 6:34:43 PM it.bancaditalia.oss.sdmx.client.RestSdmxClient runQuery
INFO: Contacting web service with query: http://ec.europa.eu/eurostat/SDMX/diss-web/rest/data/ESTAT,ei_nama_q,1.0/Q.MIO-EUR.NSA.CP.NA-P72.IT
Jan 07, 2017 6:34:43 PM it.bancaditalia.oss.sdmx.client.RestSdmxClient getData
INFO: The sdmx call returned messages in the footer:
 Message [code=400, severity=Error, url=null, text=[Error caused by the caller due to incorrect or semantically invalid arguments]]

Error: processing vignette 'Guide.Stex' failed with diagnostics:
 chunk 5 
Error in .local(serIDs, con, ...) : 
  ei_nama_q.Q.MIO-EUR.NSA.CP.NA-P72.IT error: it.bancaditalia.oss.sdmx.util.SdmxException: The query: ei_nama_q.Q.MIO-EUR.NSA.CP.NA-P72.IT did not match any time series on the provider.
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

## VariantFiltering (1.10.1)
Maintainer: Robert Castelo <robert.castelo@upf.edu>  
Bug reports: https://github.com/rcastelo/VariantFiltering/issues

0 errors | 1 warning  | 4 notes

```
checking sizes of PDF files under ‘inst/doc’ ... WARNING
  ‘gs+qpdf’ made some significant size reductions:
     compacted ‘usingVariantFiltering.pdf’ from 415Kb to 153Kb
  consider running tools::compactPDF(gs_quality = "ebook") on these files

checking installed package size ... NOTE
  installed size is  7.9Mb
  sub-directories of 1Mb or more:
    R         3.6Mb
    extdata   3.5Mb

checking dependencies in R code ... NOTE
Unexported objects imported by ':::' calls:
  'S4Vectors:::labeledLine' 'VariantAnnotation:::.checkArgs'
  'VariantAnnotation:::.consolidateHits'
  'VariantAnnotation:::.returnEmpty'
  See the note in ?`:::` about the use of this operator.
There are ::: calls to the package's namespace in its code. A package
  almost never needs to use ::: for its own objects:
  '.adjustForStrandSense'

checking Rd line widths ... NOTE
Rd file 'MafDb-class.Rd':
  \examples lines wider than 100 characters:
       ## founder mutation in a regulatory element located within the HERC2 gene inhibiting OCA2 expression.

Rd file 'MafDb2-class.Rd':
  \examples lines wider than 100 characters:
       ## founder mutation in a regulatory element located within the HERC2 gene inhibiting OCA2 expression.

Rd file 'VariantFilteringParam-class.Rd':
... 19 lines ...

Rd file 'autosomalRecessiveHeterozygous.Rd':
  \usage lines wider than 90 characters:
                                                                      BPPARAM=bpparam("SerialParam"))

Rd file 'autosomalRecessiveHomozygous.Rd':
  \usage lines wider than 90 characters:
                                                                    use=c("everything", "complete.obs", "all.obs"),
                                                                    BPPARAM=bpparam("SerialParam"))

These lines will be truncated in the PDF manual.

checking Rd cross-references ... NOTE
Package unavailable to check Rd xrefs: ‘phastCons100way.UCSC.hg38’
```

## vmsbase (2.1.3)
Maintainer: Lorenzo D'Andrea <support@vmsbase.org>

1 error  | 0 warnings | 0 notes

```
checking whether package ‘vmsbase’ can be installed ... ERROR
Installation failed.
See ‘/home/muelleki/git/R/RSQLite/revdep/checks/vmsbase.Rcheck/00install.out’ for details.
```

