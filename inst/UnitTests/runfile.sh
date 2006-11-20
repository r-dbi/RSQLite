#!/bin/bash

RUNIT_DIR=`pwd`
INST_PATH=`dirname $RUNIT_DIR`
PKG_PATH=`dirname $INST_PATH`
PKG=`basename $PKG_PATH`

TEST_FILE=$1

if test $# -ne 1; then
    echo "Usage: runfile.sh SOMETEST.R"
    exit 1
fi

R_CODE="library('RUnit')"
R_CODE="${R_CODE};library('${PKG}')"
R_CODE="${R_CODE};res <- runTestFile('${TEST_FILE}', rngKind='default', rngNormalKind='default')"
R_CODE="${R_CODE};printTextProtocol(res, showDetails=FALSE)"

echo $R_CODE | R --slave
