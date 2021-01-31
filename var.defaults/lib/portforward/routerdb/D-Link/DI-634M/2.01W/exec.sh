#!/bin/sh

if [ "xappend" = "x$1" ]; then
	rule_params="$2";
	file_name="$3"
	/bin/echo "$rule_params" >> "$file_name"
elif [ "xtemp" = "x$1" ]; then
	file_name="$2"
	/bin/rm -f "$file_name"
	/bin/touch "$file_name"
	/bin/echo -n "$file_name"
elif [ "xjob" = "x$1" ]; then
	page="$2"
	tmp=`/usr/syno/bin/synoportforward --jobnum "$page" | /bin/grep 'num' | /usr/bin/cut -d'=' -f2`
	/bin/echo -n "$tmp"
elif [ "xclean" = "x$1" ]; then
	shift #clean all other params
	/bin/rm -f $@
fi
