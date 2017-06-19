# Setup

## Platform

|setting  |value                        |
|:--------|:----------------------------|
|version  |R version 3.4.0 (2017-04-21) |
|system   |x86_64, linux-gnu            |
|ui       |X11                          |
|language |(EN)                         |
|collate  |en_US.UTF-8                  |
|tz       |Zulu                         |
|date     |2017-06-17                   |

## Packages

|package   |*  |version   |date       |source                             |
|:---------|:--|:---------|:----------|:----------------------------------|
|BH        |   |1.62.0-1  |2016-11-19 |cran (@1.62.0-)                    |
|bit64     |   |0.9-7     |2017-05-08 |cran (@0.9-7)                      |
|blob      |   |1.1.0     |2017-06-17 |Github (tidyverse/blob@9dd54d9)    |
|DBI       |   |0.6-13    |2017-05-08 |Github (rstats-db/DBI@f6500a5)     |
|DBItest   |   |1.4-22    |2017-05-08 |Github (rstats-db/DBItest@1f344a3) |
|knitr     |   |1.16      |2017-05-18 |cran (@1.16)                       |
|memoise   |   |1.1.0     |2017-04-21 |CRAN (R 3.4.0)                     |
|pkgconfig |   |2.0.1     |2017-03-21 |cran (@2.0.1)                      |
|plogr     |   |0.1-1     |2016-09-24 |cran (@0.1-1)                      |
|Rcpp      |   |0.12.11.2 |2017-06-05 |local                              |
|rmarkdown |   |1.6       |2017-06-15 |cran (@1.6)                        |
|RSQLite   |   |1.1-17    |2017-06-17 |local                              |
|testthat  |   |1.0.2     |2016-04-23 |cran (@1.0.2)                      |

# Check results

38 packages with problems

|package            |version   | errors| warnings| notes|
|:------------------|:---------|------:|--------:|-----:|
|anchoredDistr      |1.0.2     |      0|        1|     0|
|AnnotationDbi      |1.38.1    |      0|        1|     5|
|AnnotationHubData  |1.6.0     |      1|        0|     4|
|BiocFileCache      |1.0.0     |      1|        1|     0|
|Category           |2.42.0    |      1|        0|     1|
|ChemmineR          |2.28.0    |      1|        0|     0|
|chunked            |0.3       |      1|        0|     1|
|clstutils          |1.24.0    |      0|        2|     5|
|CNEr               |1.12.0    |      2|        3|     3|
|cummeRbund         |2.18.0    |      1|        1|     6|
|etl                |0.3.5     |      1|        1|     0|
|GeneAnswers        |2.18.0    |      1|        3|     6|
|GenomicFeatures    |1.28.3    |      1|        1|     3|
|liteq              |1.0.0     |      1|        0|     0|
|lumi               |2.28.0    |      0|        2|     3|
|maGUI              |2.2       |      1|        0|     0|
|metagenomeFeatures |1.8.0     |      1|        0|     0|
|metaseqR           |1.16.0    |      1|        1|     4|
|mgsa               |1.24.0    |      0|        1|     5|
|MonetDBLite        |0.3.1     |      2|        0|     3|
|oce                |0.9-21    |      1|        0|     1|
|oligoClasses       |1.38.0    |      0|        2|     4|
|oligo              |1.40.1    |      1|        1|     9|
|Organism.dplyr     |1.0.0     |      1|        0|     0|
|PAnnBuilder        |1.40.0    |      0|        3|     1|
|plethy             |1.14.0    |      2|        0|     3|
|poplite            |0.99.17.3 |      2|        1|     0|
|recoup             |1.4.0     |      2|        0|     1|
|RImmPort           |1.4.1     |      0|        1|     0|
|RQDA               |0.2-8     |      1|        0|     1|
|seqplots           |1.13.0    |      2|        0|     3|
|sf                 |0.5-0     |      1|        0|     1|
|sqldf              |0.4-10    |      1|        1|     2|
|taxizedb           |0.1.0     |      1|        0|     0|
|TFBSTools          |1.14.0    |      2|        1|     4|
|TSdata             |2016.8-1  |      0|        1|     0|
|VariantFiltering   |1.12.1    |      0|        1|     4|
|vmsbase            |2.1.3     |      1|        0|     0|

## anchoredDistr (1.0.2)
Maintainer: Heather Savoy <frystacka@berkeley.edu>

0 errors | 1 warning  | 0 notes

```
checking re-building of vignette outputs ... WARNING
Error in re-building vignettes:
  ...
Quitting from lines 50-64 (anchoredDistr.Rmd) 
Error: processing vignette 'anchoredDistr.Rmd' failed with diagnostics:
cannot open the connection
Execution halted

```

## AnnotationDbi (1.38.1)
Maintainer: Bioconductor Package Maintainer <maintainer@bioconductor.org>

0 errors | 1 warning  | 5 notes

```
checking for unstated dependencies in ‘tests’ ... WARNING
'library' or 'require' call not declared from: ‘org.testing.db’

checking installed package size ... NOTE
  installed size is  8.7Mb
  sub-directories of 1Mb or more:
    R         1.0Mb
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

## AnnotationHubData (1.6.0)
Maintainer: Bioconductor Package Maintainer <maintainer@bioconductor.org>

1 error  | 0 warnings | 4 notes

```
checking tests ... ERROR
  Running ‘AnnotationHubData_unit_tests.R’ [66s/121s]
Running the tests in ‘tests/AnnotationHubData_unit_tests.R’ failed.
Last 13 lines of output:
  
   
  1 Test Suite : 
  AnnotationHubData RUnit Tests - 21 test functions, 1 error, 0 failures
  ERROR in test_Grasp2Db_recipe: Error : object 'src_sql' is not exported by 'namespace:dplyr'
  
  Test files with failing tests
  
     test_recipe.R 
       test_Grasp2Db_recipe 
  
  
  Error in BiocGenerics:::testPackage("AnnotationHubData") : 
    unit tests failed for package AnnotationHubData
  Execution halted

checking DESCRIPTION meta-information ... NOTE
Package listed in more than one of Depends, Imports, Suggests, Enhances:
  ‘BiocInstaller’
A package should be listed in only one of these fields.

checking top-level files ... NOTE
Non-standard file/directory found at top level:
  ‘appveyor.yml’

checking dependencies in R code ... NOTE
'library' or 'require' call to ‘BiocInstaller’ in package code.
  Please use :: or requireNamespace() instead.
  See section 'Suggested packages' in the 'Writing R Extensions' manual.
