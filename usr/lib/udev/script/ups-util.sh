#!/bin/sh

UPS_NOTIFY="/lib/udev/script/synoupsnotify.sh"
SERVICE_RUNNING=`/usr/syno/bin/synogetkeyvalue /etc/synoinfo.conf ups_enabled`
UPS_UDEVLOCK="/tmp/upsudevlock"

if [ "$1" == "start" ]; then
	/usr/syno/bin/synologset1 sys info 0x1130001A
	/usr/syno/sbin/synoservice --start ups-usb
	if [ "$SERVICE_RUNNING" == "yes" ]; then
		$UPS_NOTIFY UPSConnected &
	fi
elif [ "$1" == "stop" ]; then
	/usr/syno/bin/synologset1 sys warn 0x11300018
	/usr/syno/sbin/synoservice --stop ups-usb
	if [ "$SERVICE_RUNNING" == "yes" ]; then
		$UPS_NOTIFY UPSDisconnect &
	fi
fi

# after synoservice done! we release the lock for
# udev
if [ -f "$UPS_UDEVLOCK" ]; then
	rm $UPS_UDEVLOCK
else
	logger -p user.err -t "udev" "UPS warning: no upsudevlock for unlock"
fi
