#!/bin/sh
#S90usbip.sh - startup script for multifunctional printer
#
# This goes in /usr/syno/etc/rc.d and gets run at boot-time.
PRINTERCONF=/usr/syno/etc/printer.conf
KERNEL_VERSION=`uname -r`

CAT=/bin/cat
CUT=/usr/bin/cut
ECHO=/bin/echo
GET_KEY_VALUE=/bin/get_key_value
GREP=/bin/grep
INSMOD=/sbin/insmod
RMMOD=/sbin/rmmod
KILL=/bin/kill
PIDFILEDIR=/var/run
PIDOF=/bin/pidof
LOGGER=/usr/bin/logger

BIND_DRIVER=/usr/bin/bind_driver
USBIPD=/usr/bin/usbipd

case "$KERNEL_VERSION" in
"3.10."* | "3.6."*)
	USBIP_KO=/lib/modules/usbip-host
	USBIP_COMMON_MOD_KO=/lib/modules/usbip-core
	;;
*)
	USBIP_KO=/lib/modules/usbip
	USBIP_COMMON_MOD_KO=/lib/modules/usbip_common_mod
	;;
esac
VHCI_HCD_KO=/lib/modules/vhci-hcd
SYNOPRINT=/usr/syno/bin/synoprint

log_msg()
{
        $LOGGER -sp $1 -t USBIP "$2"
}

# For non-support model
SUPPORTMFP=`$GET_KEY_VALUE /etc.defaults/synoinfo.conf supportMFP`
if [ "x$SUPPORTMFP" != "xyes" ]; then
	exit 1
fi

LoadModules() {
		# insmod usbip kernel modules
		$INSMOD "$USBIP_COMMON_MOD_KO.ko" > /dev/null 2>&1
		$INSMOD "$USBIP_KO.ko" > /dev/null 2>&1
		#$INSMOD "$VHCI_HCD_KO.ko" > /dev/null 2>&1
}

UnLoadModules() {
    # rmmod usbip kernel modules
    $RMMOD $USBIP_KO > /dev/null 2>&1
    $RMMOD $USBIP_COMMON_MOD_KO > /dev/null 2>&1
    #$RMMOD $VHCI_HCD_KO > /dev/null 2>&1
}

SIGUSR1USBIPD() {
	/usr/syno/sbin/synoservice --reload usbipd > /dev/null 2>&1
}

ExecuteUSBIPD() {
    # execute the usbipd daemon or force to reload config.

	ret=`/usr/syno/sbin/synoservice --status usbipd`
	if [ $? -ne 0 ]; then
		/usr/syno/sbin/synoservice --start usbipd > /dev/null 2>&1
	fi
}

STOPUSBIPD() {
    # stop the usbipd daemon and unload modules.
	/usr/syno/sbin/synoservice --stop usbipd > /dev/null 2>&1
}

if [ "x$1" = "xstartd" ]; then
	LoadModules
	ExecuteUSBIPD

elif [ "x$1" = "xbindbybusid" ]; then
    LoadModules
    $BIND_DRIVER --usbip $2 > /dev/null 2>&1
    ExecuteUSBIPD

elif [ "x$1" = "xbindbyprinterid" ]; then
    LoadModules
    $BIND_DRIVER --syno $2 > /dev/null 2>&1
    ExecuteUSBIPD

elif [ "x$1" = "xunbind" ]; then
    $BIND_DRIVER --other $2 > /dev/null 2>&1
    usbipDeviceNum=`$BIND_DRIVER --count`
    if [ $usbipDeviceNum -eq 0 ]; then
		STOPUSBIPD
    else
		SIGUSR1USBIPD
    fi
fi