Missing object imported by a ':::' call: ‘AnnotationHub:::.db_connection’
Unexported object imported by a ':::' call: ‘OrganismDbi:::.packageTaxIds’
  See the note in ?`:::` about the use of this operator.

checking R code for possible problems ... NOTE
.NCBIMetadataFromUrl: no visible binding for global variable ‘results’
.NCBIMetadataFromUrl: no visible binding for global variable ‘specData’
.cleanOneTable: no visible global function definition for ‘dbGetQuery’
.getOtherTableDupIDs: no visible global function definition for
  ‘dbGetQuery’
.makeComplexGR: no visible binding for global variable ‘seqname’
getCurrentResources: no visible global function definition for
  ‘dbGetQuery’
makeAnnotationHubMetadata : <anonymous> : <anonymous>: no visible
... 44 lines ...
test_Inparanoid8ImportPreparer_recipe: no visible binding for global
  variable ‘BiocVersion’
test_Inparanoid8ImportPreparer_recipe: no visible global function
  definition for ‘checkTrue’
trackWithAuxiliaryTablesToGRanges: no visible binding for global
  variable ‘seqname’
Undefined global functions or variables:
  BiocVersion Coordinate_1_based DataProvider Description DispatchClass
  Genome Location_Prefix Maintainer RDataClass RDataDateAdded RDataPath
  SourceType SourceUrl SourceVersion Species TaxonomyId Title ahroot
  checkTrue dbGetQuery results seqname specData suppresWarnings
```

## BiocFileCache (1.0.0)
Maintainer: Lori Shepherd <lori.shepherd@roswellpark.org>  
Bug reports: https://github.com/Bioconductor/BiocFileCache/issues

1 error  | 1 warning  | 0 notes

```
checking tests ... ERROR
  Running ‘testthat.R’
Running the tests in ‘tests/testthat.R’ failed.
Last 13 lines of output:
  39: eval(exprs, env)
  40: source_file(path, new.env(parent = env), chdir = TRUE)
  41: force(code)
  42: with_reporter(reporter = reporter, start_end_reporter = start_end_reporter,     {        lister$start_file(basename(path))        source_file(path, new.env(parent = env), chdir = TRUE)        end_context()    })
  43: FUN(X[[i]], ...)
  44: lapply(paths, test_file, env = env, reporter = current_reporter,     start_end_reporter = FALSE, load_helpers = FALSE)
  45: force(code)
  46: with_reporter(reporter = current_reporter, results <- lapply(paths,     test_file, env = env, reporter = current_reporter, start_end_reporter = FALSE,     load_helpers = FALSE))
  47: test_files(paths, reporter = reporter, env = env, ...)
  48: test_dir(test_path, reporter = reporter, env = env, filter = filter,     ...)
  49: with_top_env(env, {    test_dir(test_path, reporter = reporter, env = env, filter = filter,         ...)})
  50: run_tests(package, test_path, filter, reporter, ...)
  51: test_check("BiocFileCache")
  An irrecoverable exception occurred. R is aborting now ...
  Segmentation fault (core dumped)

checking re-building of vignette outputs ... WARNING
Error in re-building vignettes:
  ...
Loading required package: dplyr

Attaching package: 'dplyr'

The following objects are masked from 'package:stats':

    filter, lag

The following objects are masked from 'package:base':

    intersect, setdiff, setequal, union

Quitting from lines 88-89 (BiocFileCache.Rmd) 
Error: processing vignette 'BiocFileCache.Rmd' failed with diagnostics:
limit not greater than 0
Execution halted

```

## Category (2.42.0)
Maintainer: Bioconductor Package Maintainer <maintainer@bioconductor.org>

1 error  | 0 warnings | 1 note 

```
checking tests ... ERROR
  Running ‘runTests.R’ [39s/39s]
Running the tests in ‘tests/runTests.R’ failed.
Last 13 lines of output:
  1 Test Suite : 
  Category RUnit Tests - 9 test functions, 2 errors, 0 failures
  ERROR in test_basic_regression_YEAST: Error in dbGetQuery(db, SQL) : could not find function "dbGetQuery"
  ERROR in test_basic_regression_hgu95av2: Error in dbGetQuery(db, SQL) : could not find function "dbGetQuery"
  
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

## ChemmineR (2.28.0)
Maintainer: Thomas Girke <thomas.girke@ucr.edu>

1 error  | 0 warnings | 0 notes

```
checking whether package ‘ChemmineR’ can be installed ... ERROR
Installation failed.
See ‘/home/muelleki/git/R/RSQLite/revdep/checks/ChemmineR.Rcheck/00install.out’ for details.
```

## chunked (0.3)
Maintainer: Edwin de Jonge <edwindjonge@gmail.com>  
Bug reports: https://github.com/edwindj/chunked/issues

1 error  | 0 warnings | 1 note 

```
checking tests ... ERROR
  Running ‘testthat.R’
Running the tests in ‘tests/testthat.R’ failed.
Last 13 lines of output:
  1. Error: write_chunkwise to db works (@test-write.R#29) -----------------------
  'sql_render' is not an exported object from 'namespace:dplyr'
  1: write_chunkwise(iris2, tmp, row.names = FALSE) at testthat/test-write.R:29
  2: write_chunkwise.tbl_sql(iris2, tmp, row.names = FALSE)
  3: dplyr::sql_render
  4: getExportedValue(pkg, name)
  5: stop(gettextf("'%s' is not an exported object from 'namespace:%s'", name, getNamespaceName(ns)), 
         call. = FALSE, domain = NA)
  
  testthat results ================================================================
  OK: 30 SKIPPED: 0 FAILED: 1
  1. Error: write_chunkwise to db works (@test-write.R#29) 
  
  Error: testthat unit tests failed
  Execution halted

checking dependencies in R code ... NOTE
Missing or unexported object: ‘dplyr::sql_render’
```

## clstutils (1.24.0)
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

## CNEr (1.12.0)
Maintainer: Ge Tan <ge_tan@live.com>  
Bug reports: https://github.com/ge11232002/CNEr/issues

2 errors | 3 warnings | 3 notes

