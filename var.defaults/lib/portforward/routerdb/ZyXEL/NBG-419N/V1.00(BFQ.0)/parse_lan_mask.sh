#!/bin/sh

LanMask=`/bin/grep -A 5 "<table id=LanIPNetMask " "$1" | \
        /bin/grep value | /usr/bin/cut -d '"' -f2`

if [ "" = "$LanMask" ]; then
        /bin/echo -n "255.255.255.0"
else
        /bin/echo -n "$LanMask"
fi
