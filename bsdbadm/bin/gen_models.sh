#!/bin/sh

# change 1 level down script's directory
cd "$(dirname $0)/../"
mkdir tmp

python bs/manage.py inspectdb > tmp/models_1
python bin/fix_models.py tmp/models_1 tmp/models_2

cp tmp/models_2 "bs/dbadm/inspectdb/models_$(date '+%Y_%m_%d').py"
rm -r tmp

