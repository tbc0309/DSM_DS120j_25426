#!/bin/sh

PKG_NAME="iscsitrg"
PKG_VERSION="1.0"
PKG_VENDOR="Synology Inc."
PKG_MODVER="1.0"

LOGGER="/usr/bin/logger"

case $1 in
	--sdk-mod-ver)
		#Print SDK support version
		echo $PKG_MODVER;
		;;
	--name)
		#Print package name
		echo $PKG_NAME;
		;;
	--pkg-ver)
		#Print package version
		echo $PKG_VERSION;
		;;
	--vendor)
		#Print package vendor
		echo $PKG_VENDOR;
		;;
	--pre)
		;;
	--post)
		# do nothing when ip change on booting-up step
		if /usr/syno/bin/synobootseq --is-booting-up > /dev/null 2>&1 ; then
			if [ -z "`status iscsitrg-adapter | grep running`" ]; then
				exit
			fi
		fi
		# do nothing when ip change shutdown step
		if /usr/syno/bin/synobootseq --is-shutdown > /dev/null 2>&1 ; then
			exit
		fi
		# do nothing when iscsi service is disabled
		/usr/syno/etc/rc.sysv/S78iscsitrg.sh status > /dev/null 2>&1
		if [ "$?" != "0" ]; then
			exit
		fi
		# ignores the events comming from the interfaces for PPTP/L2TP server-side,
		# whose names are in the ranage of ppp201-299 and ppp301-399, because no
		# services interested them.
		echo $IFNAME | grep 'ppp[2-3]\{1\}[0-9]\{2\}' > /dev/null 2>&1
		if [ "$?" == "0" ] && [ "ppp200" != "$IFNAME" ] && [ "ppp300" != "$IFNAME" ]; then
			exit
		fi
		if [ "tun1000" = "$IFNAME" ]; then
			exit
		fi
		/usr/syno/bin/synoiscsiep --network_portal_update --ifname ${IFNAME} --origin_ip ${ORIGIN_ADDRESS} --new_ip ${NEW_ADDRESS} --is_link ${IS_LINK}
		support_vaai=`/bin/get_key_value /etc.defaults/synoinfo.conf support_vaai`
		case "${support_vaai}" in
			[Yy][Ee][Ss])
				/sbin/initctl restart iscsi_pluginengined
				/sbin/initctl restart scsi_plugin_server
				;;
			*)
				;;
		esac
		;;
	*)
		echo "Usage: $0 --sdk-mod-ver|--name|--pkg-ver|--vendor|--pre|--post"
		;;
esac

