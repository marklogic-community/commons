#!/bin/sh

# Zip up everything in this directory and plop it in the
# "releases" directory one level up.  The zip file is named
# with the verson number in the ../project/project.xml descriptor.
# Ron Hitchens, March 2005

basename=xquery-commons

version=`egrep "[:space:]*<version>.*</version>[:space:]*\$" ../project/project.xml | head -1 | sed "s@.*<version>\(.*\)</version>.*@\1@"`
zipfile=../releases/$basename-$version.zip
exclude="$zipfile ziprelease.sh *.svn*"

zip -r $zipfile * -x $exclude
