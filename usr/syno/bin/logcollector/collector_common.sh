#!/bin/sh

SZD_TMP="$1"
ETHTOOL="/usr/bin/ethtool"
DMIDECODE="/usr/sbin/dmidecode"
PROCFILES="/proc/buddyinfo \
			/proc/bus/usb/devices \
			/proc/cmdline \
			/proc/cpuinfo \
			/proc/flashcache/*/flashcache_stats \
			/proc/interrupts \
			/proc/mdstat \
			/proc/meminfo \
			/proc/modules \
			/proc/mounts \
			/proc/mtd \
			/proc/net/bonding/* \
			/proc/net/dev \
			/proc/net/route \
			/proc/pagetypeinfo \
			/proc/partitions \
			/proc/scsi/scsi \
			/proc/slabinfo \
			/proc/swaps \
			/proc/sys/kernel/syno_* \
			/proc/sys/vm/* \
			/proc/uptime \
			/proc/usb/devices \
			/proc/vmallocinfo \
			/proc/vmstat \
			/proc/zoneinfo \
			/sys/class/scsi_host/host*/syno_pm_info \
			"

copy_proc_to_tmp()
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

gen_du_root_result() {
	local RootMnt="$(/bin/mktemp -d /tmp/rootmnt.XXXX)"
	/bin/mount --bind / "${RootMnt}"
	pushd . >/dev/null

	cd "${RootMnt}"
	/bin/du -h -d1 . > $SZD_TMP/result/du-h-d1-rootmnt.result

	popd >/dev/null
	/bin/umount -l "${RootMnt}"
	/bin/rmdir "${RootMnt}"
}

