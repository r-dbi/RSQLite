#!/bin/bash

cd $(dirname $0)
MAKEFLAGS="-j8 -O" nice R CMD INSTALL --libs-only --no-test-load .
