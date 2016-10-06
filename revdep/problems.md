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
|date     |2016-10-06                   |

## Packages

|package  |*  |version    |date       |source                           |
|:--------|:--|:----------|:----------|:--------------------------------|
|DBI      |   |0.5-12     |2016-10-06 |Github (rstats-db/DBI@4f00863)   |
|RSQLite  |   |1.0.0      |2016-10-06 |local (rstats-db/RSQLite@NA)     |
|testthat |   |1.0.2.9000 |2016-08-25 |Github (hadley/testthat@46d15da) |

# Check results

38 packages with problems

|package          |version  | errors| warnings| notes|
|:----------------|:--------|------:|--------:|-----:|
|AnnotationDbi    |1.34.4   |      0|        1|     5|
|AnnotationForge  |1.14.2   |      0|        1|     6|
|Category         |2.38.0   |      0|        1|     1|
|ChemmineR        |2.24.2   |      1|        0|     0|
|clstutils        |1.20.0   |      0|        2|     5|
|CNEr             |1.8.3    |      0|        2|     1|
|customProDB      |1.12.0   |      1|        1|     3|
|DECIPHER         |2.0.2    |      0|        2|     2|
|ensembldb        |1.4.7    |      0|        1|     1|
|filematrix       |1.1.0    |      0|        1|     0|
|gcbd             |0.2.6    |      0|        1|     1|
|GeneAnswers      |2.14.0   |      1|        3|     6|
|GenomicFeatures  |1.24.5   |      0|        1|     2|
|Genominator      |1.26.0   |      0|        1|     4|
|lumi             |2.24.0   |      0|        5|     5|
|maGUI            |1.0      |      1|        0|     0|
|MeSHDbi          |1.8.0    |      0|        1|     2|
|metaseqR         |1.12.2   |      1|        1|     4|
|mgsa             |1.20.0   |      0|        1|     5|
|oce              |0.9-19   |      1|        0|     1|
|oligo            |1.36.1   |      1|        1|     8|
|OrganismDbi      |1.14.1   |      0|        1|     2|
|PAnnBuilder      |1.36.0   |      0|        4|     1|
|pdInfoBuilder    |1.36.0   |      0|        1|     1|
|PGA              |1.2.2    |      1|        1|     3|
|plethy           |1.10.0   |      2|        0|     3|
|recoup           |1.0.2    |      2|        0|     1|
|RImmPort         |1.0.2    |      0|        1|     1|
|RQDA             |0.2-7    |      1|        0|     1|
|specL            |1.6.2    |      0|        1|     4|
|sqldf            |0.4-10   |      0|        1|     2|
|TFBSTools        |1.10.4   |      0|        1|     1|
|tigre            |1.26.0   |      0|        1|     2|
|trackeR          |0.0.3    |      0|        1|     0|
|TSdata           |2016.8-1 |      0|        1|     0|
|UniProt.ws       |2.12.0   |      0|        1|     1|
|VariantFiltering |1.8.6    |      0|        3|     3|
|vmsbase          |2.1.3    |      1|        0|     0|

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

## AnnotationForge (1.14.2)
Maintainer: Bioconductor Package Maintainer <maintainer@bioconductor.org>

0 errors | 1 warning  | 6 notes

