#!/bin/sh
# Copyright (c) 2000-2015 Synology Inc. All rights reserved.
dump_sas_disk_map()
{
	supportSAS=`/bin/get_key_value /etc.defaults/synoinfo.conf supportsas`
	if [ "xyes" == "x${supportSAS}" -o "xYES" == "x${supportSAS}" ]; then
		sleep 15
		/usr/syno/bin/synoenc --dump_enc_disk /tmp/sasdiskmaps
		cat /tmp/sasdiskmaps >> /var/log/messages
	fi
}

first_install_configure()
{
	echo `date`": start pre_first_install_configure"

	# get original value for setting below.
	GRINST_OK="/.GRINST_OK"
	WEBINST_OK="/.WEBINST_OK"
	if [ -f ${GRINST_OK} -o -f ${WEBINST_OK} ]; then
		echo "Group/Web Installation OK, auto set configured."
		grep -v "^configured=" /etc/synoinfo.conf > /tmp/synoinfo.conf
		echo "configured=\"yes\"" >> /tmp/synoinfo.conf
		mv /tmp/synoinfo.conf /etc/synoinfo.conf
		if [ -f ${GRINST_OK} ]; then
			/usr/syno/bin/synosetkeyvalue ${SYNOINFO} install_agent groupinstall
		elif [ -f ${WEBINST_OK} ]; then
			/usr/syno/bin/synosetkeyvalue ${SYNOINFO} install_agent webinstall
		fi
		if [ -f /.ds_configure.sh ]; then
			/.ds_configure.sh
		fi
	fi
	rm -f ${GRINST_OK}
	rm -f ${WEBINST_OK}
	rm -f /.ds_configure.sh
	if [ -f /.ASTINST_OK ]; then
		/usr/syno/bin/synosetkeyvalue ${SYNOINFO} install_agent dsassistant
		rm -f /.ASTINST_OK
	fi
}

dump_cache_slot_info()
{
	local disk_info=`synodisk --enum -t cache | egrep "Slot id|Disk id|Disk path"`
	local output=""

	if [ -z $disk_info ]; then
		return
	fi

	output="******  Cache Slot info *******\n"
	while read -r line
	do
		line=`echo $line | cut -c 4-`
		output="$output$line"
		if [[ `echo $line | grep "Disk path"` ]]; then
			output="$output \n"
		else
			output="$output, "
		fi
	done <<< "$disk_info"

	echo -e "$output" >> /var/log/messages
}

dump_disk_info()
{
	dump_cache_slot_info
	dump_sas_disk_map
}

usage() {
	cat << EOF
Usage: $(basename $0) [start]
EOF
}

start()
{
	if [ -x /usr/syno/bin/synofstool ]; then
		/usr/syno/bin/synofstool --dump-fscache &
	fi

	dump_disk_info &

	#Change permission of /dev/fuse
	if [ -e "/dev/fuse" ]; then
		/bin/chown root:users /dev/fuse
		/bin/chmod 0666 /dev/fuse
	fi

	first_install_configure
	# create volume for first installation
	/usr/syno/sbin/bootup_create_volumes.sh

	if [ -d /.SynoManutilPackages ]; then
		/usr/syno/etc/rc.sysv/manutil-pkg-install.sh start
	fi

	if [ "yes" = "`/bin/get_key_value /etc/synoinfo.conf runha`" ] &&
		[ "Passive" = "`/usr/syno/sbin/synohacore --local-role`" ]; then
		# do nothing after upgrade on passive, active will do these things
		:;
	elif [ -f /.updater ] || [ -f /var/.UpgradeBootup ]; then
		/sbin/initctl emit --no-wait syno.packages.repair
		/usr/syno/bin/synoselfcheck -o "dsmupdate_$(date "+%Y%m%d_%H%M%S").result" dsm full &
		/usr/syno/bin/syno_disk_config_check &
		/usr/syno/bin/syno_disk_wcache_config_init &
		/usr/syno/sbin/synoupgrade --ensure-settings &
	elif [ -f /var/.SmallupdateBootup ]; then
		/usr/syno/bin/synoselfcheck -o "smallupdate_$(date "+%Y%m%d_%H%M%S").result" dsm full &
	fi

	# In VDSM, we will ask host to initialize guest here.
	if [ -x /usr/syno/synovdsm/scripts/initializeVdsm.sh ]; then
		/usr/syno/synovdsm/scripts/initializeVdsm.sh
	fi

	#Remove updater and version files for first-bootup of upgrade
	rm -f /.updater
	rm -f /var/.UpgradeBootup
	rm -f /var/.SmallupdateBootup
	rm -f /var/.AutoSmallupdateBootup
	rm -f /.smallupdate.pat
	# clean up migrate backup file
	rm -rf /.syno/update_bkp/
}

case "$1" in
	start) start;;
	*) usage >&2; exit 1;;
esac
