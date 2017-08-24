#!/bin/bash

REPOURL=https://github.com/apache/nifi.git

VEROLD=rel/nifi-1.3.0
VERNEW=master

rm -rf oldbuild newbuild oldrepo newrepo

git clone $REPOURL oldbuild
pushd oldbuild
git checkout $VEROLD
mvn -Duser.name=unattributed -DskipTests -Dmaven.repo.local=../oldrepo clean package
popd

git clone $REPOURL newbuild
pushd newbuild
git checkout $VERNEW
mvn -Duser.name=unattributed -DskipTests -Dmaven.repo.local=../newrepo clean package
popd

pushd oldrepo
find . -type f -name "*.pom" | xargs dirname | sort > ../oldpomdirs 
popd

pushd newrepo
find . -type f -name "*.pom" | xargs dirname | sort > ../newpomdirs
popd

tar -cvzf deps-$(date +%Y%m%d-%H%M%S).tar.gz $(comm -13 oldpomdirs newpomdirs)

