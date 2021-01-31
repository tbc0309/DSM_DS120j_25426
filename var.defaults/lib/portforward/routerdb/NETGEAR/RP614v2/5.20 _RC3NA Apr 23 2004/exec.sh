#!/bin/sh

if [ "xsleep" = "x$1" ]; then
	/bin/sleep "$2"
elif [ "xcount" = "x$1" ]; then
	keyword='"VirSerActEnt"'
	cnt=`/bin/sed -n "s/$keyword/\n&\n/gp" "$2" | /bin/grep -c "^$keyword$"`
	/bin/echo -n "$cnt"
elif [ "xconcate" = "x$1" ]; then
	str="&"
	cnt=0
	while [ "$2" -gt "$cnt" ]; do
		str="$str""VirSerActEnt=on&VirActIn=""$cnt""&"
		cnt="$(( $cnt + 1 ))"
	done
	/bin/echo -n "$str"
elif [ "xassign" = "x$1" ]; then
	/bin/echo -n "$2"
fi
