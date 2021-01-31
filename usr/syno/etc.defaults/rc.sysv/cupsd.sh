#!/bin/sh
CUPSD_LPADMIN=/usr/bin/lpadmin
CUPSD_DISABLE=/usr/bin/cupsdisable
GET_SECTION_KEY_VALUE=/usr/syno/bin/get_section_key_value
PRINTER_NAME=""
PPD_PATH="/etc/cups/ppd/"
LOGGER="/usr/bin/logger"
SERVICETOOL="/usr/syno/bin/servicetool"
SwapScript="/usr/syno/bin/swapaction"

MAXDISKS=`/bin/get_key_value /etc.defaults/synoinfo.conf maxdisks`
if [ ${MAXDISKS} -eq 0 ]; then
	DISKLESS="yes"
fi

log_msg()
{
	$LOGGER -sp $1 -t CUPS "$2"
}

update_service_link()
{
	VolumeSpool=$1
	log_msg err "Update service link to [${VolumeSpool}]"
	if [ ! -d /var/services ]; then
		rm -f /var/services
		mkdir /var/services
		chmod 755 /var/services
	fi
	if [ ! -d ${VolumeSpool} ]; then
		rm -f ${VolumeSpool}
		/bin/mkdir ${VolumeSpool}
	fi
	rm -rf /var/services/printer
	ln -sf ${VolumeSpool} /var/services/printer
}

make_spool_ready()
{
	Volume=`${SERVICETOOL} --get-service-path cupsd`
	ServiceOnVolume=$?
	if [ $ServiceOnVolume -eq 0 ] ; then
		Volume=`${SERVICETOOL} --get-alive-volume`
		FoundVolume=$?
		if [ $FoundVolume -eq 0 ] ; then
			log_msg err "Never start CUPS until volume exist..."
			exit 1
		fi
		update_service_link "${Volume}/@spool"
	fi

	SPOOL="/var/services/printer"
	/bin/rm -rf $SPOOL/cache
	/bin/mkdir $SPOOL/cache
	/bin/mkdir -p $SPOOL/tmp
	/bin/chmod -R 777 $SPOOL/
}

make_diskless_spool_ready()
{
	Volume=`${SERVICETOOL} --get-alive-sharebin`
	FoundVolume=$?
	if [ $FoundVolume -eq 0 ] ; then
		Volume="/volume1"
	fi

	ServicePath=`${SERVICETOOL} --get-service-path cupsd`
	ServiceOnVolume=$?
	if [ $ServiceOnVolume -eq 0 ] ; then
		update_service_link "${Volume}/@spool"
	elif [ $FoundVolume -ne 0 ] ; then
		CurrentService=`readlink /var/services/printer`
		FoundCurrent=$?
		if [ $FoundCurrent -ne 0 ] || [ "${CurrentService}" != "${Volume}/@spool" ] ; then
			update_service_link "${Volume}/@spool"
		fi
	fi

	SPOOL="/var/services/printer"
	/bin/rm -rf $SPOOL/cache
	/bin/mkdir $SPOOL/cache
	/bin/mkdir -p $SPOOL/tmp
	/bin/chmod 777 $SPOOL/
	/bin/chmod -R 777 $SPOOL/cache/
	/bin/chmod -R 777 $SPOOL/tmp/
}

link_airprint_filter()
{
	if [ -d /usr/local/cups/filter/ ]; then
		# backward compatible to DSM 5.0 AirPrint drivers
		ln -s /usr/local/cups/filter/* /usr/lib/cups/filter/ > /dev/null 2>&1
	fi
}

pre_start_cups()
{

	# create directories for airprint driver
	mkdir -p /usr/local/cups/
	chgrp lp /usr/local/cups/
	mkdir -p /etc/cups/ppd/

	if [ "$DISKLESS" = "yes" ] ; then
		make_diskless_spool_ready
	else
		make_spool_ready
	fi

	link_airprint_filter
	exit 0
}

post_start_cups()
{
	update_lpoptions
}

reload_cups()
{
	link_airprint_filter
	update_lpoptions
	/sbin/reload cupsd
}

update_lpoptions()
{
	NET_PRINTER=`/usr/syno/bin/synoprint --list net`
	for printer in $NET_PRINTER
	do
		ENABLE=`$GET_SECTION_KEY_VALUE /usr/syno/etc/printer.conf $printer 'fit to page' | grep on | wc -l`
		CUPS_NAME=`$GET_SECTION_KEY_VALUE /usr/syno/etc/printer.conf $printer 'cups printer name'`
		if [ $ENABLE -eq 1 ]; then
			/usr/bin/lpoptions -p $CUPS_NAME -o 'fit-to-page'
		else
			/usr/bin/lpoptions -p $CUPS_NAME -r 'fit-to-page'
		fi
	done
}

case $1 in
uninstall)
	ID=$2
	PRINTER_NAME=`$GET_SECTION_KEY_VALUE /usr/syno/etc/printer.conf $ID cups\ printer\ name`

	PPD=$PPD_PATH/$ID.ppd
	test -f $PPD && rm -f $PPD
	if ! synoservice --status cupsd >/dev/null; then
		synoservice --start cupsd
	fi
	$CUPSD_LPADMIN -x $PRINTER_NAME
	if [ "$DISKLESS" = "yes" ]; then
		$SwapScript off
	fi
	HOSTNAME=`hostname`
	$CUPSD_LPADMIN -p $PRINTER_NAME -E -L "$HOSTNAME" -v usb:/dev/usb/$2
	$CUPSD_DISABLE $PRINTER_NAME
	;;
uninstall_np)
	ID=$2
	PRINTER_NAME=`$GET_SECTION_KEY_VALUE /usr/syno/etc/printer.conf $ID cups\ printer\ name`
	IP=`$GET_SECTION_KEY_VALUE /usr/syno/etc/printer.conf $ID IP`
	Protocol=`$GET_SECTION_KEY_VALUE /usr/syno/etc/printer.conf $ID Backend`
	QName=`$GET_SECTION_KEY_VALUE /usr/syno/etc/printer.conf $ID QName`

	if [ "$Protocol" = "lpd" -o "$Protocol" = "ipp" ] && [ "$QName" != "" ]; then
		Device_URI="$Protocol://$IP/$QName"
	else
		Device_URI="$Protocol://$IP/"
	fi

	PPD=$PPD_PATH/$ID.ppd
	test -f $PPD && rm -f $PPD
	if ! synoservice --status cupsd >/dev/null; then
		synoservice --start cupsd
	fi
	$CUPSD_LPADMIN -x $PRINTER_NAME
	if [ "$DISKLESS" = "yes" ]; then
		$SwapScript off
	fi
	HOSTNAME=`hostname`
	$CUPSD_LPADMIN -p $PRINTER_NAME -E -L "$HOSTNAME" -v $Device_URI
	;;
prestart)
	pre_start_cups
	;;
poststart)
	post_start_cups
	;;
reload)
	reload_cups
	;;
*)
	exit 1
	;;
esac
# the return value should be 0 if operation success without a hitch
