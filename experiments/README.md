# `experiments/`: measured evidence

*Conventions: [`meta/experiments/`](https://github.com/cynkra/handbook-tools/blob/main/handbook/meta/experiments/README.md)
in cynkra/handbook-tools owns this directory's conventions.
This repository has no handbook, so a record supports an issue instead of a handbook leaf.*

One directory per experiment, holding everything it needs:
a `README.md` that says what was measured, when, on what, and which issue relies on it,
plus whatever the run took: scripts, inputs, recorded output.
Nothing here runs on its own or gates a merge, and `.Rbuildignore` leaves the directory out of the package.

This file is what names the contents, so nothing here is an orphan.
The change that adds a directory adds its line below: the name, what it measured, and the issue it supports.

<!-- One bullet per directory, newest last:
     * [`YYYY-MM-DD-topic/`](YYYY-MM-DD-topic/): what it measured, in one clause;
       supports [#NNN](https://github.com/r-dbi/RSQLite/issues/NNN). -->

* [`2026-11-11-incremental-build-vendor/`](2026-11-11-incremental-build-vendor/):
  whether an incremental build recompiles `ext-http.o` after an edit to the vendored `src/vendor/extensions/http.c`;
  supports [#836](https://github.com/r-dbi/RSQLite/issues/836).
