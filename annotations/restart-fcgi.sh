#!/bin/sh

cd $(dirname $0)

PROJDIR=$(pwd)
PIDFILE="$PROJDIR/annot.pid"


if [ -f $PIDFILE ]; then
    kill `cat -- $PIDFILE`
    rm -f -- $PIDFILE
fi

python manage.py runfcgi host=127.0.0.1 port=8090 --settings=settings pidfile=$PIDFILE