```
checking whether package ‘AnnotationForge’ can be installed ... WARNING
Found the following significant warnings:
  Warning: namespace ‘Rcpp’ is not available and has been replaced
See ‘/home/muelleki/git/R/RSQLite/revdep/checks/AnnotationForge.Rcheck/00install.out’ for details.

checking installed package size ... NOTE
  installed size is  6.1Mb
  sub-directories of 1Mb or more:
    AnnDbPkg-templates   1.8Mb
    extdata              3.3Mb

checking DESCRIPTION meta-information ... NOTE
Packages listed in more than one of Depends, Imports, Suggests, Enhances:
  ‘RSQLite’ ‘XML’
A package should be listed in only one of these fields.

checking dependencies in R code ... NOTE
'library' or 'require' calls in package code:
  ‘GO.db’ ‘RCurl’ ‘RSQLite’ ‘XML’ ‘affy’ ‘biomaRt’ ‘httr’
  Please use :: or requireNamespace() instead.
  See section 'Suggested packages' in the 'Writing R Extensions' manual.

checking R code for possible problems ... NOTE
.addOntologyData: no visible binding for global variable ‘GO.db’
.downloadAndPopulateAltGOData: no visible global function definition
  for ‘CFILE’
.downloadAndPopulateAltGOData: no visible global function definition
  for ‘curlPerform’
.downloadAndSaveToTemp: no visible global function definition for
  ‘url.exists’
.downloadAndSaveToTemp: no visible global function definition for
  ‘getBinaryURL’
... 33 lines ...
getProbeDataAffy: no visible global function definition for
  ‘cleancdfname’
listMappings: no visible global function definition for
  ‘NCBIORG_DB_SeedGenerator’
writeTable: no visible global function definition for
  ‘sqliteWriteTable’
Undefined global functions or variables:
  CFILE GO.db GOBPANCESTOR GOCCANCESTOR GOMFANCESTOR GOTERM GO_dbconn
  NCBIORG_DB_SeedGenerator Stop cleancdfname curlPerform getBM
  getBinaryURL getCurlHandle getURL listAttributes listDatasets
  sqliteWriteTable url.exists useMart

checking Rd line widths ... NOTE
Rd file 'sqlForge-makeCHIPDB.Rd':
  \examples lines wider than 100 characters:
                   fileName = "/mnt/cpb_anno/mcarlson/proj/mcarlson/sqliteGen/srcFiles/hgu95av2/HG_U95Av2_annot.csv.070824",
                     EA="/mnt/cpb_anno/mcarlson/proj/mcarlson/sqliteGen/srcFiles/hgu95av2/hgu95av2.EA.txt",
                     UMICH="/mnt/cpb_anno/mcarlson/proj/mcarlson/sqliteGen/srcFiles/hgu95av2/hgu95av2_UMICH.txt"),

Rd file 'sqlForge-popDB.Rd':
  \examples lines wider than 100 characters:
                  chipSrc = "/mnt/cpb_anno/mcarlson/proj/mcarlson/sqliteGen/annosrc/db/chipsrc_human.sqlite",
                  fileName="/mnt/cpb_anno/mcarlson/proj/mcarlson/sqliteGen/srcFiles/hgu95av2/HG_U95Av2.na27.annot.csv",
                   fileName="/mnt/cpb_anno/mcarlson/proj/mcarlson/sqliteGen/srcFiles/yeast2/Yeast_2.na27.annot.csv",

These lines will be truncated in the PDF manual.

checking for unstated dependencies in vignettes ... NOTE
'library' or 'require' call not declared from: ‘Biostrings’
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

## ChemmineR (2.24.2)
Maintainer: Thomas Girke <thomas.girke@ucr.edu>

1 error  | 0 warnings | 0 notes

```
checking whether package ‘ChemmineR’ can be installed ... ERROR
Installation failed.
See ‘/home/muelleki/git/R/RSQLite/revdep/checks/ChemmineR.Rcheck/00install.out’ for details.
```

## clstutils (1.20.0)
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

## CNEr (1.8.3)
Maintainer: Ge Tan <ge.tan09@imperial.ac.uk>  
Bug reports: https://github.com/ge11232002/CNEr/issues

0 errors | 2 warnings | 1 note 

```
checking compiled code ... WARNING
File ‘CNEr/libs/CNEr.so’:
  Found ‘abort’, possibly from ‘abort’ (C)
    Object: ‘ucsc/errabort.o’
  Found ‘exit’, possibly from ‘exit’ (C)
    Objects: ‘ucsc/errabort.o’, ‘ucsc/pipeline.o’
  Found ‘printf’, possibly from ‘printf’ (C)
    Objects: ‘ceScan.o’, ‘ucsc/pipeline.o’
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
Warning: It seems you should call rmarkdown::render() instead of knitr::knit2html() because CNEr.Rmd appears to be an R Markdown v2 document.
Quitting from lines 2-16 (CNEr.Rmd) 
Error: processing vignette 'CNEr.Rmd' failed with diagnostics:
could not find function "doc_date"
Execution halted


