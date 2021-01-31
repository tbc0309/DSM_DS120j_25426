#!/bin/sh

cnt=`grep -c 'name="delRule0"' "$1"`

if [ "0" -lt "$cnt" ]; then
    /bin/echo 1
else
    /bin/echo 0
fi
