# Vendored nanoarrow

`nanoarrow.c`, `nanoarrow.h` and `nanoarrow.hpp` are the bundled sources of the Apache Arrow nanoarrow library, version 0.9.0,
copied from the `src/` directory of the nanoarrow R package's CRAN sources (`nanoarrow_0.9.0.tar.gz`).
`LICENSE.txt` and `NOTICE.txt` are the files of the same name from the nanoarrow release tag `apache-arrow-nanoarrow-0.9.0`.

The single delta is the line `#define NANOARROW_NAMESPACE RSQLite` in `nanoarrow.h` (upstream: `RPkg`), marked there with a comment,
which prefixes the library's symbols so that they cannot collide with the copy inside the nanoarrow package or arrow's.
`-DNANOARROW_DLL=` in `src/Makevars` additionally keeps them out of the shared object's exports.
Copies of `LICENSE.txt` and `NOTICE.txt` are installed from `inst/licenses/`, and `inst/COPYRIGHTS` describes the bundled code.

To update:

1. Download the CRAN sources of the new nanoarrow version, unpack them into a temporary directory (`tar -xzf nanoarrow_X.Y.Z.tar.gz -C "$tmp"`, with `tmp=$(mktemp -d)`),
   and copy `src/nanoarrow.c`, `src/nanoarrow.h` and `src/nanoarrow.hpp` from there over these files.
2. Set the namespace line in `nanoarrow.h` back to `#define NANOARROW_NAMESPACE RSQLite  // Changed by RSQLite from RPkg, see README.md`.
3. Copy `LICENSE.txt` and `NOTICE.txt` from the release tag, also to `inst/licenses/nanoarrow-LICENSE.txt` and `inst/licenses/nanoarrow-NOTICE.txt`,
   and update the version here and in `inst/COPYRIGHTS`.
4. Check the delta: `for f in nanoarrow.c nanoarrow.h nanoarrow.hpp; do diff "$tmp/nanoarrow/src/$f" src/vendor/nanoarrow/$f; done`
   must print only the namespace line of `nanoarrow.h`.
5. Rebuild, and check that `nm -D --defined-only src/RSQLite.so | grep -i arrow` prints nothing.
