# Fetching a large table into a data frame: the default path against Arrow

*What it measures:* how long it takes to move a query result from SQLite into an R data frame,
and the peak memory of the move, per fetch strategy,
for a table whose row count the fetch cannot know in advance:
SQLite reports no count before the last step, so every column has to grow as the rows arrive.
The question behind it is whether `dbConnect(arrow = TRUE)`,
which routes every data frame through the Arrow arrays that `dbFetchArrowChunk()` fills,
can carry the data frames of RSQLite without a cost in time or memory.

*When and on what:* 2026-09-26, an Ubuntu 24.04 container (x86_64, 4 cores),
R 4.5.3, the vendored SQLite 3.53.4, nanoarrow 0.9.0,
on two states of [#796](https://github.com/r-dbi/RSQLite/pull/796):
`83bb24e`, the head before the fixes it motivated, and `75ea617`, the commit with them.
A synthetic table of one million rows (three repetitions) and of five million rows (two), medians reported.
The harness is [`bench.R`](bench.R), and the runs are the four CSV files beside it.

*What it supports:* the `arrow` argument of `dbConnect()` in
[`R/dbConnect_SQLiteDriver.R`](/R/dbConnect_SQLiteDriver.R),
and the sections on data frames and chunking of `?sqlite-arrow` in [`R/arrow.R`](/R/arrow.R).

## The harness

[`bench.R`](bench.R): one file, DBI, RSQLite, nanoarrow and callr.

* Data: a deterministic table `t (id INTEGER, n INTEGER, x REAL, s TEXT, t TEXT)`:
  a row number, an integer with 10 % NULLs, a real in [0, 1),
  a seven-character key drawn from 100,000 values,
  and a three-word string of about 30 characters with 20 % NULLs.
* Isolation: every strategy × query cell runs in a fresh R subprocess,
  and its peak RSS is the `VmHWM` of that process, which includes the floor
  that R, the packages and the connection take (the `baseline` strategy measures it).
* Strategies:
  `default` (`dbGetQuery()` on a default connection),
  `arrow_df` (`dbGetQuery()` on `dbConnect(arrow = TRUE)`),
  `arrow_stream` (`as.data.frame(dbGetQueryArrow())`, nanoarrow's own conversion),
  `default_chunked` and `arrow_df_chunked` (`dbSendQuery()` and a `dbFetch(n = 10000)` loop that discards its batches),
  `arrow_drain` (`dbSendQueryArrow()` and a `dbFetchArrowChunk(chunk_size = 10000)` loop that converts nothing),
  `baseline` (the query behind `LIMIT 0`).
* Queries: `all` (`SELECT * FROM t`), `numbers` (the three numeric columns),
  `strings` (the two text columns), `filtered` (`SELECT * FROM t WHERE x < 0.3`, about a third of the rows).

Run it:

```sh
Rscript bench.R --rows=1000000 --reps=3 --out=results-<build>-1e6.csv
Rscript bench.R --rows=5000000 --reps=2 --out=results-<build>-5e6.csv
```

## The runs

The build under test is the RSQLite installed in the library the script runs with.

* [`results-pr796-83bb24e-1e6.csv`](results-pr796-83bb24e-1e6.csv) and
  [`results-pr796-83bb24e-5e6.csv`](results-pr796-83bb24e-5e6.csv):
  the head of the pull request before the fixes,
  where `dbFetch()` handed the arrays to `nanoarrow::convert_array_stream()` and `convert_array()` as they were.
* [`results-pr796-75ea617-1e6.csv`](results-pr796-75ea617-1e6.csv) and
  [`results-pr796-75ea617-5e6.csv`](results-pr796-75ea617-5e6.csv):
  the commit with the fixes.

Timings move by about 10 % between repetitions on this shared container:
read them as shape, not to two decimals.

### Five million rows, before the fixes (`83bb24e`)

| query | strategy | seconds | peak RSS MB | above floor MB | data frame MB |
|---|---|---:|---:|---:|---:|
| all | default | 18.47 | 779 | 679 | 411 |
| all | arrow_df | 14.01 | 1181 | 1081 | 411 |
| all | arrow_stream | 12.09 | 1050 | 950 | 449 |
| all | default_chunked | 9.05 | 199 | 99 | |
| all | arrow_df_chunked | 3.54 | 330 | 230 | |
| all | arrow_drain | 3.58 | 466 | 366 | |
| numbers | default | 3.33 | 255 | 154 | 76 |
| numbers | arrow_df | 2.67 | 489 | 389 | 76 |
| numbers | arrow_stream | 1.90 | 336 | 236 | 114 |
| numbers | default_chunked | 3.39 | 160 | 60 | |
| numbers | arrow_df_chunked | 2.50 | 191 | 91 | |
| numbers | arrow_drain | 1.89 | 269 | 168 | |
| strings | default | 13.44 | 635 | 534 | 334 |
| strings | arrow_df | 10.76 | 751 | 650 | 334 |
| strings | arrow_stream | 10.25 | 751 | 651 | 334 |
| strings | default_chunked | 6.31 | 192 | 92 | |
| strings | arrow_df_chunked | 1.97 | 341 | 240 | |
| strings | arrow_drain | 1.89 | 345 | 245 | |
| filtered | default | 4.84 | 316 | 215 | 141 |
| filtered | arrow_df | 3.84 | 444 | 343 | 141 |
| filtered | arrow_stream | 3.65 | 408 | 307 | 152 |
| filtered | default_chunked | 2.92 | 179 | 79 | |
| filtered | arrow_df_chunked | 1.67 | 258 | 158 | |
| filtered | arrow_drain | 1.38 | 223 | 123 | |

The floor is 100 MB in every cell.
The one-million-row run has the same shape at a fifth of the size.

### Five million rows, with the fixes (`75ea617`)

| query | strategy | seconds | peak RSS MB | above floor MB | data frame MB |
|---|---|---:|---:|---:|---:|
| all | default | 17.78 | 779 | 679 | 411 |
| all | arrow_df | 12.07 | 923 | 823 | 411 |
| all | arrow_stream | 11.55 | 1049 | 949 | 449 |
| all | default_chunked | 9.47 | 199 | 99 | |
| all | arrow_df_chunked | 7.10 | 231 | 131 | |
| all | arrow_drain | 3.05 | 214 | 113 | |
| numbers | default | 3.32 | 255 | 155 | 76 |
| numbers | arrow_df | 2.14 | 361 | 261 | 76 |
| numbers | arrow_stream | 1.95 | 337 | 236 | 114 |
| numbers | default_chunked | 3.19 | 160 | 60 | |
| numbers | arrow_df_chunked | 2.03 | 182 | 82 | |
| numbers | arrow_drain | 1.78 | 201 | 101 | |
| strings | default | 13.15 | 635 | 535 | 334 |
| strings | arrow_df | 9.13 | 664 | 564 | 334 |
| strings | arrow_stream | 9.45 | 751 | 651 | 334 |
| strings | default_chunked | 6.85 | 192 | 92 | |
| strings | arrow_df_chunked | 5.66 | 221 | 121 | |
| strings | arrow_drain | 1.83 | 209 | 108 | |
| filtered | default | 4.90 | 316 | 215 | 141 |
| filtered | arrow_df | 3.43 | 380 | 280 | 141 |
| filtered | arrow_stream | 3.46 | 407 | 307 | 152 |
| filtered | default_chunked | 3.06 | 179 | 79 | |
| filtered | arrow_df_chunked | 2.55 | 214 | 113 | |
| filtered | arrow_drain | 1.42 | 194 | 94 | |

At one million rows, the full fetch of `all` takes 1.9 s against 2.8 s on the default path,
at 180 against 150 MB above the floor, and the other cells scale the same way.

## What the numbers say

* **A full fetch through Arrow takes about a third less time than on the default path**,
  on every query and at both sizes:
  12.1 against 17.8 s for `all`, 9.1 against 13.2 s for the strings, 2.1 against 3.3 s for the numbers,
  3.4 against 4.9 s for the filtered third.
  The default path grows every column as the rows arrive and converts cell by cell;
  the Arrow path fills fixed-size arrays and lets nanoarrow convert them in bulk.
* **Before the fixes, a full fetch through Arrow held the result twice.**
  `nanoarrow::convert_array_stream()` collects every array of a stream of unknown size before it converts,
  so the arrays and the data frame coexisted: 1,081 MB above the floor for `all`, against 679 MB on the default path.
  Fetching the arrays first in C++ and converting them one by one, each freed once copied,
  brought that to 823 MB, with the strings at 564 against 535 MB.
  What remains is the result held in Arrow form while the columns fill, where an integer takes 8 bytes,
  and the copy that the `int64` to `integer` step makes; the numbers query pays most for it (261 against 155 MB).
* **A chunked fetch through Arrow now stays flat and is faster than the default chunked fetch:**
  7.1 s and 131 MB against 9.5 s and 99 MB for `all` in chunks of 10,000 rows.
  Before the fixes, the chunks came back at 3.5 s but 230 MB and growing:
  nanoarrow's character vectors read from the Arrow array until they are touched,
  so every chunk stayed alive behind its data frame until the garbage collector ran,
  and the earlier time never paid for materializing the strings.
  Copying the strings out of each array and freeing it right away makes the comparison like for like.
* **A loop over `dbFetchArrowChunk()` that discards its chunks no longer piles them up.**
  The collector does not see the memory nanoarrow allocates, so `arrow_drain` grew to 366 MB above the floor,
  the whole result as garbage.
  A collection of the young generation after every 64 MB of arrays handed out keeps it at 113 MB,
  at no cost in time (3.05 against 3.58 s).
* **`as.data.frame(dbGetQueryArrow())` is the same speed but not the same data frame:**
  nanoarrow's own conversion collects the arrays first (949 MB above the floor for `all`)
  and turns `int64` columns into doubles, which lose precision above 2^53 without a warning,
  where RSQLite's conversion gives integers where they fit and `integer64` otherwise.
* **The floor is 100 MB** in every cell: R, the packages and an open connection, before the first row.
  Peak RSS repeats to the MB between repetitions of the same cell; timings move by about 10 %.

To refresh: install the build of interest, run the two commands above, and commit the CSV files named after it.
