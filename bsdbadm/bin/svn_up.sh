#!/bin/sh

# change 1 level down script's directory
cd "$(dirname $0)/../"

echo Updating working copy...
svn up

echo Applying patches...
bin/apply_patches.pl

echo Restarting server...
bin/restart-fcgi.sh

cd - > /dev/null
