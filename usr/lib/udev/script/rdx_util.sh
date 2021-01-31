#!/bin/sh

DEVNAME=$2

is_rdx()
{
	## check if the device if a RDX device
	udevadm info --name=${DEVNAME} | grep SYNO_IS_RDX=1
}

rdx_eject()
{
	## check parameter
	if [ -z "${DEVNAME}" ]; then
		echo "please provide device name"
		exit 1
	fi

	is_rdx
	if [ "0" != "$?" ]; then
		echo "not a rdx device"
		exit 0
	fi
	## eject RDX tape
	logger -p user.err -t $(basename $0) "eject RDX device ${DEVNAME} ..."
	/sbin/eject -s ${DEVNAME}

	exit $?
}

case "$1" in
	eject)
		rdx_eject
		;;
	is_rdx)
		is_rdx
		exit $?
		;;
	*)
		echo "Usages: $0 eject <devname>"
	;;
esac

exit 0