checking dependencies in R code ... NOTE
Unexported objects imported by ':::' calls:
  ‘BiocGenerics:::replaceSlots’
  ‘S4Vectors:::makeClassinfoRowForCompactPrinting’
  ‘S4Vectors:::makePrettyMatrixForCompactPrinting’
  ‘S4Vectors:::make_zero_col_DataFrame’
  See the note in ?`:::` about the use of this operator.
```

## customProDB (1.12.0)
Maintainer: xiaojing wang <xiaojing.wang@vanderbilt.edu>

1 error  | 1 warning  | 3 notes

```
checking examples ... ERROR
Running examples in ‘customProDB-Ex.R’ failed
The error most likely occurred in:

> base::assign(".ptime", proc.time(), pos = "CheckExEnv")
> ### Name: PrepareAnnotationEnsembl
> ### Title: prepare annotation from ENSEMBL
> ### Aliases: PrepareAnnotationEnsembl
> 
> ### ** Examples
... 29 lines ...
8: Entity 'hellip' not defined
9: Entity 'hellip' not defined
10: Entity 'hellip' not defined
11: Opening and ending tag mismatch: img line 68 and li
12: Opening and ending tag mismatch: li line 68 and ul
13: Opening and ending tag mismatch: ul line 67 and div
14: Entity 'copy' not defined
15: Opening and ending tag mismatch: div line 19 and body
16: Opening and ending tag mismatch: body line 17 and html
17: Premature end of data in tag html line 2
Execution halted

checking re-building of vignette outputs ... WARNING
Error in re-building vignettes:
  ...

Loading required package: AnnotationDbi
Loading required package: Biobase
Welcome to Bioconductor

    Vignettes contain introductory material; view with
    'browseVignettes()'. To cite Bioconductor, see
... 8 lines ...
Extract the 'transcripts' data frame ... OK
Extract the 'splicings' data frame ... OK
Download and preprocess the 'chrominfo' data frame ... OK
Prepare the 'metadata' data frame ... OK
Make the TxDb object ... OK
 done
Prepare gene/transcript/protein id mapping information (ids.RData) ... 
Error: processing vignette 'customProDB.Rnw' failed with diagnostics:
 chunk 3 (label = PrepareAnnoRef) 
Error in normArgTable(value, x) : unknown table name 'refLink'
Execution halted

checking DESCRIPTION meta-information ... NOTE
Malformed Title field: should not end in a period.
Malformed Description field: should contain one or more complete sentences.
Packages listed in more than one of Depends, Imports, Suggests, Enhances:
  ‘IRanges’ ‘biomaRt’ ‘AnnotationDbi’
A package should be listed in only one of these fields.

checking dependencies in R code ... NOTE
Unexported objects imported by ':::' calls:
  ‘biomaRt:::martBM’ ‘biomaRt:::martDataset’ ‘biomaRt:::martHost’
  See the note in ?`:::` about the use of this operator.

checking R code for possible problems ... NOTE
.Ensembl.getTable: no visible global function definition for
  ‘download.file’
.Ensembl.getTable: no visible global function definition for
  ‘read.table’
Bed2Range: no visible global function definition for ‘read.table’
Bed2Range: no visible binding for global variable ‘V5’
OutputNovelJun: no visible binding for global variable ‘jun_type’
OutputVarproseq: no visible binding for global variable ‘genename’
OutputVarproseq: no visible binding for global variable ‘txname’
... 46 lines ...
Varlocation: no visible binding for global variable ‘pro_name’
easyRun: no visible global function definition for ‘write.table’
easyRun_mul: no visible global function definition for ‘write.table’
Undefined global functions or variables:
  V5 aapos aaref aavar alleleCount alleles allsample cds_end cds_start
  chrom download.file ensembl_gene_id genename jun_type mrnaAcc name
  pro_name proname protAcc read.table rsid saveDb transcript txname
  write.table
