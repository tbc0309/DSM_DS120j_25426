#!/bin/sh
# Copyright (c) 2000-2014 Synology Inc. All rights reserved.
. /usr/syno/bin/jsoncmd

PKGNAME_TRIGGER=$1
SOURCE_PLUGIN_PATH=/usr/syno/share/synoappbackuptemp
BIN_CP=/bin/cp
BIN_SYNOPKG=/usr/syno/bin/synopkg

PKGNAME_SURVEILLANCE=SurveillanceStation

myLog()
#1: err message
{
	/usr/bin/logger -s -p err -t syno_install_backup_plugin $1
}

checkVersion()
#1: Package ID
{
	pkg_name=$1

#Get installed package version
	version_install=`${BIN_SYNOPKG} version ${pkg_name}`
	if [ $? -eq 1 ]; then
		return 0 #package not installed
	fi
	version_install=\"${version_install}\"

	version_json=`/bin/cat ${SOURCE_PLUGIN_PATH}/${pkg_name}/package_version`
	version_list=$(jfilter "${version_json}" .[])
	if [ $? -ne 0 ];then
		  myLog "Package NOT install, skip install plugin [${pkg_name}]"
		  return 0   #failed to get version list, maybe data format is wrong
	fi

	for version_allow in ${version_list}; do
		if [ "x${version_allow}" = "x${version_install}" ]; then
			myLog "Version match [${version_install}] ==> Install package [${pkg_name}]"
			return 1 #match
		fi
	done

	myLog "Version NOT match [${version_install}] ==> Not install plugin [${pkg_name}]"

	return 0
}

#SurveillanceStation
if [ -z "${PKGNAME_TRIGGER}" -o "x${PKGNAME_TRIGGER}" = "x${PKGNAME_SURVEILLANCE}" ];then
	checkVersion ${PKGNAME_SURVEILLANCE}
	IsVersionMatch=$?

	if [ ${IsVersionMatch} -eq 1 ];then
		${BIN_CP} -rf ${SOURCE_PLUGIN_PATH}/${PKGNAME_SURVEILLANCE}/scripts/backup /var/packages/${PKGNAME_SURVEILLANCE}/scripts/
	fi
fi
