#!/bin/sh

SZD_TMP="$1"
file=/usr/syno/etc/rsyncd.account
dir=
[ -r "$file" ] || exit 0
dir="${SZD_TMP}"$(/usr/bin/dirname "$file")
[ -w "$dir" ] || /bin/mkdir -p "$dir"
/bin/cat "$file" | sed 's/:.*$//g' > "${SZD_TMP}/${file}"
