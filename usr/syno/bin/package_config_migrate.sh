#!/bin/sh
# Copyright (c) 2003-2011 Synology Inc. All rights reserved.

GREP=/bin/grep
SED=/bin/sed


Usage()
{
	cat >&2 <<EOF
Usage:
	del  [conf file] [key list]
		delete keys in list from conf file.
		key list is separate by space. can be regular expression.
	move [src conf file] [dst conf file] [key list]
		move keys in list from src file to dst file.
		key list is separate by space. can be regular expression.
EOF
}

Delete()
{
	local confFile="$1"
	local keyList="$2"
	local count=0

	if [ -z "$confFile" ] || [ -z "$keyList" ]; then
		Usage;
		return 1;
	fi

	if [ ! -r "$confFile" ]; then
		echo "Failed to open file $confFile"
		return 1;
	fi

	for key in $keyList; do
		line=`$GREP "^$key=" "$confFile"`
		matched=`$GREP -c "^$key=" "$confFile"`

		if [ -n "$line" ]; then
			$SED -i "/^"$key"=/d" "$confFile"
			count=`expr $count + $matched`
		fi
	done

	echo "Deleted $count keys from file $confFile"
}

Move()
{
	local srcFile="$1"
	local dstFile="$2"
	local keyList="$3"
	local count=0

	if [ -z "$srcFile" ] || [ -z "$dstFile" ] || [ -z "$keyList" ]; then
		Usage;
		return 1;
	fi

	if [ ! -r "$srcFile" ]; then
		echo "Failed to open file $srcFile"
		return 1;
	fi
	if [ ! -r "$dstFile" ]; then
		echo "Failed to open file $dstFile"
		return 1;
	fi

	for key in $keyList; do
		line=`$GREP "^$key=" "$srcFile"`
		lineInDst=`$GREP "^$key=" "$dstFile"`
		matched=`$GREP -c "^$key=" "$srcFile"`

		if [ -n "$line" ]; then
			if [ -n "$lineInDst" ]; then
				# dst already has these keys, delete first
				$SED -i '/^'$key'=/d' "$dstFile"
			fi

			# copy keys from src to dst
			$GREP "^$key=" "$srcFile" >> "$dstFile"

			# remove keys from src file
			$SED -i '/^'$key'=/d' "$srcFile"

			count=`expr $count + $matched`
		fi
	done

	echo "Moved $count keys from $srcFile to $dstFile"
}

case $1 in
h|help|-h|--help)
	Usage;
	exit 1;
	;;
d|del|-d|--del)
	Delete "$2" "$3";
	exit 0;
	;;
m|move|-m|--move)
	Move "$2" "$3" "$4";
	exit 0;
	;;
*)
	Usage;
	exit 1;
	;;
esac

# vim:ts=4
