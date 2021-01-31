#!/bin/sh
# Copyright (c) 2000-2019 Synology Inc. All rights reserved.

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

usage() {
	cat << EOF
Usage: $(basename $0) {start,get_queue}
EOF
}

install_manutil_packages()
{
	local package_dir=$1

	[ -d "$package_dir" ] || return 1

	/usr/syno/bin/synosetkeyvalue /etc/synoinfo.conf pkg_source_trust_level 2

	ManutilPackList=`cat $package_dir/install_list`
	for mPackage in $ManutilPackList
	do
		echo install $mPackage
		install_package $package_dir/$mPackage
	done
}

start()
{
	# install packages for factory test
	if [ -d /.SynoManutilPackages ]; then
		# Check 6 times if volume exist
		count=0
		while ! grep -qs 'volume' /proc/mounts
		do
			sleep 10
			count=`expr $count + 1`
			if test $count -eq 6
			then
				syslog "Volume not exist!"
				break
			fi
		done
		install_manutil_packages /.SynoManutilPackages
		rm -rf /.SynoManutilPackages
	fi
}

case "$1" in
	start) start;;
	*) usage >&2; exit 1;;
esac
