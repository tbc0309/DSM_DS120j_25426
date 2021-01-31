#!/bin/sh

SZD_TMP="$1"
copy_files_to_tmp()
{
	local file=$1 dir=
	[ -r "$file" ] || return 1
	dir=${SZD_TMP}/`/usr/bin/dirname "$file"`
	[ -w "$dir" ] || /bin/mkdir -p "$dir"
	/bin/cp -f $file ${SZD_TMP}/$file
}

copy_and_filter_out() { # <fileter pattern> <file>
	local pattern=$1 file=$2 dir=
	[ -r "$file" ] || return 1
	dir=${SZD_TMP}/`/usr/bin/dirname "$file"`
	[ -w "$dir" ] || /bin/mkdir -p "$dir"
	/bin/grep -v "$pattern" "$file" > ${SZD_TMP}/${file}

	# concate file list for later `ls -l', because the grep command can
	# not restore original file stat like mtime.
	# FIXME if file name include white space, this list will be wrong
	TMP_LIST="$TMP_LIST $file"
}

copy_and_filter_out "\(password\|pass\)=" /usr/syno/etc/synovpnclient/l2tp/l2tpclient.conf
copy_and_filter_out "\(password\|pass\)=" /usr/syno/etc/synovpnclient/pptp/pptpclient.conf
copy_and_filter_out "\(password\|pass\)=" /usr/syno/etc/synovpnclient/openvpn/ovpnclient.conf

copy_files_to_tmp /usr/syno/etc/synovpnclient/openvpn/client_o*
copy_files_to_tmp /usr/syno/etc/synovpnclient/l2tp/connect_*
copy_files_to_tmp /usr/syno/etc/synovpnclient/l2tp/options_*
copy_files_to_tmp /usr/syno/etc/synovpnclient/pptp/connect_*
copy_files_to_tmp /usr/syno/etc/synovpnclient/pptp/options_*


exit 0

