#!/bin/sh

set -e

old_tag=v1.0.0
branch=f-revdep

cd $(dirname $0)/..
git checkout -- .
git clean -fdx

git checkout $branch --
cp -r revdep revdep-

git checkout $old_tag --
rm -rf revdep
mv revdep- revdep
rm -rf revdep/install

R -f revdep/check.R
#echo $old_tag >> revdep/README.md

mv revdep revdep-$old_tag

git checkout $branch --

rm -rf revdep
mv revdep-$old_tag revdep
git add revdep
git commit -m "revdep update with $old_tag results"

git clean -fdx
rm -rf revdep/install

R -f revdep/check.R
#echo $branch >> revdep/README.md

git add revdep
git commit -m "revdep update with $branch results"

git fetch --all
git rebase
git push
