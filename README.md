# RSQLite

RSQLite embeds the SQLite database engine in R, providing a DBI-compliant interface. [SQLite](http://www.sqlite.org) is a public-domain, single-user, very light-weight database engine that implements a decent subset of the SQL 92 standard, including the core table creation, updating, insertion, and selection operations, plus transaction management.

You can install the latest released version from CRAN with:

```r
install.packages("RSQLite")
```

or install the latest development version from github with:

```r
library(devtools)
install_github("RSQLite", "rstats-dbi")
```

To install from github, you'll need a [development environment](http://www.rstudio.com/ide/docs/packages/prerequisites)).

## Acknowledgements

Many thanks to Doug Bates, Seth Falcon, Detlef Groth, Ronggui Huang,
Kurt Hornik, Uwe Ligges, Charles Loboz, Duncan Murdoch, and Brian
D. Ripley for comments, suggestions, bug reports, and/or patches.

