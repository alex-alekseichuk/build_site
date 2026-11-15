#!/bin/sh

# change 1 level down script's directory
cd "$(dirname $0)/../"

python bs/manage.py syncdb

