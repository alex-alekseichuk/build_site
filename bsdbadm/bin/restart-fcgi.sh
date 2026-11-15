#!/bin/sh

cd "$(dirname $0)/../bs"

PROJDIR=$(pwd)
PIDFILE="$PROJDIR/dbadm.pid"
SOCKET="$PROJDIR/dbadm.sock"

if [ -f $PIDFILE ]; then
    kill `cat -- $PIDFILE`
    rm -f -- $PIDFILE
fi

if [ $(hostname) = "crunch.ahinea.com" ]; then
    python manage.py runfcgi host=127.0.0.1 port=8080 --settings=settings pidfile=$PIDFILE
else
    python manage.py runfcgi --settings=settings socket=$SOCKET pidfile=$PIDFILE method=prefork maxrequests=100 maxspare=3 minspare=2 maxchildren=3 daemonize=true
    chmod a+w $SOCKET
fi

