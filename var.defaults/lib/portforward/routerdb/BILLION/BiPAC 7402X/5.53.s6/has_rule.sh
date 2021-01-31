#!/bin/sh

cnt=`grep -c 'name=".*_node"' "$1"`

if [ "0" -lt "$cnt" ]; then
    /bin/echo 1
else
    /bin/echo 0
fi
