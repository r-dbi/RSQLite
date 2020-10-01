<!-- README.md is generated from README.Rmd. Please edit that file -->

# RSQLite

<!-- badges: start -->

[![Lifecycle: stable](https://img.shields.io/badge/lifecycle-stable-brightgreen.svg)](https://www.tidyverse.org/lifecycle/#stable) [![Build Status](https://travis-ci.com/r-dbi/RSQLite.png?branch=master)](https://travis-ci.com/github/r-dbi/RSQLite) [![AppVeyor Build Status](https://ci.appveyor.com/api/projects/status/github/r-dbi/RSQLite?branch=master&svg=true)](https://ci.appveyor.com/project/r-dbi/RSQLite) [![Coverage Status](https://codecov.io/gh/r-dbi/RSQLite/branch/master/graph/badge.svg)](https://codecov.io/github/r-dbi/RSQLite?branch=master) [![CRAN status](https://www.r-pkg.org/badges/version/RSQLite)](https://cran.r-project.org/package=RSQLite) [![CII Best Practices](https://bestpractices.coreinfrastructure.org/projects/3234/badge)](https://bestpractices.coreinfrastructure.org/projects/3234)

<!-- badges: end -->

Embeds the SQLite database engine in R, providing a DBI-compliant interface. [SQLite](https://www.sqlite.org/index.html) is a public-domain, single-user, very light-weight database engine that implements a decent subset of the SQL 92 standard, including the core table creation, updating, insertion, and selection operations, plus transaction management.

You can install the latest released version from CRAN with:

<pre class='chroma'>
<span class='nf'><a href='https://rdrr.io/r/utils/install.packages.html'>install.packages</a></span>(<span class='s'>"RSQLite"</span>)
</pre>

Or install the latest development version from GitHub with:

<pre class='chroma'>
<span class='c'># install.packages("devtools")</span>
<span class='k'>devtools</span>::<span class='nf'><a href='https://devtools.r-lib.org//reference/remote-reexports.html'>install_github</a></span>(<span class='s'>"r-dbi/RSQLite"</span>)
</pre>

<!-- https://www.rstudio.com/ide/docs/packages/prerequisites -->

To install from GitHub, you’ll need a [development environment](https://support.rstudio.com/hc/en-us/articles/200486498-Package-Development-Prerequisites).

Discussions associated with DBI and related database packages take place on [R-SIG-DB](https://stat.ethz.ch/mailman/listinfo/r-sig-db). The website [Databases using R](https://db.rstudio.com/) describes the tools and best practices in this ecosystem.

## Basic usage

<pre class='chroma'>
<span class='nf'><a href='https://rdrr.io/r/base/library.html'>library</a></span>(<span class='k'><a href='https://dbi.r-dbi.org'>DBI</a></span>)
<span class='c'># Create an ephemeral in-memory RSQLite database</span>
<span class='k'>con</span> <span class='o'>&lt;-</span> <span class='nf'><a href='https://dbi.r-dbi.org/reference/dbConnect.html'>dbConnect</a></span>(<span class='k'>RSQLite</span>::<span class='nf'><a href='https://rsqlite.r-dbi.org/reference/SQLite.html'>SQLite</a></span>(), <span class='s'>":memory:"</span>)

<span class='nf'><a href='https://dbi.r-dbi.org/reference/dbListTables.html'>dbListTables</a></span>(<span class='k'>con</span>)
</pre>

<pre class='chroma'>
<span class='c'>## character(0)</span>
</pre>

<pre class='chroma'>
<span class='nf'><a href='https://dbi.r-dbi.org/reference/dbWriteTable.html'>dbWriteTable</a></span>(<span class='k'>con</span>, <span class='s'>"mtcars"</span>, <span class='k'>mtcars</span>)
<span class='nf'><a href='https://dbi.r-dbi.org/reference/dbListTables.html'>dbListTables</a></span>(<span class='k'>con</span>)
</pre>

<pre class='chroma'>
<span class='c'>## [1] "mtcars"</span>
</pre>

<pre class='chroma'>
<span class='nf'><a href='https://dbi.r-dbi.org/reference/dbListFields.html'>dbListFields</a></span>(<span class='k'>con</span>, <span class='s'>"mtcars"</span>)
</pre>

<pre class='chroma'>
<span class='c'>##  [1] "mpg"  "cyl"  "disp" "hp"   "drat" "wt"   "qsec" "vs"   "am"   "gear"</span>
<span class='c'>## [11] "carb"</span>
</pre>

<pre class='chroma'>
<span class='nf'><a href='https://dbi.r-dbi.org/reference/dbReadTable.html'>dbReadTable</a></span>(<span class='k'>con</span>, <span class='s'>"mtcars"</span>)
</pre>

<pre class='chroma'>
<span class='c'>##    mpg cyl  disp  hp drat    wt  qsec vs am gear carb</span>
<span class='c'>## 1 21.0   6 160.0 110 3.90 2.620 16.46  0  1    4    4</span>
<span class='c'>## 2 21.0   6 160.0 110 3.90 2.875 17.02  0  1    4    4</span>
<span class='c'>## 3 22.8   4 108.0  93 3.85 2.320 18.61  1  1    4    1</span>
<span class='c'>## 4 21.4   6 258.0 110 3.08 3.215 19.44  1  0    3    1</span>
<span class='c'>## 5 18.7   8 360.0 175 3.15 3.440 17.02  0  0    3    2</span>
<span class='c'>## 6 18.1   6 225.0 105 2.76 3.460 20.22  1  0    3    1</span>
<span class='c'>## 7 14.3   8 360.0 245 3.21 3.570 15.84  0  0    3    4</span>
<span class='c'>## 8 24.4   4 146.7  62 3.69 3.190 20.00  1  0    4    2</span>
<span class='c'>## 9 22.8   4 140.8  95 3.92 3.150 22.90  1  0    4    2</span>
<span class='c'>##  [ reached 'max' / getOption("max.print") -- omitted 23 rows ]</span>
</pre>

<pre class='chroma'>
<span class='c'># You can fetch all results:</span>
<span class='k'>res</span> <span class='o'>&lt;-</span> <span class='nf'><a href='https://dbi.r-dbi.org/reference/dbSendQuery.html'>dbSendQuery</a></span>(<span class='k'>con</span>, <span class='s'>"SELECT * FROM mtcars WHERE cyl = 4"</span>)
<span class='nf'><a href='https://dbi.r-dbi.org/reference/dbFetch.html'>dbFetch</a></span>(<span class='k'>res</span>)
</pre>

<pre class='chroma'>
<span class='c'>##    mpg cyl  disp hp drat    wt  qsec vs am gear carb</span>
<span class='c'>## 1 22.8   4 108.0 93 3.85 2.320 18.61  1  1    4    1</span>
<span class='c'>## 2 24.4   4 146.7 62 3.69 3.190 20.00  1  0    4    2</span>
<span class='c'>## 3 22.8   4 140.8 95 3.92 3.150 22.90  1  0    4    2</span>
<span class='c'>## 4 32.4   4  78.7 66 4.08 2.200 19.47  1  1    4    1</span>
<span class='c'>## 5 30.4   4  75.7 52 4.93 1.615 18.52  1  1    4    2</span>
<span class='c'>## 6 33.9   4  71.1 65 4.22 1.835 19.90  1  1    4    1</span>
<span class='c'>## 7 21.5   4 120.1 97 3.70 2.465 20.01  1  0    3    1</span>
<span class='c'>## 8 27.3   4  79.0 66 4.08 1.935 18.90  1  1    4    1</span>
<span class='c'>## 9 26.0   4 120.3 91 4.43 2.140 16.70  0  1    5    2</span>
<span class='c'>##  [ reached 'max' / getOption("max.print") -- omitted 2 rows ]</span>
</pre>

<pre class='chroma'>
<span class='nf'><a href='https://dbi.r-dbi.org/reference/dbClearResult.html'>dbClearResult</a></span>(<span class='k'>res</span>)

<span class='c'># Or a chunk at a time</span>
<span class='k'>res</span> <span class='o'>&lt;-</span> <span class='nf'><a href='https://dbi.r-dbi.org/reference/dbSendQuery.html'>dbSendQuery</a></span>(<span class='k'>con</span>, <span class='s'>"SELECT * FROM mtcars WHERE cyl = 4"</span>)
<span class='kr'>while</span>(<span class='o'>!</span><span class='nf'><a href='https://dbi.r-dbi.org/reference/dbHasCompleted.html'>dbHasCompleted</a></span>(<span class='k'>res</span>)){
  <span class='k'>chunk</span> <span class='o'>&lt;-</span> <span class='nf'><a href='https://dbi.r-dbi.org/reference/dbFetch.html'>dbFetch</a></span>(<span class='k'>res</span>, n = <span class='m'>5</span>)
  <span class='nf'><a href='https://rdrr.io/r/base/print.html'>print</a></span>(<span class='nf'><a href='https://rdrr.io/r/base/nrow.html'>nrow</a></span>(<span class='k'>chunk</span>))
}
</pre>

<pre class='chroma'>
<span class='c'>## [1] 5</span>
<span class='c'>## [1] 5</span>
<span class='c'>## [1] 1</span>
</pre>

<pre class='chroma'>
<span class='c'># Clear the result</span>
<span class='nf'><a href='https://dbi.r-dbi.org/reference/dbClearResult.html'>dbClearResult</a></span>(<span class='k'>res</span>)

<span class='c'># Disconnect from the database</span>
<span class='nf'><a href='https://dbi.r-dbi.org/reference/dbDisconnect.html'>dbDisconnect</a></span>(<span class='k'>con</span>)
</pre>

## Acknowledgements

Many thanks to Doug Bates, Seth Falcon, Detlef Groth, Ronggui Huang, Kurt Hornik, Uwe Ligges, Charles Loboz, Duncan Murdoch, and Brian D. Ripley for comments, suggestions, bug reports, and/or patches.

-----

Please note that the ‘RSQLite’ project is released with a [Contributor Code of Conduct](https://rsqlite.r-dbi.org/code_of_conduct). By contributing to this project, you agree to abide by its terms.
