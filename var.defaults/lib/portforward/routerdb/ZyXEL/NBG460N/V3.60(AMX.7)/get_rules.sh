#!/bin/sh

cnt=`grep -c doFindCurrentRule "$1"`
cnt="$(( $cnt - 1 ))"

if [ "0" -ge "$cnt" ]; then
    /bin/echo 0
else
    /bin/echo "$(( $cnt / 2 + 1 ))"
fi
