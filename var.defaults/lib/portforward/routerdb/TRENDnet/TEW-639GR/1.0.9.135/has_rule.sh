#!/bin/sh

cnt=`grep -c "submit_apply('edit'" "$1"`

if [ "0" -lt "$cnt" ]; then
    /bin/echo 1
else
    /bin/echo 0
fi
