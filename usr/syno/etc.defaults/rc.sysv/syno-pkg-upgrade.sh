#!/bin/sh
# Copyright (c) 2000-2015 Synology Inc. All rights reserved.

SYNOPKG=/usr/syno/bin/synopkg
SYNOGETKEYVALUE=/usr/syno/bin/synogetkeyvalue

syslog() {
	local ret=$?
	logger -p user.err -t $(basename $0) "$@"
	return $ret
}

resolve_pkgname_from_spk()
{
	local spk="$1"
	local pkgname

	pkgname="$(tar xOf "$spk" INFO | grep "^package=" | cut -d'"' -f2)"
	if [ -n "$pkgname" ]; then
		echo "$pkgname"
	else
		echo "$spk" | sed -n 's,^.*/\([^-]\+\)-.*$,\1,p'
	fi
}

get_display_name()
{
	local spk="$1"
	local pkgname="$2"
	local tmpdir
	local displayname_key=displayname

	tmpdir="$(mktemp -d "${pkgname}XXX" -p /tmp)"
	/bin/tar xf "$spk" -C "$tmpdir" INFO

	lang="$($SYNOGETKEYVALUE /etc/synoinfo.conf maillang)"
	if [ -n "$lang" ]; then
		displayname_key="displayname_$lang"
	fi

	display_name=$($SYNOGETKEYVALUE "$tmpdir/INFO" "$displayname_key")
	[ -n "$display_name" ] && echo "$display_name" || echo "$pkgname"

	rm -r "$tmpdir"
}

is_package_installed()
{
	local packageName
	[[ *.spk == $packageName ]] && packageName=$(resolve_pkgname_from_spk $1) || packageName=$1

	if [ -d "/var/packages/$packageName" ]; then
		true
	else
		false
	fi
}

# Is package $1 built-in package for freshly installed DSM?
#
# PROTO TYPE:
#         is_in_fresh_install spk_filename
is_in_fresh_install()
{
	local packageName="$1"
	local package_list="FileStation SynoFinder USBCopy SurveillanceStation OAuthService"
	local unique=`/bin/get_key_value /etc.defaults/synoinfo.conf unique`

	if [ "synology_kvmcloud_alidsm" = "$unique" ]; then
		local alidsm_preinstall='
			Node.js_v4
			PHP5.6
			Perl
			AntiVirus
			LogCenter
			CloudStation
			CloudSync
			TextEditor
			PDFViewer
			StorageAnalyzer
			HyperBackup
			SynologyApplicationService
			SynologyFileManager
			NoteStation
			Spreadsheet
			Calendar
			Chat
			DiagnosisTool
		'
		package_list="$package_list $alidsm_preinstall"
	fi
	for i in ${package_list}
	do
		if [ "x$packageName" = "x${i}" ]; then
			return 0
		fi
	done
	return 1
}

# Is packge $2 built-in package for dsm $1?
#
# PROTO TYPE:
#         is_in_dsm previous_dsm_build_number spk_filename
is_in_dsm()
{
	local packageName=$2
	local package_list="FileStation SynoFinder DisasterRecovery OAuthService"

	# SurveillanceStation always in dsm
	if [ "x$packageName" = "xSurveillanceStation" ]; then
		return 0
	fi

	# following if-statements should be something like
	#	if [ $1 -lt xxxx ]; then
	#		package="$package_list yyyy"
	#	fi
	# where
	# 	xxxx: max reserved build number in "previous" release
	#	yyyy: packages become builtin or must install/upgrade in "this" release
	if [ $1 -lt 14600 ]; then  # builtin package introduced in 6.1 beta
		package_list="$package_list USBCopy"
	fi
	if [ $1 -lt 15030 ]; then # check before 6.1 RC
		package_list="$package_list SnapshotReplication"
	fi

	for i in ${package_list}
	do
		if [ "x$packageName" = "x${i}" ]; then
			return 0
		fi
	done
	return 1
}

