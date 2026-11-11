# Vendored nanoarrow

`nanoarrow.c`, `nanoarrow.h` and `nanoarrow.hpp` are the bundled sources of the
Apache Arrow nanoarrow library, version 0.9.0, copied unchanged from the `src/`
directory of the nanoarrow R package's CRAN sources (`nanoarrow_0.9.0.tar.gz`).
`LICENSE.txt` and `NOTICE.txt` come from the nanoarrow release tarball.

The single delta is the line `#define NANOARROW_NAMESPACE RSQLite` in
`nanoarrow.h` (upstream: `RPkg`), which prefixes the library's exported symbols
so that they cannot collide with the copy inside the nanoarrow package.

To update: download the CRAN sources of the new nanoarrow version, copy the
three files over these, reapply the namespace line, and rebuild.
The R-side exchange helpers (`nanoarrow/r.h`) are not vendored; they come from
`LinkingTo: nanoarrow`.