gen_cmd_result() {
	local SZ_CMD="dmesg free ifconfig iwconfig uptime lsof netstat mount"
	local UPS_V_SERVER="localhost"

	# Runtime commands
	for cmd in $SZ_CMD; do
		`/usr/bin/which $cmd` > $SZD_TMP/result/$cmd.result
	done

	gen_du_root_result
	/bin/ls -hlAR /var/log > $SZD_TMP/result/ls-hlAR-var-log.result

	/bin/ps -e -o pid,user,vsz,stat,command > $SZD_TMP/result/ps.result
	/bin/pstree -p > $SZD_TMP/result/pstree.result
	/bin/ps aux www > $SZD_TMP/result/ps-aux-www.result

	/bin/df -h > $SZD_TMP/result/df.result

	mv /etc/mtab /etc/mtab.$$
	/bin/ln -s /proc/mounts /etc/mtab
	/bin/df > $SZD_TMP/result/df2.result
	/bin/df -h > $SZD_TMP/result/df2-h.result
	rm /etc/mtab
	mv /etc/mtab.$$ /etc/mtab

	/usr/bin/top -b -n 1 -w 1024 > $SZD_TMP/result/top.result
	route -n > $SZD_TMP/result/route.result

	/usr/bin/dpkg -l > $SZD_TMP/result/dpkg.result

	if [ -x /usr/syno/bin/spacetool ]; then
		/usr/syno/bin/spacetool --synoblock-enum > $SZD_TMP/result/synoblock_enum.result
	fi

	for i in $(ls /sys/class/net); do
		[ "$i" = "bonding_masters" ] && continue
		${ETHTOOL} $i &> $SZD_TMP/result/ethtool.$i.result
		${ETHTOOL} -S $i &> $SZD_TMP/result/ethtool_stats.$i.result
		${ETHTOOL} -i $i &> $SZD_TMP/result/ethtool_info.$i.result
	done

	# network and firewall related information
	/bin/netstat -neap > $SZD_TMP/result/netstat.result
	/sbin/iptables-save > $SZD_TMP/result/iptables-save.result

	/sbin/iptables-save > $SZD_TMP/result/iptables-save.result
	/sbin/iptables-save -c > $SZD_TMP/result/iptables-save-c.result
	/sbin/ip6tables-save > $SZD_TMP/result/ip6tables-save.result
	/sbin/ip6tables-save -c > $SZD_TMP/result/ip6tables-save-c.result

	/bin/ip route > $SZD_TMP/result/iproute.result
	/bin/ip -6 route > $SZD_TMP/result/ip6route.result

	# core-dump file list
	/bin/ls -al /var/crash/*.core{,.gz} > $SZD_TMP/result/core-files.result
	/bin/ls -al /volume*/*.core{,.gz} >> $SZD_TMP/result/core-files.result

	# for upnp router info, only get them if any port-forwarding conf/rule exists
	if [ -s /etc/portforward/rule.conf ] && [ -s /etc/portforward/router.conf ]; then
		/usr/syno/bin/synoupnp --get-all-info > $SZD_TMP/result/upnp-info.result
	fi

	# for Bluetooth info
	/usr/bin/hciconfig -a > $SZD_TMP/result/bluetooth-hciconfig.result

	# for upsc info
	case `/usr/syno/bin/synogetkeyvalue /etc/synoinfo.conf ups_mode`  in
		slave)
		UPS_V_SERVER=`/usr/syno/bin/synogetkeyvalue /etc/synoinfo.conf upsslave_server`
		;;
	esac
	/usr/bin/upsc ups@$UPS_V_SERVER > $SZD_TMP/result/upsc.result

	# for wireless info
	[ -f /usr/syno/sbin/rfkill ] && /usr/syno/sbin/rfkill list all > $SZD_TMP/result/rfkill.result
	: > $SZD_TMP/result/wifi_signal_antenna.result
	for wsa in `ls /proc/sys/kernel/syno_wifi_signal_antenna*` ;
	do
		/bin/cat $wsa > $SZD_TMP/result/wifi_signal_antenna.result
	done

	# for disk partition info
	for i in `ls /sys/block | grep sd`; do
		/usr/syno/sbin/synopartition --check /dev/${i} >> $SZD_TMP/result/disk_part_ver.result
	done
	/bin/lspci -tv > $SZD_TMP/result/lspci_tv.result
	/bin/lspci -vvv > $SZD_TMP/result/lspci_vvv.result
}
IsMvSocDriver() {
	local KernelVersion Chip
	if [ -z "$1" ]; then
		return 255
	fi
	KernelVersion=`/bin/uname -r | cut -d'.' -f-2`
	if [ "x$KernelVersion" = "x2.4" ]; then
		return 0
	fi
	Chip=`/bin/cat /sys/block/$1/device/../../scsi*/proc_name`
	if [ "x$Chip" = "xmvSata" ]; then
		return 1
	fi
	return 0
}
gen_raid_result() {
	local SZF_RAID_RESULT="$SZD_TMP/result/raid_superblock_enum.result"
	local SZF_SFDISK_RESULT="$SZD_TMP/result/sfdisk_enum.result"

	local i D N ret
	local wait_pid=""
	local _raid_tmp=""
	local _sfdisk_tmp=""

	for i in `cat /proc/partitions | awk '{print $4}'`;
	do
		if [ ! -e /dev/$i ]; then
			continue;
		fi

		# seperate sdXXyy to D=sdXX N=yy
		D=""
		N=""

		case "$i" in
		    hd*)
		    `echo $i | sed -n 's/hd\([a-z]*\)\([0-9]*\)/eval D=hd\1; eval N=\2;/p'`
		    ;;
		    sd*)
		    `echo $i | sed -n 's/sd\([a-z]*\)\([0-9]*\)/eval D=sd\1; eval N=\2;/p'`
		    ;;
		    sas*)
		    `echo $i | sed -n 's/sas\([0-9]*\)p*\([0-9]*\)/eval D=sas\1; eval N=\2;/p'`
		    ;;
		esac

		_raid_tmp="$_raid_tmp $SZF_RAID_RESULT.$i"
		if [ ! -z $N ]; then
			_sfdisk_tmp="$_sfdisk_tmp $SZF_SFDISK_RESULT.$D$N"
		fi

		{
		if [ -x /sbin/mdadm ]; then
			if [ `cat /proc/mdstat | grep -c ${i}` -ne 0 ]; then
				echo "$i:" >> $SZF_RAID_RESULT.$i
				/sbin/mdadm -E -b /dev/$i >> $SZF_RAID_RESULT.$i
				echo "" >> $SZF_RAID_RESULT.$i
			fi
		fi

		if [ ! -z $N ]; then
			# Partition Info for sdXXyy
			/sbin/sfdisk -l -uS -N$N /dev/$D >> $SZF_SFDISK_RESULT.$D$N
			if [ $? -ne 0 ]; then
				echo "/dev/$i error" >> $SZF_SFDISK_RESULT.$D$N
			fi
		fi
		}&
		wait_pid="$wait_pid $!"
	done
	wait $wait_pid
	cat $_raid_tmp 2>/dev/null > $SZF_RAID_RESULT
	cat $_sfdisk_tmp 2>/dev/null > $SZF_SFDISK_RESULT
	rm -f $_raid_tmp $_sfdisk_tmp
}