should_install_package() {
	local packageName="$1"
	local is_upgrade=false

	if is_package_installed $packageName; then
		is_upgrade=true
	fi

	if [ "$packageName" = "FileStation" ] || [ "$packageName" = "SynoFinder" ]; then
		:
		# always install and upgrade FileStation.
		# always install and upgrade SynoFinder.
	elif [ "$packageName" = "OAuthService" ]; then
		:
		# always install and upgrade OAuthService.
	elif [ "$packageName" = "DisasterRecovery" ]; then
		if ! $is_upgrade; then
			return 1 # don't install packages
		fi
	elif [ "$packageName" = "SurveillanceStation" ]; then
		:
		# always install and upgrade SurveillanceStation
	else
		if $is_upgrade; then
			return 1 # don't upgrade packages
		fi
	fi

	# perform package-specific checks here
	case "$packageName" in
		"USBCopy")
			# if no usbcopy and no sdcopy => do not install
			if [ "yes" != "$(get_key_value /etc.defaults/synoinfo.conf usbcopy)" ] &&
				[ "yes" != "$(get_key_value /etc.defaults/synoinfo.conf sdcopy)" ]; then
				return 1
			fi
			;;
		"SnapshotReplication")
			python /usr/syno/synodr/sbin/check_snapreplica.py
			chk_ret=$?
			if [ 0 -ne $chk_ret ]; then
				return 1
			fi
			;;
		"*")
			;;
	esac

	return 0
}

install_package() {
	local packageName
	local ret=
	local is_upgrade=false

	[ ! -z $2 ] && packageName=$2 || packageName=$(resolve_pkgname_from_spk $1)

	if is_package_installed $packageName; then
		is_upgrade=true
	fi

	if $is_upgrade; then
		syslog "upgrade package: $1"
	else
		syslog "install package: $1"
	fi
	$SYNOPKG install "$1"
	ret=$?

	# return if install failed
	[ $ret -ne 0 ] && return $ret

	/usr/syno/sbin/synopkgctl enable $packageName
	/usr/syno/sbin/synopkgctl correct-cfg $packageName
	# start service of built-in package
	/sbin/initctl start "pkgctl-$packageName"
	return $ret
}

process_builtin_packages() {
	local package_dir=$1
	local packageName
	local print_only=$2
	local old_bnum=`/bin/get_key_value /.old_patch_info/VERSION buildnumber`
	local fresh_install=true
	local sort_spk_by_dep_order_result=
	local sorted_spk_list=

	[ -d "$package_dir" ] || return 1

	# if no "/.old_patch_info" (new installation), only install packages that pass is_in_fresh_install()
	[ -f "/.old_patch_info/VERSION" ] && fresh_install=false

	if [ ! -z "$(ls -A $package_dir)" ]; then
		sort_spk_by_dep_order_result=$("$SYNOPKG" sort_spk_by_dep_order $(find $package_dir/*.spk))
		if [ $? -ne 0 ]; then
			echo "syno-pkg-upgrade.sh: $sort_spk_by_dep_order_result"
		else
			sorted_spk_list="$sort_spk_by_dep_order_result"
			for i in $sorted_spk_list; do
				packageName=$(resolve_pkgname_from_spk $i)
				if $fresh_install && $(is_in_fresh_install "$packageName") && $(should_install_package "$packageName"); then
					if [ $print_only ]; then
						echo "$packageName"
					else
						install_package "$i" "$packageName"
					fi
				elif ! $fresh_install && $(is_in_dsm "${old_bnum}" "$packageName") && $(should_install_package "$packageName"); then
					if [ $print_only ]; then
						echo "$packageName"
					else
						install_package "$i" "$packageName"
					fi
				fi
			done
		fi
	fi
}

usage() {
	cat << EOF
Usage: $(basename $0) {start,get_queue}
EOF
}

# Old python package will remove the builtin python binary, so we have to remove it.
remove_old_python_package() {
	local package_dir="/var/packages/Python"
	local preuninst="$package_dir/scripts/preuninst"

	if [ -d "$package_dir" ]; then
		syslog "Remove old python package"
		sed -i -e 's,.*libyaml.*,:,g' -e 's,.*libpython.*,:,g' -e 's,.*/usr/bin/python.*,:,g' $preuninst
		synopkg uninstall Python
	fi
}

start()
{
	if [ -e /var/.UpgradeBootup ]; then
		remove_old_python_package
	fi

	if [ -d /.SynoUpgradePackages ]; then
		process_builtin_packages /.SynoUpgradePackages
		rm -rf /.SynoUpgradePackages
	fi

}

get_queue()
{
	if [ -d /.SynoUpgradePackages ]; then
		process_builtin_packages /.SynoUpgradePackages true
	fi
}

case "$1" in
	start) start;;
	get_queue) get_queue;;
	*) usage >&2; exit 1;;
esac
