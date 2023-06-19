#!/bin/sh

set -ex

git clean -fdx src
R CMD INSTALL .
if ! [ -d dm ]; then git clone https://github.com/cynkra/dm; fi
cd dm
R -q -e 'Sys.setenv(DM_TEST_SRC = "sqlite"); pkgload::load_all(); x <- tf_1(); y <- data_card_1_duckdb()'
