#!/bin/sh
#
# Synology space utility.
#
# Copyright (c) 2003-2013 Synology Inc. All rights reserved.
#
# Support to parse synology space*.xml and generate the correspond
# mdadm rebuild command, ref: <DSM> #45470.

Usage()
{
	echo "Copyright (c) 2003-2013 Synology Inc. All rights reserved."
	echo
	echo "Usage: $CMD [OPTIONS] [FILES]"
	echo
	echo "Option:"
	echo "    -p,--parse        Parse the space.xml to generate the correspond mdadm command."
	echo
}

getToken()
{
	awk '/<raid/,/raid>/' $1 | \
	awk '
	BEGIN { numRaid=0; }
	{
		if ("<raid" == $1) {
			for (i=2; i<=NF; i++) {
				if ("path=" == substr($i, 0, 5)) {
					if (0 != numRaid) {
						printf "END %d\n", numRaid;
					}

					numRaid++;
					printf "BEGIN %d\n", numRaid;
					printf "%s \"%d\"\n", $i, -2;
				}
				if ("level=" == substr($i, 0, 6)) {
					printf "%s \"%d\"\n", $i, -1;
				}
			}
		}
		if ("<disk" == $1) {
			path="";
			slot=-999;
			for (i=2; i<=NF; i++) {
				if ("dev_path=" == substr($i, 0, 9)) {
					path=$i;
				}
				if ("slot=" == substr($i, 0, 5)) {
					slot=$i;
				}
			}
			printf "%s %s\n", path, slot;
		}
	}
	END { printf "END %d\n", numRaid; }'
}

sortToken()
{
	echo "$@" | \
	sort -t '"' -k 4 -n | cut -d ' ' -f 1
}

blockToken()
{
	local block=""
	local numBlock=0
	echo "$@" | while read line; do
		if [ "BEGIN" == "`echo $line | head -c5`" ]; then
			block=""
			numBlock=`echo $line | cut -d' ' -f2`
		elif [ "END" == "`echo $line | head -c3`" ]; then
			output=`echo -e "$block"`
			echo ======= block token $numBlock  >&2
			echo "$output"                      >&2
			output=$(sortToken "$output")
			echo ======= sorted token $numBlock >&2
			echo "$output"                      >&2
			# real return
			echo "$output"
		else
			block="$block$line\n"
		fi
	done
}

assembleCMD()
{
	echo "$@" | \
	awk -F'"' '
	# for syntax escape"
	function output() {
		printf "%s -n %d --assume-clean %s\n", cmd, numDisk, disks;
	}
	# Check device exist or not
	# 0: exist
	# 1: not exist
	function exists(device) {
		line=0;
		if ((getline line < device) > 0) {
			return 0;
		}
		return 1;
	}

	BEGIN{ cmd=""; }
	{
		if ("path=" == $1) {
			if ("" != cmd) {		# handle previous raid section
				output();
			}

			# Initial all vars.
			numDisk=0; disks="";
			cmd="mdadm -C " $2 " -R ";
		}
		if ("level=" == $1) {
			cmd=cmd "-l " $2;
		}
		if ("dev_path=" == $1) {
			numDisk++;
			if (0 == exists($2)) {
				disks = disks $2 " ";
			} else {
				disks = disks "missing ";
			}
		}
	}
	END{ output(); }'
}

ParseXML()
{
	echo "========= get token"    >&2
	tok=$(getToken "$1")

	echo "$tok"                   >&2
	btok=$(blockToken "$tok")

	echo "========= asm command"  >&2
	cmd=$(assembleCMD "$btok")

	echo "$cmd"
}

CMD=$(basename "$0")
ARGS=`getopt -o "p:" -l "parse:" -n "$CMD" -- "$@"`

if [ $? -ne 0 -o $# -eq 0 ]; then
	Usage
	exit 1
fi


doParse=""
xmlFile=""
while [ -n "$1" ]; do
	case "$1" in
	-p | --parse)
		doParse=true
		xmlFile="$2"
		shift
		shift
		continue;;
	*)
		Usage
		exit 1;;
	esac
done

if [ -n "$doParse" ] ; then
	if [ -f $xmlFile -a -r $xmlFile ] ; then
		# turn on/off debug info
		exec 2>/dev/null
		ParseXML $xmlFile
	else
		echo "Error: File $xmlFile read failed."
		exit 1
	fi
fi

exit 0