Consider adding
  importFrom("utils", "download.file", "read.table", "write.table")
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
  installed size is  8.9Mb
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

## ensembldb (1.4.7)
Maintainer: Johannes Rainer <johannes.rainer@eurac.edu>  
Bug reports: https://github.com/jotsetung/ensembldb/issues

0 errors | 1 warning  | 1 note 

```
checking re-building of vignette outputs ... WARNING
Error in re-building vignettes:
  ...
Warning: It seems you should call rmarkdown::render() instead of knitr::knit2html() because ensembldb.Rmd appears to be an R Markdown v2 document.
Quitting from lines 2-48 (ensembldb.Rmd) 
Error: processing vignette 'ensembldb.Rmd' failed with diagnostics:
could not find function "Biocpkg"
Execution halted


checking dependencies in R code ... NOTE
Unexported objects imported by ':::' calls:
  'GenomicFeatures:::fetchChromLengthsFromEnsembl'
  'GenomicFeatures:::fetchChromLengthsFromEnsemblPlants'
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
Warning: It seems you should call rmarkdown::render() instead of knitr::knit2html() because Best_Prectices.Rmd appears to be an R Markdown v2 document.
Quitting from lines 2-23 (Best_Prectices.Rmd) 
Error: processing vignette 'Best_Prectices.Rmd' failed with diagnostics:
could not find function "doc_date"
Execution halted

```

## gcbd (0.2.6)
Maintainer: Dirk Eddelbuettel <edd@debian.org>

0 errors | 1 warning  | 1 note 

```
checking re-building of vignette outputs ... WARNING
Error in re-building vignettes:
  ...
Warning in packageDescription("gputools") :
  no package 'gputools' was found
Error: processing vignette 'gcbd.Rnw' failed with diagnostics:
at gcbd.Rnw:860, subscript out of bounds
Execution halted


checking package dependencies ... NOTE
Package suggested but not available for checking: ‘gputools’
```

## GeneAnswers (2.14.0)
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
     compacted ‘geneAnswers.pdf’ from 1401Kb to 597Kb
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
  installed size is 36.2Mb
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

## GenomicFeatures (1.24.5)
Maintainer: Bioconductor Package Maintainer <maintainer@bioconductor.org>

0 errors | 1 warning  | 2 notes

```
checking whether package ‘GenomicFeatures’ can be installed ... WARNING
Found the following significant warnings:
  Warning: namespace ‘Rcpp’ is not available and has been replaced
See ‘/home/muelleki/git/R/RSQLite/revdep/checks/GenomicFeatures.Rcheck/00install.out’ for details.

checking package dependencies ... NOTE
Depends: includes the non-default packages:
  ‘BiocGenerics’ ‘S4Vectors’ ‘IRanges’ ‘GenomeInfoDb’ ‘GenomicRanges’
  ‘AnnotationDbi’
Adding so many packages to the search path is excessive and importing
selectively is preferable.

checking dependencies in R code ... NOTE
Unexported objects imported by ':::' calls:
  ‘AnnotationDbi:::.getMetaValue’ ‘AnnotationDbi:::.valid.colnames’
  ‘AnnotationDbi:::.valid.metadata.table’
  ‘AnnotationDbi:::.valid.table.colnames’ ‘AnnotationDbi:::dbEasyQuery’
  ‘AnnotationDbi:::dbQuery’ ‘AnnotationDbi:::smartKeys’
  ‘biomaRt:::martBM’ ‘biomaRt:::martDataset’ ‘biomaRt:::martHost’
  ‘rtracklayer:::resourceDescription’ ‘rtracklayer:::ucscTableOutputs’
  See the note in ?`:::` about the use of this operator.
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

## lumi (2.24.0)
Maintainer: Pan Du <dupan.mail@gmail.com>

0 errors | 5 warnings | 5 notes

```
checking whether package ‘lumi’ can be installed ... WARNING
Found the following significant warnings:
  Warning: bad markup (extra space?) at lumiMethyR.Rd:18:16
  Warning: bad markup (extra space?) at lumiMethyR.Rd:19:28
  Warning: bad markup (extra space?) at lumiMethyR.Rd:20:13
