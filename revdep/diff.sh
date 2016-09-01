#!/bin/sh

set -e

old_tag=v1.0.0
branch=f-revdep

cd $(dirname $0)/..
git checkout -- .
git clean --force -dx

git checkout $branch --
cp -r revdep revdep-

git checkout $old_tag --
rm -rf revdep
mv revdep- revdep
rm -rf revdep/install

git add revdep
git commit -m "revdep update for clean state" || true

R -f revdep/check.R
#echo $old_tag >> revdep/README.md

mv revdep revdep-$old_tag
git checkout .

git checkout $branch --

rm -rf revdep
mv revdep-$old_tag revdep
cp revdep/README.md revdep/README-${old_tag}.md
cp revdep/problems.md revdep/problems-${old_tag}.md
git add revdep
git commit -m "revdep update with $old_tag results"

git clean --force -dx
rm -rf revdep/install
git add revdep
git commit -m "revdep update for clean state" || true

R -f revdep/check.R
#echo $branch >> revdep/README.md

cp revdep/README.md revdep/README-${branch}.md
cp revdep/problems.md revdep/problems-${branch}.md

git add revdep
git commit -m "revdep update with $branch results"

git fetch --all
git rebase
git push origin HEAD
