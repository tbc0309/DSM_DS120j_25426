#!/bin/sh

if [ "xcount" = "x$1" ]; then
	keyword='option value='
	cnt=`/bin/grep '^<option value="0">' "$2"|/bin/sed -n "s/$keyword/\n&\n/gp"|/bin/grep -c "^$keyword$"`
	/bin/echo -n "$cnt"
elif [ "xconcate" = "x$1" ]; then
	str='VSList_s=0'
	cnt=1;
	while [ $2 -gt $cnt ]; do
		str="$str&VSList_s=$cnt"
		cnt=$(( $cnt + 1 ))
	done
	/bin/echo -n "$str"
fi
