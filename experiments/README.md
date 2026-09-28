# `experiments/`: measured evidence

*The conventions of this directory are those of
[`cynkra/handbook-tools`](https://github.com/cynkra/handbook-tools/blob/main/handbook/meta/experiments/README.md).*

One directory per experiment, holding everything it needs:
a `README.md` that says what was measured, when, on what, and which documentation relies on it,
plus whatever the run took: scripts, inputs, recorded output.
Nothing here runs on its own, and nothing here gates a merge.

This file names the contents, so nothing here is an orphan.

* [`2026-09-26-arrow-df-fetch/`](2026-09-26-arrow-df-fetch/):
  wall time and peak memory of fetching a large table into a data frame,
  on the default path and through Arrow, per fetch strategy;
  supports the `arrow` argument of `dbConnect()` in
  [`R/dbConnect_SQLiteDriver.R`](/R/dbConnect_SQLiteDriver.R).

Adding one: create the directory, name it for the date and the topic,
open its `README.md` with what and when and on what,
and link it from the documentation that relies on it.
