#!/bin/sh

SZD_TMP="$1"
DIR=${SZD_TMP}"/usr/syno/etc"

[ ! -z "$SZD_TMP" ] || exit 0
[ -w "$DIR" ] || /bin/mkdir -p "$DIR"

copy_and_filter_out() {
    local pattern=$1 file=$2
    [ -r "$file" ] || return 1
    /bin/grep -v "$pattern" "$file" > ${SZD_TMP}/${file}

    # concate file list for later `ls -l', because the grep command can
    # not restore original file stat like mtime.
    TMP_LIST="$TMP_LIST $file"
}

copy_and_filter_out "\(username=\|password=\)" /usr/syno/etc/iscsi_target.conf

/bin/ls -l $TMP_LIST >> "$SZD_TMP/grep_files.list"

exit 0

