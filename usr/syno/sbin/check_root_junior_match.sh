#!/bin/sh

RootMnt="${1}/"; shift

GetKV() { /bin/get_key_value "$@"; }

SYNOINFO_DEF=etc.defaults/synoinfo.conf
VERSION_DEF=etc.defaults/VERSION
VERSION_UPDATER=.syno/patch/VERSION
UniqueRD=`GetKV "/$SYNOINFO_DEF" unique | cut -d"_" -f2`

AssertDirectory() { # dir
	local dir="$1"; shift

	if ! [ -d "$dir" ]; then
		echo "Failed to AssertDirectory[$dir]"
		exit 1
	fi
}

AssertDirectory "${RootMnt}"
AssertDirectory "${RootMnt}etc.defaults/"

AssertFileKeyValueEqual() { # file1 file2 key
	local file1="$1"; shift
	local file2="$1"; shift
	local key="$1"; shift

	local value1=$(GetKV "$file1" "$key")
	local value2=$(GetKV "$file2" "$key")

	if [ "$value1" != "$value2" ]; then
		echo "Failed to AssertFileKeyValueEqual"
		echo "  value1: ${file1}:${key} -> $value1"
		echo "  value2: ${file2}:${key} => $value2"
		exit 2
	fi
}

AssertFileKeyValueEqual "/${SYNOINFO_DEF}" "${RootMnt}${SYNOINFO_DEF}" unique
AssertFileKeyValueEqual "/${VERSION_DEF}" "${RootMnt}${VERSION_DEF}" buildnumber

if [ "$UniqueRD" != "kvmx64" -a "$UniqueRD" != "nextkvmx64" -a "$UniqueRD" != "kvmcloud" ]; then
	AssertDirectory "${RootMnt}.syno/patch/"
	AssertFileKeyValueEqual "/${VERSION_DEF}" "${RootMnt}${VERSION_UPDATER}" buildnumber
	AssertFileKeyValueEqual "/${VERSION_DEF}" "${RootMnt}${VERSION_UPDATER}" smallfixnumber
	AssertFileKeyValueEqual "/${VERSION_DEF}" "${RootMnt}${VERSION_UPDATER}" packing
	AssertFileKeyValueEqual "/${VERSION_DEF}" "${RootMnt}${VERSION_UPDATER}" packing_id
fi
