#!/bin/sh

INETD=/usr/bin/inetd
INETD_CONF="/etc/inetd.conf"
TEMP_CONF="/tmp/inetd.$$.conf.tmp"
CUPS_LPD="/usr/lib/cups/daemon/cups-lpd"

check_conf()
{
	if [ ! -f $INETD_CONF ]; then
		touch $INETD_CONF
	fi
}

prestart_telnetd()
{
	check_conf

	grep -v "^[ 	]*telnet\([ 	]\|$\)" $INETD_CONF > $TEMP_CONF
	echo "telnet	stream	tcp6 nowait	root	/usr/bin/telnetd	telnetd -h" >> $TEMP_CONF
	echo "telnet	stream	tcp nowait	root	/usr/bin/telnetd	telnetd -h" >> $TEMP_CONF
	mv $TEMP_CONF $INETD_CONF

	reload inetd
}

poststop_telnetd()
{
	check_conf

	grep -v "^[ 	]*telnet\([ 	]\|$\)" $INETD_CONF > $TEMP_CONF
	mv $TEMP_CONF $INETD_CONF

	killall telnetd
	reload inetd
}

prestart_cups_lpd()
{
	if [ ! -x ${CUPS_LPD} ]; then
		echo "cups-lpd does not exist"
		return 0
	fi

	check_conf

	grep -v "^[ 	]*printer\([ 	]\|$\)" $INETD_CONF > $TEMP_CONF
	echo "printer	stream  tcp	nowait	root	${CUPS_LPD} cups-lpd" >> $TEMP_CONF
	echo "printer	stream  tcp6 nowait	root	${CUPS_LPD} cups-lpd" >> $TEMP_CONF
	mv $TEMP_CONF $INETD_CONF

	reload inetd
}

poststop_cups_lpd()
{
	check_conf

	grep -v "^[ 	]*printer\([ 	]\|$\)" $INETD_CONF > $TEMP_CONF
	mv $TEMP_CONF $INETD_CONF

	reload inetd
}

case "$1" in

prestart_telnetd)
	prestart_telnetd
	;;

poststop_telnetd)
	poststop_telnetd
	;;

prestart_cups_lpd)
	prestart_cups_lpd
	;;

poststop_cups_lpd)
	poststop_cups_lpd
	;;

*)
	echo "usage: $0 { prestart_telnetd | poststop_telnetd | prestart_cups_lpd | poststop_cups_lpd }" >&2
	exit 1
	;;

esac
