#!/bin/sh

if [ "xcount" = "x$1" ]; then
	keyword='],\|]]'
	cnt=`/bin/grep "^var VSList =" "$2" | /bin/sed -n "s/$keyword/\n&\n/gp" | /bin/grep -c "^$keyword$"`
	/bin/echo -n "$cnt"
elif [ "xconcate" = "x$1" ]; then
	str='VSList_s=0&VSList=Delete'
	cnt=1;
	while [ "$2" -gt "$cnt" ]; do
		str="$str&VSList_s=$cnt"
		cnt=$(( $cnt + 1 ))
	done
	/bin/echo -n "$str"
elif [ "xaddconcate" = "x$1" ]; then
	tmp_cn=0;
	while [ "$2" -gt "$tmp_cn" ]; do
		str="$str&VSList_s=$tmp_cn"
		tmp_cn=$(( $tmp_cn + 1))
	done
	/bin/echo -n "$str"
fi