gen_lv_result()
{
	local SZF_LV_RESULT="$SZD_TMP/result/lv.result"
	lvs=`/sbin/lvs | tail -n +2 | awk '{print "/dev/" $2 "/" $1}' | grep -v syno_vg_reserved_area`
	for lv in $lvs ; do
		echo "  --- Logical volume ---" >> $SZF_LV_RESULT
		echo "  Filesystem created     `/usr/syno/bin/synofstool --get-fs-type $lv`" >> $SZF_LV_RESULT
		/sbin/lvdisplay $lv | tail -n +2 >> $SZF_LV_RESULT
		echo "" >> $SZF_LV_RESULT
	done
}

gen_dm_result()
{
	local SZF_DM_PATH=`/bin/ls /sys/block/dm-*/dm/name`
	local dm name

	for dm_path in ${SZF_DM_PATH}; do
		dm=`printf ${dm_path} | /bin/grep -o 'dm-[0-9]\+'`
		name=`/bin/cat ${dm_path}`
		echo ${dm}"	"${name} >> $SZD_TMP/result/dm.result
	done
}

gen_md_examine_result()
{
	local SZF_MD_EXAM_RESULT="$SZD_TMP/result/md_examine/"
	local DISKS=""
	local PARTS=""
	local wait_pid=""

	mkdir -p $SZF_MD_EXAM_RESULT

	for part in `cat /proc/partitions | awk '{print $4}'`; do
		md_dev=`grep " ${part}" /proc/mdstat | awk '{print $1}'`
		[ ! -z "${md_dev}" ] || continue
		{
		exam_result="`/sbin/mdadm -E /dev/${part} 2> /dev/null`"
		if [ 0 -eq $? ]; then
			echo "${exam_result}" > ${SZF_MD_EXAM_RESULT}/${md_dev}_${part}.log
		fi
		}&
		wait_pid="$wait_pid $!"
	done
	wait $wait_pid
}

gen_tc_result()
{
	local interfaces=`ifconfig | grep "Link encap" | awk '{print $1}'`
	local tc_log="$SZD_TMP/result/tc.result"

	echo "" > $tc_log

	for tc_if in $interfaces ;
	do
		echo "==== $tc_if ====" >> $tc_log
		echo "qdisc:" >> $tc_log
		/usr/sbin/tc qdisc show dev $tc_if >> $tc_log

		echo "class:" >> $tc_log
		/usr/sbin/tc class show dev $tc_if >> $tc_log

		echo "filter:" >> $tc_log
		/usr/sbin/tc filter show dev $tc_if >> $tc_log
	done
}

gen_asound_result()
{
	local base_dir="/proc/asound"

	if [ -d ${base_dir} ]; then
		local card_dir=`ls -d ${base_dir}/card* | sed '/[0-9]$/!d'`
		for card in ${card_dir}; do
			copy_proc_to_tmp "${card}/stream0"
			local sub_dir=`ls -d ${card}/pcm0p/sub* | sed '/[0-9]$/!d'`
			for sub in ${sub_dir}; do
				local sub_list=`ls -d ${sub}/*`
				for sub_file in ${sub_list}; do
					copy_proc_to_tmp "${sub_file}"
				done
			done
		done
	fi
}