```
checking examples ... ERROR
Running examples in ‘CNEr-Ex.R’ failed
The error most likely occurred in:

> base::assign(".ptime", proc.time(), pos = "CheckExEnv")
> ### Name: CNEDensity-methods
> ### Title: CNEDensity function
> ### Aliases: CNEDensity CNEDensity-methods
> ###   CNEDensity,ANY,character,character,missing,missing-method
> ###   CNEDensity,ANY,missing,character,character,character-method
... 11 lines ...
> minLength <- 50L
> cneDanRer10Hg38_45_50 <- 
+   CNEDensity(dbName=dbName, 
+              tableName="danRer10_hg38_45_50", 
+              whichAssembly="first", chr=chr, start=start,
+              end=end, windowSize=windowSize, 
+              minLength=minLength)
Error in dbGetQuery(con, sqlCmd) : could not find function "dbGetQuery"
Calls: CNEDensity -> .CNEDensityInternal -> readCNERangesFromSQLite
Execution halted
** found \donttest examples: check also with --run-donttest

checking tests ... ERROR
  Running ‘testthat.R’ [21s/25s]
Running the tests in ‘tests/testthat.R’ failed.
Last 13 lines of output:
  2. Error: test_readCNERangesFromSQLite (@test_IO.R#102) ------------------------
  could not find function "dbGetQuery"
  1: readCNERangesFromSQLite(dbName = dbName, tableName = "danRer10_hg38_45_50") at testthat/test_IO.R:102
  
  The number of axt files 1
  The number of axt alignments is 50
  The number of axt files 1
  The number of axt alignments is 352
  testthat results ================================================================
  OK: 81 SKIPPED: 0 FAILED: 2
  1. Error: test_GRangePairs (@test_GRangePairs.R#94) 
  2. Error: test_readCNERangesFromSQLite (@test_IO.R#102) 
  
  Error: testthat unit tests failed
  Execution halted

checking for missing documentation entries ... WARNING
Undocumented code objects:
  ‘addAncestorGO’
All user-level objects in a package should have documentation entries.
See chapter ‘Writing R documentation files’ in the ‘Writing R
Extensions’ manual.

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
File ‘CNEr/libs/CNEr.so’:
  Found no call to: ‘R_useDynamicSymbols’

Compiled code should not call entry points which might terminate R nor
write to stdout/stderr instead of to the console, nor the system RNG.
It is good practice to register native routines and to disable symbol
search.

See ‘Writing portable packages’ in the ‘Writing R Extensions’ manual.

checking re-building of vignette outputs ... WARNING
Error in re-building vignettes:
  ...
The following object is masked from 'package:base':

    expand.grid

Loading required package: IRanges
Loading required package: GenomeInfoDb
Loading required package: GenomicRanges
... 8 lines ...
    N50

The following object is masked from 'package:base':

    strsplit

Loading required package: rtracklayer
Quitting from lines 376-385 (CNEr.Rmd) 
Error: processing vignette 'CNEr.Rmd' failed with diagnostics:
could not find function "dbGetQuery"
Execution halted

checking installed package size ... NOTE
  installed size is 29.4Mb
  sub-directories of 1Mb or more:
    R        11.5Mb
    extdata  15.9Mb
    libs      1.1Mb

checking dependencies in R code ... NOTE
Unexported objects imported by ':::' calls:
  ‘BiocGenerics:::replaceSlots’ ‘S4Vectors:::make_zero_col_DataFrame’
  See the note in ?`:::` about the use of this operator.

checking R code for possible problems ... NOTE
queryAnnotationSQLite: no visible global function definition for
  ‘dbGetQuery’
queryCNEData: no visible global function definition for ‘dbGetQuery’
readCNERangesFromSQLite: no visible global function definition for
  ‘dbGetQuery’
Undefined global functions or variables:
  dbGetQuery
```

## cummeRbund (2.18.0)
Maintainer: Loyal A. Goff <lgoff@csail.mit.edu>

1 error  | 1 warning  | 6 notes

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
... 161 lines ...
Reading Read Group Info  /home/muelleki/git/R/RSQLite/revdep/checks/cummeRbund.Rcheck/cummeRbund/extdata/read_groups.info
Warning: RSQLite::make.db.names() is deprecated, please switch to DBI::dbQuoteIdentifier().
Writing replicates Table
Warning: Factors converted to character
Warning in rsqlite_fetch(res@ptr, n = n) :
  Don't need to call dbFetch() for statements, only for queries
Reading /home/muelleki/git/R/RSQLite/revdep/checks/cummeRbund.Rcheck/cummeRbund/extdata/genes.fpkm_tracking
Checking samples table...
Populating samples table...
Error: Column name mismatch.
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
Error in rsqlite_send_query(conn@ptr, statement) : near ")": syntax error
Execution halted

checking package dependencies ... NOTE
Depends: includes the non-default packages:
  ‘BiocGenerics’ ‘RSQLite’ ‘ggplot2’ ‘reshape2’ ‘fastcluster’
  ‘rtracklayer’ ‘Gviz’
Adding so many packages to the search path is excessive and importing
selectively is preferable.

checking installed package size ... NOTE
  installed size is 11.4Mb
  sub-directories of 1Mb or more:
    R         3.9Mb
    doc       1.6Mb
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
```

## etl (0.3.5)
Maintainer: Ben Baumer <ben.baumer@gmail.com>  
Bug reports: https://github.com/beanumber/etl/issues

1 error  | 1 warning  | 0 notes

```
checking tests ... ERROR
  Running ‘testthat.R’