See ‘/home/muelleki/git/R/RSQLite/revdep/checks/lumi.Rcheck/00install.out’ for details.

checking dependencies in R code ... WARNING
'::' or ':::' import not declared from: ‘bigmemoryExtras’
'library' or 'require' call to ‘vsn’ in package code.
  Please use :: or requireNamespace() instead.
  See section 'Suggested packages' in the 'Writing R Extensions' manual.

checking Rd files ... WARNING
prepare_Rd: getChrInfo.Rd:23-25: Dropping empty section \details
prepare_Rd: getChrInfo.Rd:29-31: Dropping empty section \references
prepare_Rd: getChrInfo.Rd:38-40: Dropping empty section \seealso
prepare_Rd: getChrInfo.Rd:41-44: Dropping empty section \examples
prepare_Rd: importMethyIDAT.Rd:39-42: Dropping empty section \examples
prepare_Rd: bad markup (extra space?) at lumiMethyR.Rd:18:16
prepare_Rd: bad markup (extra space?) at lumiMethyR.Rd:19:28
prepare_Rd: bad markup (extra space?) at lumiMethyR.Rd:20:13

checking Rd contents ... WARNING
Argument items with no description in Rd object 'lumiMethyR':
  ‘qcfile’ ‘sampleDescriptions’ ‘sep’


checking re-building of vignette outputs ... WARNING
Error in re-building vignettes:
  ...

Attaching package: ‘XML’

The following object is masked from ‘package:tools’:

    toHTML

... 8 lines ...
  documentation provided with the lumi package.