gen_sas_topology()
{
	supportSAS=`get_key_value /etc.defaults/synoinfo.conf supportsas`
	if [ "yes" = "${supportSAS}" ]; then
		PROCFILES="${PROCFILES} /sys/class/sas_expander/*/*id /sys/class/sas_expander/*/*rev"
		#SAS controller phy error count
		PROCFILES="${PROCFILES} /sys/class/sas_host/host*/device/phy-*/sas_phy/phy-*/phy_reset_problem_count"
		PROCFILES="${PROCFILES} /sys/class/sas_host/host*/device/phy-*/sas_phy/phy-*/running_disparity_error_count"
		PROCFILES="${PROCFILES} /sys/class/sas_host/host*/device/phy-*/sas_phy/phy-*/invalid_dword_count"
		PROCFILES="${PROCFILES} /sys/class/sas_host/host*/device/phy-*/sas_phy/phy-*/loss_of_dword_sync_count"
		#SAS expander phy error count
		PROCFILES="${PROCFILES} /sys/class/sas_expander/expander*/device/phy-*/sas_phy/phy-*/phy_reset_problem_count"
		PROCFILES="${PROCFILES} /sys/class/sas_expander/expander*/device/phy-*/sas_phy/phy-*/running_disparity_error_count"
		PROCFILES="${PROCFILES} /sys/class/sas_expander/expander*/device/phy-*/sas_phy/phy-*/invalid_dword_count"
		PROCFILES="${PROCFILES} /sys/class/sas_expander/expander*/device/phy-*/sas_phy/phy-*/loss_of_dword_sync_count"

		/bin/cp /tmp/sasdiskmaps $SZD_TMP/result/sasdiskmaps_boot.result
		/usr/syno/bin/synoenc --dump_enc_disk $SZD_TMP/result/sasdiskmaps_curr.result
		/usr/syno/bin/synoenc --enc_enum > $SZD_TMP/result/enc_enum.result
		/usr/syno/bin/synoenc --enc_enum_by_valid_link > $SZD_TMP/result/enc_enum_valid.result
		expAddrs=`/bin/cat /sys/class/sas_device/expander-*/sas_address`
		for exp in ${expAddrs}; do
			/usr/syno/bin/synoses --phy_enum $exp > $SZD_TMP/result/enc.${exp}_phy.result
		done
	fi
}

