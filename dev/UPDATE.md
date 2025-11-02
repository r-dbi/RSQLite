# Updates

Two components are shipped with the package that can be updated:

- SQLite library
- Datasets database

Ideally the update should happen right *after* each CRAN release, so
that a new SQLite version is tested for some time before it’s released
to CRAN.

## SQLite library

1.  Download latest SQLite source by running `data-raw/upgrade.R`

2.  Update `DESCRIPTION` for included version of SQLite

3.  Update `NEWS`

## Datasets database

RSQLite includes one SQLite database (accessible from
[`datasetsDb()`](https://rsqlite.r-dbi.org/dev/reference/datasetsDb.md)
that contains all data frames in the datasets package. The code that
created it is located in `data-raw/datasets.R`.