Error in texi2dvi(file = file, pdf = TRUE, clean = clean, quiet = quiet,  : 
  Running 'texi2dvi' on 'IlluminaAnnotation.tex' failed.
LaTeX errors:
! Package auto-pst-pdf Error: 
    "shell escape" (or "write18") is not enabled:
    auto-pst-pdf will not work!
.
Calls: buildVignettes -> texi2pdf -> texi2dvi
Execution halted

checking installed package size ... NOTE
  installed size is 11.8Mb
  sub-directories of 1Mb or more:
    R      2.8Mb
    data   3.6Mb
    doc    5.0Mb

checking DESCRIPTION meta-information ... NOTE
Package listed in more than one of Depends, Imports, Suggests, Enhances:
  ‘Biobase’
A package should be listed in only one of these fields.

checking R code for possible problems ... NOTE
.estimate.quantile.reference: no visible global function definition for
  ‘approx’
.initialGammaEstimation: no visible global function definition for
  ‘quantile’
.initialGammaEstimation: no visible global function definition for
  ‘var’
.quantileNormalization.reference: no visible global function definition
  for ‘approx’
addAnnotationInfo: no visible global function definition for ‘fData’
... 247 lines ...
Consider adding
  importFrom("grDevices", "colors")
  importFrom("graphics", "Axis", "arrows", "box", "layout", "legend",
             "rect", "title")
  importFrom("stats", "approx", "as.dist", "cmdscale", "cor",
             "density.default", "dgamma", "dist", "ecdf", "hclust", "lm",
             "median", "pgamma", "predict", "quantile", "sd", "start",
             "supsmu", "var")
  importFrom("utils", "head", "packageDescription", "read.table", "tail",
             "write.table")
to your NAMESPACE file.

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

## MeSHDbi (1.8.0)
Maintainer: Koki Tsuyuzaki <k.t.the-answer@hotmail.co.jp>

0 errors | 1 warning  | 2 notes

```
checking whether package ‘MeSHDbi’ can be installed ... WARNING
Found the following significant warnings:
  Warning: namespace ‘Rcpp’ is not available and has been replaced
See ‘/home/muelleki/git/R/RSQLite/revdep/checks/MeSHDbi.Rcheck/00install.out’ for details.

checking R code for possible problems ... NOTE
.div: no visible global function definition for ‘na.omit’
Undefined global functions or variables:
  na.omit
Consider adding
  importFrom("stats", "na.omit")
to your NAMESPACE file.

checking Rd line widths ... NOTE
Rd file 'makeMeSHPackage.Rd':
  \examples lines wider than 100 characters:
                                             maintainer = "Koki Tsuyuzaki <k.t.the-answer@hotmail.co.jp>",

These lines will be truncated in the PDF manual.
```

## metaseqR (1.12.2)
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

The following objects are masked from 'package:GenomicAlignments':

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
... 239 lines ...
Consider adding
  importFrom("grDevices", "bmp", "colorRampPalette", "dev.new",
             "dev.off", "jpeg", "pdf", "png", "postscript", "tiff")
  importFrom("graphics", "abline", "arrows", "axis", "grid", "lines",
             "mtext", "par", "plot", "plot.new", "plot.window", "points",
             "text", "title")
  importFrom("stats", "as.dist", "cmdscale", "cor", "end", "ks.test",
             "mad", "median", "model.matrix", "na.exclude", "optimize",
             "p.adjust", "p.adjust.methods", "pchisq", "quantile",
             "rexp", "rnbinom", "runif", "sd", "start", "var")
to your NAMESPACE file.
```

## mgsa (1.20.0)
Maintainer: Sebastian Bauer <mail@sebastianbauer.info>

0 errors | 1 warning  | 5 notes

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

checking compiled code ... NOTE
File ‘mgsa/libs/mgsa.so’:
  Found ‘printf’, possibly from ‘printf’ (C)
    Object: ‘mgsa.o’

Compiled code should not call entry points which might terminate R nor
write to stdout/stderr instead of to the console, nor the system RNG.

See ‘Writing portable packages’ in the ‘Writing R Extensions’ manual.
```

## oce (0.9-19)
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
  installed size is  5.1Mb
  sub-directories of 1Mb or more:
    help   2.0Mb
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
  installed size is 30.0Mb
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

## OrganismDbi (1.14.1)
Maintainer: Biocore Data Team <maintainer@bioconductor.org>

0 errors | 1 warning  | 2 notes

```
checking whether package ‘OrganismDbi’ can be installed ... WARNING
Found the following significant warnings:
  Warning: namespace ‘Rcpp’ is not available and has been replaced
See ‘/home/muelleki/git/R/RSQLite/revdep/checks/OrganismDbi.Rcheck/00install.out’ for details.

checking dependencies in R code ... NOTE
Unexported object imported by a ':::' call: ‘BiocGenerics:::testPackage’
  See the note in ?`:::` about the use of this operator.
There are ::: calls to the package's namespace in its code. A package
  almost never needs to use ::: for its own objects:
  ‘.biocAnnPackages’ ‘.extractPkgsAndCols’ ‘.gentlyExtractDbFiles’
  ‘.lookupDbNameFromKeytype’ ‘.mungeGraphData’ ‘.taxIdToOrgDb’
  ‘.taxIdToOrgDbName’ ‘.testGraphData’ ‘.testKeys’ ‘OrganismDb’

checking R code for possible problems ... NOTE
Found the following assignments to the global environment:
File ‘OrganismDbi/R/createOrganismPackage.R’:
  assign(txdbName, txdb, .GlobalEnv)
  assign(orgdbName, orgdb, .GlobalEnv)
  assign(orgdbName, orgdb, .GlobalEnv)
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

## PGA (1.2.2)
Maintainer: Bo Wen <wenbo@genomics.cn>, Shaohang Xu <xsh.skye@gmail.com>

1 error  | 1 warning  | 3 notes

```
checking examples ... ERROR
Running examples in ‘PGA-Ex.R’ failed
The error most likely occurred in:

> base::assign(".ptime", proc.time(), pos = "CheckExEnv")
> ### Name: PrepareAnnotationEnsembl2
> ### Title: Prepare annotation from ENSEMBL
> ### Aliases: PrepareAnnotationEnsembl2
> 
> ### ** Examples
... 29 lines ...
8: Entity 'hellip' not defined
9: Entity 'hellip' not defined
10: Entity 'hellip' not defined
11: Opening and ending tag mismatch: img line 68 and li
12: Opening and ending tag mismatch: li line 68 and ul
13: Opening and ending tag mismatch: ul line 67 and div
14: Entity 'copy' not defined
15: Opening and ending tag mismatch: div line 19 and body
16: Opening and ending tag mismatch: body line 17 and html
17: Premature end of data in tag html line 2
Execution halted

checking whether package ‘PGA’ can be installed ... WARNING
Found the following significant warnings:
  Warning: replacing previous import ‘data.table::shift’ by ‘IRanges::shift’ when loading ‘PGA’
See ‘/home/muelleki/git/R/RSQLite/revdep/checks/PGA.Rcheck/00install.out’ for details.

checking installed package size ... NOTE
  installed size is  5.6Mb
  sub-directories of 1Mb or more:
    extdata   1.8Mb

checking dependencies in R code ... NOTE
Unexported objects imported by ':::' calls:
  ‘biomaRt:::martBM’ ‘biomaRt:::martDataset’ ‘biomaRt:::martHost’
  ‘customProDB:::makeTranscriptDbFromBiomart_archive’
  See the note in ?`:::` about the use of this operator.

checking R code for possible problems ... NOTE
.base_transfer: no visible global function definition for ‘read.delim’
.base_transfer: no visible binding for global variable ‘peptide’
.base_transfer: no visible binding for global variable ‘refbase’
.base_transfer: no visible binding for global variable ‘varbase’
.base_transfer: no visible binding for global variable ‘aaref’
.base_transfer: no visible binding for global variable ‘aavar’
.base_transfer: no visible binding for global variable ‘Type’
.base_transfer: no visible binding for global variable ‘Freq’
.get_30aa_splited_seq: no visible global function definition for ‘.’
... 301 lines ...
  setNames subseq text transcript tx_name txid txname varbase
  write.table writeXStringSet x xyz y
Consider adding
  importFrom("grDevices", "colorRampPalette", "dev.off", "pdf", "png",
             "rainbow")
  importFrom("graphics", "abline", "axTicks", "axis", "barplot", "box",
             "clip", "hist", "lines", "mtext", "par", "pie", "plot",
             "points", "rug", "text")
  importFrom("stats", "density", "rt", "setNames")
  importFrom("utils", "read.delim", "read.table", "write.table")
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
Processing /tmp/RtmpgsEUyw/filec7ee56f2026d in chunks of 10000
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
  closing unused connection 3 (/tmp/RtmpXii8VL/filec8ef239dede8) 
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

## recoup (1.0.2)
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
calcDesignPlotProfiles : <anonymous>: no visible global function
  definition for ‘smooth.spline’
calcPlotProfiles : <anonymous>: no visible global function definition
  for ‘smooth.spline’
cmclapply: no visible global function definition for ‘mclapply’
... 85 lines ...
  seqlevels seqlevels<- sexon smooth.spline spline subjectHits tiff
  unzip var
Consider adding
  importFrom("grDevices", "bmp", "col2rgb", "dev.new", "dev.off", "jpeg",
             "pdf", "png", "postscript", "tiff")
  importFrom("graphics", "plot")
  importFrom("stats", "approx", "kmeans", "lowess", "quantile",
             "smooth.spline", "spline", "var")
  importFrom("utils", "download.file", "packageVersion", "read.delim",
             "unzip")
to your NAMESPACE file.
```

## RImmPort (1.0.2)
Maintainer: Ravi Shankar <rshankar@stanford.edu>

0 errors | 1 warning  | 1 note 

```
checking sizes of PDF files under ‘inst/doc’ ... WARNING
  ‘gs+qpdf’ made some significant size reductions:
     compacted ‘RImmPort_Article.pdf’ from 761Kb to 336Kb
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

## RQDA (0.2-7)
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

## TFBSTools (1.10.4)
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

## trackeR (0.0.3)
Maintainer: Hannah Frick <h.frick@ucl.ac.uk>

0 errors | 1 warning  | 0 notes

```
checking re-building of vignette outputs ... WARNING
Error in re-building vignettes:
  ...
Warning in readLines(con) :
  incomplete final line found on 'TourDetrackeR.Rmd'
Warning: It seems you should call rmarkdown::render() instead of knitr::knit2html() because TourDetrackeR.Rmd appears to be an R Markdown v2 document.
Loading required package: zoo

Attaching package: 'zoo'

... 7 lines ...
Attaching package: 'trackeR'

The following object is masked from 'package:base':

    append

Map from URL : http://maps.googleapis.com/maps/api/staticmap?center=57.157231,-2.104296&zoom=13&size=640x640&scale=2&maptype=terrain&sensor=false
Quitting from lines 96-97 (TourDetrackeR.Rmd) 
Error: processing vignette 'TourDetrackeR.Rmd' failed with diagnostics:
there is no package called 'webshot'
Execution halted
```

## TSdata (2016.8-1)
Maintainer: Paul Gilbert <pgilbert.ttv9z@ncf.ca>

0 errors | 1 warning  | 0 notes

```
checking re-building of vignette outputs ... WARNING
Error in re-building vignettes:
  ...
Oct 06, 2016 9:34:26 PM it.bancaditalia.oss.sdmx.util.Configuration init
INFO: Configuration file: /home/muelleki/R/x86_64-pc-linux-gnu-library/3.3/RJSDMX/configuration.properties
Oct 06, 2016 9:34:26 PM it.bancaditalia.oss.sdmx.client.RestSdmxClient runQuery
INFO: Contacting web service with query: http://stats.oecd.org/restsdmx/sdmx.ashx//GetDataStructure/QNA
Oct 06, 2016 9:34:26 PM it.bancaditalia.oss.sdmx.client.RestSdmxClient runQuery
INFO: Contacting web service with query: http://stats.oecd.org/restsdmx/sdmx.ashx//GetDataStructure/QNA
Oct 06, 2016 9:34:27 PM it.bancaditalia.oss.sdmx.client.RestSdmxClient runQuery
... 8 lines ...
Oct 06, 2016 9:34:28 PM it.bancaditalia.oss.sdmx.client.RestSdmxClient runQuery
INFO: Contacting web service with query: http://ec.europa.eu/eurostat/SDMX/diss-web/rest/data/ESTAT,ei_nama_q,1.0/Q.MIO-EUR.NSA.CP.NA-P72.IT
Oct 06, 2016 9:34:28 PM it.bancaditalia.oss.sdmx.client.RestSdmxClient getData
INFO: The sdmx call returned messages in the footer:
 Message [code=400, severity=Error, url=null, text=[Error caused by the caller due to incorrect or semantically invalid arguments]]

Error: processing vignette 'Guide.Stex' failed with diagnostics:
 chunk 5 
Error in .local(serIDs, con, ...) : 
  ei_nama_q.Q.MIO-EUR.NSA.CP.NA-P72.IT error: it.bancaditalia.oss.sdmx.util.SdmxException: The query: ei_nama_q.Q.MIO-EUR.NSA.CP.NA-P72.IT did not match any time series on the provider.
Execution halted
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
  installed size is  7.8Mb
  sub-directories of 1Mb or more:
    R         3.5Mb
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

## vmsbase (2.1.3)
Maintainer: Lorenzo D'Andrea <support@vmsbase.org>

1 error  | 0 warnings | 0 notes

```
checking whether package ‘vmsbase’ can be installed ... ERROR
Installation failed.
See ‘/home/muelleki/git/R/RSQLite/revdep/checks/vmsbase.Rcheck/00install.out’ for details.
```