Running the tests in ‘tests/testthat.R’ failed.
Last 13 lines of output:
  downloaded 11 KB
  
  trying URL 'http://www.nytimes.com'
  Content type 'text/html; charset=utf-8' length 225664 bytes (220 KB)
  ==================================================
  downloaded 220 KB
  
  testthat results ================================================================
  OK: 16 SKIPPED: 0 FAILED: 3
  1. Error: sqlite works (@test-etl.R#9) 
  2. Failure: dplyr works (@test-etl.R#25) 
  3. Error: MonetDBLite works (@test-etl.R#54) 
  
  Error: testthat unit tests failed
  Execution halted

checking Rd cross-references ... WARNING
Missing link or links in documentation object 'etl.Rd':
  ‘[dplyr]{src_sql}’

See section 'Cross-references' in the 'Writing R Extensions' manual.

```

## GeneAnswers (2.18.0)
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
     compacted ‘geneAnswers.pdf’ from 1374Kb to 600Kb
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

## GenomicFeatures (1.28.3)
Maintainer: Bioconductor Package Maintainer <maintainer@bioconductor.org>

1 error  | 1 warning  | 3 notes

```
checking examples ... ERROR
Running examples in ‘GenomicFeatures-Ex.R’ failed
The error most likely occurred in:

> base::assign(".ptime", proc.time(), pos = "CheckExEnv")
> ### Name: makeFeatureDbFromUCSC
> ### Title: Making a FeatureDb object from annotations available at the UCSC
> ###   Genome Browser
> ### Aliases: supportedUCSCFeatureDbTracks supportedUCSCFeatureDbTables
> ###   UCSCFeatureDbTableSchema makeFeatureDbFromUCSC
... 55 lines ...
+                               track="qPCR Primers",
+                               tablename="qPcrPrimers")
Download the qPcrPrimers table ... OK
Checking that required Columns are present ... 
OK
Prepare the 'metadata' data frame ... OK
Make the AnnoDb object ... 
Warning in rsqlite_fetch(res@ptr, n = n) :
  Don't need to call dbFetch() for statements, only for queries
Error: No value given for placeholder chrom, strand, chromStart, chromEnd, name, score, thickStart, thickEnd, itemRgb, blockCount, blockSizes, chromStarts, id, description
Execution halted

checking for missing documentation entries ... WARNING
Undocumented code objects:
  ‘exonicParts’ ‘intronicParts’
All user-level objects in a package should have documentation entries.
See chapter ‘Writing R documentation files’ in the ‘Writing R
Extensions’ manual.

checking package dependencies ... NOTE
Depends: includes the non-default packages:
  ‘BiocGenerics’ ‘S4Vectors’ ‘IRanges’ ‘GenomeInfoDb’ ‘GenomicRanges’
  ‘AnnotationDbi’
Adding so many packages to the search path is excessive and importing
selectively is preferable.

checking dependencies in R code ... NOTE
Unexported objects imported by ':::' calls:
  ‘biomaRt:::martBM’ ‘biomaRt:::martDataset’ ‘biomaRt:::martHost’
  ‘rtracklayer:::resourceDescription’ ‘rtracklayer:::ucscTableOutputs’
  See the note in ?`:::` about the use of this operator.

checking R code for possible problems ... NOTE
.writeMetadataFeatureTable: no visible global function definition for
  ‘packageDescription’
.writeMetadataTable: no visible global function definition for
  ‘packageDescription’
Undefined global functions or variables:
  packageDescription
Consider adding
  importFrom("utils", "packageDescription")
to your NAMESPACE file.
```

## liteq (1.0.0)
Maintainer: Gábor Csárdi <csardi.gabor@gmail.com>  
Bug reports: https://github.com/gaborcsardi/liteq/issues

1 error  | 0 warnings | 0 notes

```
checking tests ... ERROR
  Running ‘testthat.R’ [5s/30s]
Running the tests in ‘tests/testthat.R’ failed.
Last 13 lines of output:
  1. Failure: ensure_db (@test-db.R#12) ------------------------------------------
  ensure_db(db) produced warnings.
  
  
  2. Failure: ensure_queue (@test-queue.R#21) ------------------------------------
  q <- ensure_queue("foo", db = db) produced warnings.
  
  
  testthat results ================================================================
  OK: 506 SKIPPED: 0 FAILED: 2
  1. Failure: ensure_db (@test-db.R#12) 
  2. Failure: ensure_queue (@test-queue.R#21) 
  
  Error: testthat unit tests failed
  Execution halted
```

## lumi (2.28.0)
Maintainer: Pan Du <dupan.mail@gmail.com>, Lei Huang <lhuang@bsd.uchicago.edu>, Gang Feng <g-feng@northwestern.edu>

0 errors | 2 warnings | 3 notes

```
checking dependencies in R code ... WARNING
'::' or ':::' imports not declared from:
  ‘IRanges’ ‘bigmemoryExtras’

checking files in ‘vignettes’ ... WARNING
Files in the 'vignettes' directory but no files in 'inst/doc':
  ‘IlluminaAnnotation.R’, ‘IlluminaAnnotation.pdf’, ‘lumi.R’,
    ‘lumi.pdf’, ‘lumi_VST_evaluation.R’, ‘lumi_VST_evaluation.pdf’,
    ‘methylationAnalysis.R’, ‘methylationAnalysis.pdf’
Package has no Sweave vignette sources and no VignetteBuilder field.

checking installed package size ... NOTE
  installed size is  6.5Mb
  sub-directories of 1Mb or more:
    R      2.6Mb
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

## maGUI (2.2)
Maintainer: Dhammapal Bharne <dhammapalb@uohyd.ac.in>

1 error  | 0 warnings | 0 notes

```
checking whether package ‘maGUI’ can be installed ... ERROR
Installation failed.
See ‘/home/muelleki/git/R/RSQLite/revdep/checks/maGUI.Rcheck/00install.out’ for details.
```

## metagenomeFeatures (1.8.0)
Maintainer: Nathan D. Olson <nolson@umiacs.umd.edu>  
Bug reports: https://github.com/HCBravoLab/metagenomeFeatures/issues

1 error  | 0 warnings | 0 notes

```
checking whether package ‘metagenomeFeatures’ can be installed ... ERROR
Installation failed.
See ‘/home/muelleki/git/R/RSQLite/revdep/checks/metagenomeFeatures.Rcheck/00install.out’ for details.
```

## metaseqR (1.16.0)
Maintainer: Panagiotis Moulos <moulos@fleming.gr>

1 error  | 1 warning  | 4 notes

```
checking tests ... ERROR
  Running ‘runTests.R’ [21s/23s]
Running the tests in ‘tests/runTests.R’ failed.
Last 13 lines of output:
  ERROR in test_estimate_aufc_weights: Error in .check_ncores(cores) : 7 simultaneous processes spawned
  ERROR in test_metaseqr: Error in .check_ncores(cores) : 5 simultaneous processes spawned
  
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
7 simultaneous processes spawned
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

## mgsa (1.24.0)
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
  Found no call to: ‘R_useDynamicSymbols’

It is good practice to register native routines and to disable symbol
search.

See ‘Writing portable packages’ in the ‘Writing R Extensions’ manual.
```

## MonetDBLite (0.3.1)
Maintainer: Hannes Muehleisen <hannes@cwi.nl>  
Bug reports: https://github.com/hannesmuehleisen/MonetDBLite/issues

2 errors | 0 warnings | 3 notes

```
checking examples ... ERROR
Running examples in ‘MonetDBLite-Ex.R’ failed
The error most likely occurred in:

> base::assign(".ptime", proc.time(), pos = "CheckExEnv")
> ### Name: src_monetdb
> ### Title: dplyr integration from MonetDBLite
> ### Aliases: src_monetdb src_monetdblite tbl.src_monetdb
> ###   src_desc.src_monetdb src_translate_env.src_monetdb
> ###   sample_frac.tbl_monetdb sample_n.tbl_monetdb
... 18 lines ...

The following objects are masked from ‘package:base’:

    intersect, setdiff, setequal, union

> # Connection basics ---------------------------------------------------------
> # To connect to a database first create a src:
> dbdir <- file.path(tempdir(), "dplyrdir")
> my_db <- MonetDBLite::src_monetdb(embedded=dbdir)
Error: 'src_sql' is not an exported object from 'namespace:dplyr'
Execution halted

checking tests ... ERROR
  Running ‘testthat.R’ [17s/45s]
Running the tests in ‘tests/testthat.R’ failed.
Last 13 lines of output:
  1. Error: we can connect (@test_03_dplyr.R#15) 
  2. Error: dplyr copy_to() (@test_03_dplyr.R#27) 
  3. Error: dplyr tbl( sql() ) (@test_03_dplyr.R#35) 
  4. Error: dplyr select() (@test_03_dplyr.R#43) 
  5. Error: dplyr filter() (@test_03_dplyr.R#51) 
  6. Error: dplyr arrange() (@test_03_dplyr.R#59) 
  7. Error: dplyr mutate() (@test_03_dplyr.R#67) 
  8. Error: dplyr summarise() (@test_03_dplyr.R#75) 
  9. Error: dplyr multiple objects (@test_03_dplyr.R#84) 
  1. ...
  
  Error: testthat unit tests failed
  In addition: Warning message:
  call dbDisconnect() when finished working with a connection 
  Execution halted

checking installed package size ... NOTE
  installed size is  6.9Mb
  sub-directories of 1Mb or more:
    libs   6.6Mb

checking dependencies in R code ... NOTE
Missing or unexported objects:
  ‘dplyr::base_agg’ ‘dplyr::base_scalar’ ‘dplyr::base_win’
  ‘dplyr::build_sql’ ‘dplyr::is.ident’ ‘dplyr::sql_infix’
  ‘dplyr::sql_prefix’ ‘dplyr::sql_translator’ ‘dplyr::sql_variant’
  ‘dplyr::src_sql’ ‘dplyr::tbl_sql’

checking compiled code ... NOTE
File ‘MonetDBLite/libs/libmonetdb5.so’:
  Found no calls to: ‘R_registerRoutines’, ‘R_useDynamicSymbols’

It is good practice to register native routines and to disable symbol
search.

See ‘Writing portable packages’ in the ‘Writing R Extensions’ manual.
```

## oce (0.9-21)
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
  installed size is  5.5Mb
  sub-directories of 1Mb or more:
    help   2.1Mb
```

## oligoClasses (1.38.0)
Maintainer: Benilton Carvalho <beniltoncarvalho@gmail.com> and Robert Scharpf <rscharpf@jhsph.edu>

0 errors | 2 warnings | 4 notes

```
checking for missing documentation entries ... WARNING
Undocumented S4 methods:
  generic '[' and siglist 'CNSet,ANY,ANY,ANY'
  generic '[' and siglist 'gSetList,ANY,ANY,ANY'
All user-level objects in a package (including S4 classes and methods)
should have documentation entries.
See chapter ‘Writing R documentation files’ in the ‘Writing R
Extensions’ manual.

checking files in ‘vignettes’ ... WARNING
Files in the 'vignettes' directory but no files in 'inst/doc':
  ‘scriptsForExampleData/CreateExampleData.R’
Package has no Sweave vignette sources and no VignetteBuilder field.

checking package dependencies ... NOTE
Package which this enhances but not available for checking: ‘doRedis’

checking dependencies in R code ... NOTE
Unexported object imported by a ':::' call: ‘Biobase:::assayDataEnvLock’
  See the note in ?`:::` about the use of this operator.

checking R code for possible problems ... NOTE
addFeatureAnnotation.pd2: no visible global function definition for
  ‘dbGetQuery’
getSequenceLengths: no visible binding for global variable ‘seqlengths’
pdPkgFromBioC: no visible binding for global variable ‘contrib.url’
pdPkgFromBioC: no visible global function definition for
  ‘available.packages’
pdPkgFromBioC: no visible global function definition for
  ‘install.packages’
allele,SnpFeatureSet: no visible global function definition for
  ‘dbGetQuery’
chromosome,gSetList: no visible global function definition for
  ‘chromosomeList’
coerce,CNSet-CopyNumberSet: no visible global function definition for
  ‘totalCopynumber’
geometry,FeatureSet: no visible global function definition for ‘getPD’
initialize,DBPDInfo: no visible global function definition for
  ‘dbGetQuery’
Undefined global functions or variables:
  available.packages chromosomeList contrib.url dbGetQuery getPD
  install.packages seqlengths totalCopynumber
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

## oligo (1.40.1)
Maintainer: Benilton Carvalho <benilton@unicamp.br>

1 error  | 1 warning  | 9 notes

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
... 9 lines ...
+   data.frame(sampleNames(nimbleExpressionFS), groups)
+   MAplot(nimbleExpressionFS, pairs=TRUE, ylim=c(-.5, .5), groups=groups)
+ }
Loading required package: oligoData
Loading required package: pd.hg18.60mer.expr
Loading required package: RSQLite
Loading required package: DBI
Warning: call dbDisconnect() when finished working with a connection
Error in loadNamespace(name) : there is no package called ‘KernSmooth’
Calls: MAplot ... tryCatch -> tryCatchList -> tryCatchOne -> <Anonymous>
Execution halted

checking files in ‘vignettes’ ... WARNING
Files in the 'vignettes' directory newer than all files in 'inst/doc':
  ‘Makefile’

checking installed package size ... NOTE
  installed size is 30.2Mb
  sub-directories of 1Mb or more:
    R         1.1Mb
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

checking compiled code ... NOTE
File ‘oligo/libs/oligo.so’:
  Found no calls to: ‘R_registerRoutines’, ‘R_useDynamicSymbols’

It is good practice to register native routines and to disable symbol
search.

See ‘Writing portable packages’ in the ‘Writing R Extensions’ manual.
```

## Organism.dplyr (1.0.0)
Maintainer: Martin Morgan <martin.morgan@roswellpark.org>

1 error  | 0 warnings | 0 notes

```
checking whether package ‘Organism.dplyr’ can be installed ... ERROR
Installation failed.
See ‘/home/muelleki/git/R/RSQLite/revdep/checks/Organism.dplyr.Rcheck/00install.out’ for details.
```

## PAnnBuilder (1.40.0)
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

## plethy (1.14.0)
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
Processing /tmp/Rtmp9FbWp7/file116a39816e29 in chunks of 10000
Starting chunk 1
Reached breakpoint change
Processing breakpoint 1
Starting sample sample_1
Error in if (sum(which.gt) > 0) { : missing value where TRUE/FALSE needed
Calls: parse.buxco ... write.sample.breaks -> write.sample.db -> sanity.check.time
Execution halted

checking tests ... ERROR
  Running ‘runTests.R’ [24s/24s]
Running the tests in ‘tests/runTests.R’ failed.
Last 13 lines of output:
  Test files with failing tests
  
     test_check_helpers.R 
       test.add.labels.by.sample 
       test.dbImport 
       test.get.err.breaks 
       test.summaryMeasures 
  
  
  Error in BiocGenerics:::testPackage("plethy") : 
    unit tests failed for package plethy
  In addition: Warning message:
  In .Internal(gc(verbose, reset)) :
    closing unused connection 3 (/tmp/RtmpbNCrTz/file11fd5eb27935)
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

## poplite (0.99.17.3)
Maintainer: Daniel Bottomly <bottomly@ohsu.edu>

2 errors | 1 warning  | 0 notes

```
checking examples ... ERROR
Running examples in ‘poplite-Ex.R’ failed
The error most likely occurred in:

> base::assign(".ptime", proc.time(), pos = "CheckExEnv")
> ### Name: Database-class
> ### Title: Class '"Database"'
> ### Aliases: Database Database-class columns,Database-method dbFile
> ###   dbFile,Database-method populate populate,Database-method schema
> ###   schema,Database-method tables,Database-method isOpen,Database-method
... 26 lines ...
+  head(dbReadTable(examp.con, "team_franch"))
+  
+  dbDisconnect(examp.con)
+  
+ }
Loading required package: Lahman
Loading required package: RSQLite
Error in rsqlite_connection_valid(dbObj@ptr) : 
  external pointer is not valid
Calls: populate ... dbIsValid -> dbIsValid -> rsqlite_connection_valid -> .Call
Execution halted

checking tests ... ERROR
  Running ‘testthat.R’
Running the tests in ‘tests/testthat.R’ failed.
Last 13 lines of output:
  4: .local(obj, ...)
  5: isOpen(obj)
  6: isOpen(obj)
  7: dbIsValid(con@connection)
  8: dbIsValid(con@connection)
  9: rsqlite_connection_valid(dbObj@ptr) at /home/muelleki/git/R/RSQLite/R/SQLiteConnection.R:64
  
  testthat results ================================================================
  OK: 115 SKIPPED: 0 FAILED: 3
  1. Error: Database population (@test-poplite.R#452) 
  2. Error: Querying with Database objects (@test-poplite.R#567) 
  3. Error: sample tracking example but with direct keys between dna and samples (@test-poplite.R#801) 
  
  Error: testthat unit tests failed
  Execution halted

checking re-building of vignette outputs ... WARNING
Error in re-building vignettes:
  ...

The following objects are masked from ‘package:base’:

    intersect, setdiff, setequal, union

Loading required package: DBI

... 8 lines ...

    filter

Error in makeSchemaFromData(dna, "dna") : 
  ERROR: The names of the supplied data.frame need to be modified for the database see correct.df.names

Error: processing vignette 'poplite.Rnw' failed with diagnostics:
 chunk 8 
Error in rsqlite_connection_valid(dbObj@ptr) : 
  external pointer is not valid
Execution halted
```

## recoup (1.4.0)
Maintainer: Panagiotis Moulos <moulos@fleming.gr>

2 errors | 0 warnings | 1 note 

```
checking examples ... ERROR
Running examples in ‘recoup-Ex.R’ failed
The error most likely occurred in:

> base::assign(".ptime", proc.time(), pos = "CheckExEnv")
> ### Name: kmeansDesign
> ### Title: Apply k-means clustering to profile data
> ### Aliases: kmeansDesign
> 
> ### ** Examples
... 16 lines ...
+     rc=0.5
+ )
Getting main ranges for measurements
  measurement type: chipseq
  genomic region type: tss
Calculating requested regions coverage for WT H4K20me1
  processing chr12
Error in .check_ncores(cores) : 4 simultaneous processes spawned
Calls: recoup ... lapply -> FUN -> cmclapply -> mclapply -> .check_ncores
Execution halted
** found \donttest examples: check also with --run-donttest

checking tests ... ERROR
  Running ‘runTests.R’ [15s/16s]
Running the tests in ‘tests/runTests.R’ failed.
Last 13 lines of output:
  
   
  1 Test Suite : 
  recoup RUnit Tests - 1 test function, 1 error, 0 failures
  ERROR in test_recoup: Error in .check_ncores(cores) : 4 simultaneous processes spawned
  
  Test files with failing tests
  
     test_recoup.R 
       test_recoup 
  
  
  Error in BiocGenerics:::testPackage("recoup") : 
    unit tests failed for package recoup
  Execution halted

checking R code for possible problems ... NOTE
baseCoverageMatrix: no visible global function definition for
  ‘runValue’
baseCoverageMatrix : <anonymous>: no visible global function definition
  for ‘runValue’
binCoverageMatrix : <anonymous>: no visible global function definition
  for ‘runValue’
buildAnnotationStore: no visible global function definition for
  ‘Seqinfo’
calcCoverage: no visible global function definition for ‘runValue’
... 66 lines ...
recoupProfile: no visible binding for global variable ‘Design’
reduceExons : <anonymous>: no visible global function definition for
  ‘DataFrame’
splitVector: no visible global function definition for ‘Rle’
Undefined global functions or variables:
  Condition Coverage DataFrame Design IRanges Index Rle ScanBamParam
  Seqinfo Signal alphabetFrequency bamWhich<- biocLite dbConnect
  dbDisconnect dbDriver dbGetQuery dbWriteTable flankedSexon gene
  genomeRanges getBSgenome grid.text indexBam installed.genomes
  mclapply mcmapply runValue seqlevels seqlevels<- sexon sortBam
  subjectHits
```

## RImmPort (1.4.1)
Maintainer: Ravi Shankar <rshankar@stanford.edu>

0 errors | 1 warning  | 0 notes

```
checking sizes of PDF files under ‘inst/doc’ ... WARNING
  ‘gs+qpdf’ made some significant size reductions:
     compacted ‘RImmPort_Article.pdf’ from 735Kb to 339Kb
  consider running tools::compactPDF(gs_quality = "ebook") on these files
```

## RQDA (0.2-8)
Maintainer: HUANG Ronggui <ronggui.huang@gmail.com>

1 error  | 0 warnings | 1 note 

```
checking whether package ‘RQDA’ can be installed ... ERROR
Installation failed.
See ‘/home/muelleki/git/R/RSQLite/revdep/checks/RQDA.Rcheck/00install.out’ for details.

checking package dependencies ... NOTE
Package which this enhances but not available for checking: ‘rjpod’
```

## seqplots (1.13.0)
Maintainer: Przemyslaw Stempor <ps562@cam.ac.uk>  
Bug reports: http://github.com/przemol/seqplots/issues

2 errors | 0 warnings | 3 notes

```
checking examples ... ERROR
Running examples in ‘seqplots-Ex.R’ failed
The error most likely occurred in:

> base::assign(".ptime", proc.time(), pos = "CheckExEnv")
> ### Name: plotHeatmap
> ### Title: Plot heatmap with optional clustering
> ### Aliases: plotHeatmap plotHeatmap,PlotSetArray-method
> ###   plotHeatmap,PlotSetList-method plotHeatmap,PlotSetPair-method
> ###   plotHeatmap,list-method
... 22 lines ...
+     plotset1 <- getPlotSetArray(bw1, c(bed1, bed2), 'ce10')
+ } else {
+     load(system.file("extdata", "precalc_plotset.Rdata", package="seqplots"))
+ }
character
Error in close.connection(con) : invalid connection
Calls: <Anonymous> -> close -> close -> close.connection
Error in close.connection(file_con) : invalid connection
Calls: getPlotSetArray -> close -> close -> close.connection
Execution halted
** found \donttest examples: check also with --run-donttest

checking tests ... ERROR
  Running ‘test-all.R’ [25s/26s]
Running the tests in ‘tests/test-all.R’ failed.
Last 13 lines of output:
  Error in signalCondition(e) : 
    no function to return from, jumping to top level
  Calls: <Anonymous> ... close.connection -> .handleSimpleError -> h -> signalCondition
  testthat results ================================================================
  OK: 65 SKIPPED: 0 FAILED: 7
  1. Error: Test getPlotSetArray function and plotting interfaces (@test1.R#53) 
  2. Error: Test motifs (@test1.R#106) 
  3. Error: Test motifs (@test1.R#106) 
  4. Error: Test motifs (@test1.R#137) 
  5. Error: Test motifs (@test1.R#137) 
  6. Error: Test motifs (@test1.R#137) 
  7. Error: Test motifs (@test1.R#137) 
  
  Error: testthat unit tests failed
  Execution halted

checking installed package size ... NOTE
  installed size is  9.0Mb
  sub-directories of 1Mb or more:
    R          1.1Mb
    doc        2.4Mb
    seqplots   4.9Mb

checking foreign function calls ... NOTE
Foreign function call to a different package:
  .Call("BWGFile_summary", ..., PACKAGE = "rtracklayer")
See chapter ‘System and foreign language interfaces’ in the ‘Writing R
Extensions’ manual.

checking R code for possible problems ... NOTE
getPlotSetArray : <anonymous>: no visible global function definition
  for ‘qt’
getSF : <anonymous>: no visible global function definition for ‘approx’
ggHeatmapPlotWrapper: no visible global function definition for
  ‘colorRampPalette’
ggHeatmapPlotWrapper: no visible binding for global variable ‘Var2’
ggHeatmapPlotWrapper: no visible binding for global variable ‘Var1’
ggHeatmapPlotWrapper: no visible binding for global variable ‘value’
heatmapPlotWrapper: no visible global function definition for
... 42 lines ...
  capture.output colorRampPalette cutree dist hclust image kmeans
  layout lines mtext par plot.new qt rainbow rect rgb title value
Consider adding
  importFrom("grDevices", "adjustcolor", "colorRampPalette", "rainbow",
             "rgb")
  importFrom("graphics", "abline", "axis", "box", "image", "layout",
             "lines", "mtext", "par", "plot.new", "rect", "title")
  importFrom("stats", "approx", "as.dendrogram", "cutree", "dist",
             "hclust", "kmeans", "qt")
  importFrom("utils", "capture.output")
to your NAMESPACE file.
```

## sf (0.5-0)
Maintainer: Edzer Pebesma <edzer.pebesma@uni-muenster.de>  
Bug reports: https://github.com/edzer/sfr/issues/

1 error  | 0 warnings | 1 note 

```
checking tests ... ERROR
  Running ‘cast.R’
  Comparing ‘cast.Rout’ to ‘cast.Rout.save’ ...4c4
< Linking to GEOS 3.5.0, GDAL 2.1.0, proj.4 4.9.2
---
> Linking to GEOS 3.5.1, GDAL 2.1.3, proj.4 4.9.2
  Running ‘crs.R’
  Comparing ‘crs.Rout’ to ‘crs.Rout.save’ ... OK
  Running ‘dist.R’
  Comparing ‘dist.Rout’ to ‘dist.Rout.save’ ... OK
... 8 lines ...
  # A tibble: 1 x 2
    `sum(A * new_dens)`          geometry
                <units>  <simple_feature>
  1       329962 person <MULTIPOLYGON...>
  > 
  > conn = system.file("gpkg/nc.gpkg", package = "sf")
  > db = src_sqlite(conn)
  > tbl(db, "nc.gpkg") %>% filter(AREA > 0.2) %>% collect %>% st_sf
  Error in st_sf(.) : no simple features geometry column present
  Calls: %>% ... _fseq -> freduce -> withVisible -> <Anonymous> -> st_sf
  Execution halted

checking installed package size ... NOTE
  installed size is 13.0Mb
  sub-directories of 1Mb or more:
    doc      4.0Mb
    libs     5.4Mb
    sqlite   1.5Mb
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
... 6 lines ...
> # in R without SQL and then again with SQL
> #
> 
> # head
> a1r <- head(warpbreaks)
> a1s <- sqldf("select * from warpbreaks limit 6")
Loading required package: tcltk
Error in rsqlite_send_query(conn@ptr, statement) : 
  no such table: warpbreaks
Calls: sqldf ... initialize -> initialize -> rsqlite_send_query -> .Call
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

## taxizedb (0.1.0)
Maintainer: Scott Chamberlain <myrmecocystus+r@gmail.com>  
Bug reports: https://github.com/ropensci/taxizedb/issues

1 error  | 0 warnings | 0 notes

```
checking tests ... ERROR
  Running ‘test-all.R’
Running the tests in ‘tests/test-all.R’ failed.
Complete output:
  > library(testthat)
  > test_check("taxizedb")
  Loading required package: taxizedb
  1. Failure: sql_collect works (@test-sql_collect.R#9) --------------------------
  `src` inherits from `src_dbi/src_sql/src` not `src_sqlite`.
  
  
  testthat results ================================================================
  OK: 34 SKIPPED: 4 FAILED: 1
  1. Failure: sql_collect works (@test-sql_collect.R#9) 
  
  Error: testthat unit tests failed
  Execution halted
```

## TFBSTools (1.14.0)
Maintainer: Ge Tan <ge.tan09@imperial.ac.uk>  
Bug reports: https://github.com/ge11232002/TFBSTools/issues

2 errors | 1 warning  | 4 notes

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
... 62 lines ...
+       11,  0,  9,  0,  0,  0,  0, 52,  1,  6, 15, 20)),
+     nrow=4, byrow=TRUE, dimnames=list(DNA_BASES))
>   pfmQuery <- PFMatrix(profileMatrix=profileMatrix)
>   pfmSubjects <- getMatrixSet(JASPAR2016,
+                               opts=list(ID=c("MA0500", "MA0499", "MA0521",
+                                              "MA0697", "MA0048", "MA0751",
+                                              "MA0832")))
Error in dbGetQuery(con, sqlCMD) : could not find function "dbGetQuery"
Calls: getMatrixSet ... getMatrixSet -> .get_IDlist_by_query -> .get_latest_version
Execution halted
** found \donttest examples: check also with --run-donttest

checking tests ... ERROR
  Running ‘testthat.R’ [21s/21s]
Running the tests in ‘tests/testthat.R’ failed.
Last 13 lines of output:
  1: getMatrixSet(JASPAR2016, opts = list(ID = c("MA0500", "MA0499", "MA0521", "MA0697"))) at testthat/test_PFM.R:11
  2: getMatrixSet(JASPAR2016, opts = list(ID = c("MA0500", "MA0499", "MA0521", "MA0697")))
  3: getMatrixSet(x@db, opts)
  4: getMatrixSet(x@db, opts)
  5: getMatrixSet(con, opts)
  6: getMatrixSet(con, opts)
  7: .get_IDlist_by_query(x, opts)
  8: .get_latest_version(con, baseID)
  
  testthat results ================================================================
  OK: 29 SKIPPED: 0 FAILED: 1
  1. Error: test_PFMSimilarity (@test_PFM.R#11) 
  
  Error: testthat unit tests failed
  Execution halted

checking re-building of vignette outputs ... WARNING
Error in re-building vignettes:
  ...

No methods found in "RSQLite" for requests: dbGetQuery
No methods found in "RSQLite" for requests: dbGetQuery
Quitting from lines 213-226 (TFBSTools.Rmd) 
Error: processing vignette 'TFBSTools.Rmd' failed with diagnostics:
could not find function "dbGetQuery"
Execution halted


checking installed package size ... NOTE
  installed size is 12.7Mb
  sub-directories of 1Mb or more:
    R  11.9Mb

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

checking compiled code ... NOTE
File ‘TFBSTools/libs/TFBSTools.so’:
  Found no call to: ‘R_useDynamicSymbols’

It is good practice to register native routines and to disable symbol
search.

See ‘Writing portable packages’ in the ‘Writing R Extensions’ manual.
```

## TSdata (2016.8-1)
Maintainer: Paul Gilbert <pgilbert.ttv9z@ncf.ca>

0 errors | 1 warning  | 0 notes

```
checking re-building of vignette outputs ... WARNING
Error in re-building vignettes:
  ...
INFO: Contacting web service with query: https://stats.oecd.org/restsdmx/sdmx.ashx/GetData/QNA/CAN+USA+MEX.B1_GE.CARSA.Q?format=compact_v2
Jun 17, 2017 6:52:04 PM it.bancaditalia.oss.sdmx.client.RestSdmxClient runQuery
INFO: Contacting web service with query: http://ec.europa.eu/eurostat/SDMX/diss-web/rest/dataflow/ESTAT/ei_nama_q/latest
Jun 17, 2017 6:52:04 PM it.bancaditalia.oss.sdmx.client.RestSdmxClient runQuery
INFO: Contacting web service with query: http://ec.europa.eu/eurostat/SDMX/diss-web/rest/dataflow/ESTAT/ei_nama_q/latest
Jun 17, 2017 6:52:04 PM it.bancaditalia.oss.sdmx.client.RestSdmxClient runQuery
INFO: Contacting web service with query: http://ec.europa.eu/eurostat/SDMX/diss-web/rest/datastructure/ESTAT/DSD_ei_nama_q/1.0
... 8 lines ...
INFO: The sdmx call returned messages in the footer:
 Message [code=400, severity=Error, url=null, text=[Error caused by the caller due to incorrect or semantically invalid arguments]]
Jun 17, 2017 6:52:04 PM it.bancaditalia.oss.sdmx.client.RestSdmxClient getData
INFO: The sdmx call returned messages in the footer:
 Message [code=400, severity=Error, url=null, text=[Error caused by the caller due to incorrect or semantically invalid arguments]]

Error: processing vignette 'Guide.Stex' failed with diagnostics:
 chunk 5 
Error in .local(serIDs, con, ...) : 
  ei_nama_q.Q.MIO-EUR.NSA.CP.NA-P72.IT error: it.bancaditalia.oss.sdmx.exceptions.SdmxXmlContentException: The query: ei_nama_q.Q.MIO-EUR.NSA.CP.NA-P72.IT did not match any time series on the provider.
Execution halted
```

## VariantFiltering (1.12.1)
Maintainer: Robert Castelo <robert.castelo@upf.edu>  
Bug reports: https://github.com/rcastelo/VariantFiltering/issues

0 errors | 1 warning  | 4 notes

```
checking sizes of PDF files under ‘inst/doc’ ... WARNING
  ‘gs+qpdf’ made some significant size reductions:
     compacted ‘usingVariantFiltering.pdf’ from 415Kb to 154Kb
  consider running tools::compactPDF(gs_quality = "ebook") on these files

checking installed package size ... NOTE
  installed size is  8.0Mb
  sub-directories of 1Mb or more:
    R         3.7Mb
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

checking compiled code ... NOTE
File ‘VariantFiltering/libs/VariantFiltering.so’:
  Found no call to: ‘R_useDynamicSymbols’

It is good practice to register native routines and to disable symbol
search.

See ‘Writing portable packages’ in the ‘Writing R Extensions’ manual.
```

## vmsbase (2.1.3)
Maintainer: Lorenzo D'Andrea <support@vmsbase.org>

1 error  | 0 warnings | 0 notes

```
checking whether package ‘vmsbase’ can be installed ... ERROR
Installation failed.
See ‘/home/muelleki/git/R/RSQLite/revdep/checks/vmsbase.Rcheck/00install.out’ for details.
```

