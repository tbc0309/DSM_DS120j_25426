#!/bin/sh

SZD_TMP="$1"
copy_and_filter_out() { # <fileter pattern> <file>
	local pattern=$1 file=$2 dir=
	[ -r "$file" ] || return 1
	dir=${SZD_TMP}/`/usr/bin/dirname "$file"`
	[ -w "$dir" ] || /bin/mkdir -p "$dir"
	/bin/grep -v "$pattern" "$file" > ${SZD_TMP}/${file}
}

copy_and_filter_out "\(remote_pass\|remote_secret\|remote_access_token\|remote_refresh_token\)=" /usr/syno/etc/synobackup.conf

exit 0
