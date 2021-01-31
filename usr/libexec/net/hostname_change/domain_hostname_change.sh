#!/bin/sh
case $1 in
	--sdk-mod-ver)
	#Print SDK support version
	echo "1.0";
	;;
	--name)
	#Print package name
	echo "domain_hostname_change";
	;;
	--pkg-ver)
	#Print package version
	echo "1.0";
	;;
	--vendor)
	#Print package vendor
	echo "Synology";
	;;
	--pre)
        ;;
	--post)
	# if not in domain, no need to leave domain.
	SECURITY=`synogetkeyvalue /etc/samba/smb.conf security`
	if [ "$SECURITY" != "domain" -a "$SECURITY" != "ads" ]; then
		exit
	fi
	if [ -e "/run/samba/synoadserver" ]; then
		/usr/bin/logger -p user.err -t "domain_hostname_change" "hook is skipped in ad mode"
		exit
	fi
	# do nothing when hostname change on booting-up step
	if /usr/syno/bin/synobootseq --is-booting-up > /dev/null 2>&1 ; then
		exit
	fi
	# do nothing when synoha think don't need to leave domain.
	SUPPORT_HA=`synogetkeyvalue /etc.defaults/synoinfo.conf support_ha`
	if [ "$SUPPORT_HA" == "yes" ] && /usr/syno/sbin/synohacore --skip-leave-domain > /dev/null 2>&1 ; then
		exit
	fi
	/usr/bin/logger -p user.err -t "domain_hostname_change" "hostname change cause leave domain"
	/usr/syno/sbin/synowin -joinWorkgroup workgroup
	;;
	*)
	echo "Usage: $0 --sdk-mod-ver|--name|--pkg-ver|--vendor|--pre|--post"
	;;
esac

