##!/bin/sh

#if success return 0 else return -1

SYNOMULTICONTROLLER="/usr/syno/bin/synomulticontroller"
HAFORCEREBOOTFLAG="/var/lib/ha/force_reboot"
NTBDOREBOOT="/.ntbreflag"
REMOTE_IP=""
LOCAL_IP=""

ping_remote() {
	/bin/ping $1 -c 1 -W 3 > /dev/null 2>&1
	if test $? -eq 0 ; then
		return 0
	else
		return -1
	fi
}

set_route() {

	if [ -z "`route -n | cut -d' ' -f1 |grep $REMOTE_IP`" ] ; then
		route add -net $REMOTE_IP netmask 255.255.255.255 metric 0 dev ntb_eth0
	fi
}

del_ntb_error_route() {
	route del -net 169.254.0.0 netmask 255.255.0.0 dev ntb_eth0 > /dev/null 2>&1
}

succ_exit() {
	if [ -f $NTBDOREBOOT ] ; then
		rm $NTBDOREBOOT
	fi

	del_ntb_error_route

	exit 0
}

#check reomte is poweron ?
$SYNOMULTICONTROLLER --is_remote_power_on > /dev/null 2>&1
if test $? -eq 0 ; then
#remote is not poweron, exit check
	succ_exit
elif test $? -ne 1 ; then
#power on is 1,off is 0, else is error
	echo "synomulticontroller location fail"
	exit -1
fi

#check remote ip
$SYNOMULTICONTROLLER --location > /dev/null 2>&1
if test $? -eq 0 ; then
	LOCAL_IP="169.254.2.1"
	REMOTE_IP="169.254.2.2"
else
	LOCAL_IP="169.254.2.2"
	REMOTE_IP="169.254.2.1"
fi

set_route

#in 100 seconds try to ping remote ntb eth
for i in {1..10}; do
	ping_remote $REMOTE_IP
	if test $? -eq 0 ; then
		succ_exit
	fi

	#if now reomte is not power on, return 0
	$SYNOMULTICONTROLLER --is_remote_power_on > /dev/null 2>&1
	if test $? -eq 0 ; then
		succ_exit
	fi

	sleep 7
done

#reload module, try at most 10 times
for i in {1..10}; do
	echo "ntb_eth not work, try to reload $i times"
	/sbin/rmmod ntb_netdev.ko > /dev/null 2>&1
	/sbin/rmmod ntb_transport.ko > /dev/null 2>&1
	/sbin/insmod /lib/modules/ntb_transport.ko > /dev/null 2>&1
	/sbin/insmod /lib/modules/ntb_netdev.ko > /dev/null 2>&1
	ifconfig ntb_eth0 $LOCAL_IP > /dev/null 2>&1

	set_route

	ping_remote $REMOTE_IP
	if test $? -eq 0 ; then
		echo "reload ntb let ntb_eth work"
		succ_exit
	fi

	#if now reomte is not power on, return 0
	$SYNOMULTICONTROLLER --is_remote_power_on > /dev/null 2>&1
	if test $? -eq 0 ; then
		succ_exit
	fi

	sleep 7
done

if [ -f $NTBDOREBOOT ] ; then
	echo "ntb_eth can't work, go to standby mode"
	rm $NTBDOREBOOT
elif [ -f $HAFORCEREBOOTFLAG ] ; then
	echo "echo b and ntb eth not work, reboot "
	touch $NTBDOREBOOT
	reboot
fi

del_ntb_error_route
exit -1