gen_filesystem_info()
{
	local devPath resultName devName mdList lvList volumePathList volumePath grepPattern
	local tune2FSCmd="`/usr/bin/which tune2fs`"
	local btrfsCmd="`/usr/bin/which btrfs`"
	local btrfsShowSuperCmd="`/usr/bin/which btrfs-show-super` -a"
	local fsTypeCmd="`/usr/bin/which synofstool` --get-fs-type"
	local tune2FSResultDir="$SZD_TMP/var/log/tune2fs"
	local btrfsResultDir="$SZD_TMP/var/log/btrfs"
	mkdir -p "$tune2FSResultDir"
	mkdir -p "$btrfsResultDir"
	mdList=`grep "^md[0-9]*" /proc/mdstat | awk '{print $1}'`
	for devName in $mdList
	do
		devPath="/dev/$devName"
		resultName=`echo "$devPath" | tr '/' '.' | sed -e 's/\.//'`
		if `$fsTypeCmd $devPath | grep -q "^ext[2-4]$"` ; then
			$tune2FSCmd -l "$devPath" > "$tune2FSResultDir/$resultName".result
		elif `$fsTypeCmd $devPath | grep -q "^btrfs$"` ; then
			$btrfsShowSuperCmd "$devPath" > "$btrfsResultDir/$resultName".super.result
			grepPattern="^${devPath%/*}/\<${devPath##*/}\>"
			volumePathList=`df | grep "^$grepPattern" | awk '{print $6}'`
			for volumePath in $volumePathList
			do
				if [ ! -z $volumePath ] ; then
					$btrfsCmd file df $volumePath > "$btrfsResultDir/$resultName".df.result
					$btrfsCmd file show $volumePath > "$btrfsResultDir/$resultName".show.result
					$btrfsCmd filesystem usage $volumePath > "$btrfsResultDir/$resultName".usage.result
				fi
			done
		fi
	done

	lvList=`lvdisplay | grep "LV Path" | awk '{print $3}'`
	for devPath in $lvList
	do
		resultName=`echo "$devPath" | tr '/' '.' | sed -e 's/\.//'`
		if `$fsTypeCmd $devPath | grep -q "^ext[2-4]$"` ; then
			$tune2FSCmd -l "$devPath" > "$tune2FSResultDir/$resultName".result
		elif `$fsTypeCmd $devPath | grep -q "^btrfs$"` ; then
			$btrfsShowSuperCmd "$devPath" > "$btrfsResultDir/$resultName".super.result
			grepPattern="^${devPath%/*}/\<${devPath##*/}\>"
			volumePathList=`df | grep "$grepPattern" | awk '{print $6}'`
			for volumePath in $volumePathList
			do
				if [ ! -z $volumePath ] ; then
					$btrfsCmd file df $volumePath > "$btrfsResultDir/$resultName".df.result
					$btrfsCmd file show $volumePath > "$btrfsResultDir/$resultName".show.result
					$btrfsCmd filesystem usage $volumePath > "$btrfsResultDir/$resultName".usage.result
				fi
			done
		fi
	done
}

gen_selfcheck_result()
{
	/usr/syno/bin/synoselfcheck dsm full
}

gen_dmidecode_result()
{
	if [ -f $DMIDECODE ]; then
            $DMIDECODE > $SZD_TMP/result/dmidecode.result
	fi
}

gen_disk_db_info()
{
	local drivedb="/var/lib/smartmontools/drivedb.version";
	local synodrivedb="/var/lib/smartmontools/synodrivedb.version";
	local tempdb="/var/lib/temperature/disk_temperature.version";
	local infoResult="$SZD_TMP/result/diskdb.result";

	if [ -f $drivedb ]; then
		echo "drivedb.version=`cat $drivedb`" >> $infoResult;
	fi

	if [ -f $synodrivedb ]; then
		echo "synodrivedb.version=`cat $synodrivedb`" >> $infoResult;
	fi

	if [ -f $tempdb ]; then
		echo "disk_temperature.version=`cat $tempdb`" >> $infoResult
	fi
}

gen_smart_result()
{
	/usr/syno/bin/syno_smart_result_collect
}

mkdir -p $SZD_TMP/result

gen_cmd_result
gen_raid_result
gen_lv_result
gen_dm_result
gen_md_examine_result
gen_tc_result
gen_asound_result
gen_sas_topology
gen_filesystem_info
gen_dmidecode_result
gen_disk_db_info
gen_smart_result

for f in $PROCFILES; do
	copy_proc_to_tmp "$f"
done
copy_and_filter_out "\(download_[a-z]*_password\|smspass\|eventpasscrypted\)=" /etc/synoinfo.conf
copy_and_filter_out "\(download_[a-z]*_password\|smspass\|eventpasscrypted\)=" /etc.defaults/synoinfo.conf
copy_and_filter_out "passwd=" /usr/syno/etc/synosms.conf
copy_and_filter_out "passwd=" /etc/ddns.conf
copy_and_filter_out "\(user\|pass\)=" /etc/portforward/router.conf

/bin/ls -l $TMP_LIST >> "$SZD_TMP/grep_files.list"

/bin/ls -l /var/packages >> "$SZD_TMP/packages.list"
/bin/ls -lt /etc/apparmor.d/cache >> "$SZD_TMP/apparmor_cache.list"

exit 0
