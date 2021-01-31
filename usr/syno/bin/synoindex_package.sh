#!/bin/sh

PKGNAME=$2
SYNOINDEX_PKG_INFO="/usr/syno/etc/synoindex/packages/${PKGNAME}/INFO"
gIsPackageEnabled=""

set_synoindex_package_enable()
{
	# set ENABLED to yes in synoindex package info
	enableKey=`grep ENABLED= ${SYNOINDEX_PKG_INFO}`
	if [ $enableKey != "" ]; then
		sed -i 's/ENABLED=.*/ENABLED=\"'${gIsPackageEnabled}'\"/g' ${SYNOINDEX_PKG_INFO}
	else
		echo 'ENABLED="${gIsPackageEnabled}"' >> ${SYNOINDEX_PKG_INFO}
	fi

	# daemon should reload config
	/usr/syno/sbin/synoservice --reload synoindexd
	/usr/syno/sbin/synoservice --reload synomkthumbd
	/usr/syno/sbin/synoservice --reload synomkflvd
}

case $1 in
	enable)
		gIsPackageEnabled="yes"
		set_synoindex_package_enable
	;;
	disable)
		gIsPackageEnabled="no"
		set_synoindex_package_enable
	;;
	*)
		echo "Usage: $0 enable|disable [PKG_NAME]"
	;;
esac
