#!/bin/sh
. /etc.defaults/rc.subr

SYNOMOUNT=/usr/syno/bin/synomount
BOOTSEQ=/usr/syno/bin/synobootseq
KERNEL_VCODE=`KernelVersionCode $(KernelVersion)`

LoadModule()
{
	local MODULE=$1
	local MODULE_PATH=

	if [ -z "$MODULE" ]; then
		return 1;
	fi

	shift;

	if lsmod | grep -q "^$MODULE\>"; then
		return 0;
	fi

	MODULE_PATH=/lib/modules/$MODULE.ko
	if [ -f "${MODULE_PATH}" ]; then
		echo "Load ${MODULE}.ko ... "
		insmod ${MODULE_PATH} "$@" > /dev/null 2>&1
	fi
}

RemoveModule()
{
	local MODULE=$1

	if [ -z "$MODULE" ]; then
		return 1;
	fi

	if ! lsmod | grep -q "^$MODULE\>"; then
		return 0;
	fi

	echo "Remove ${MODULE}.ko ..."
	rmmod $MODULE
}

SYNOMountAllBooting()
{
	$SYNOMOUNT --all
	while true;
	do
		if $BOOTSEQ --is-ready > /dev/null 2>&1; then
			$SYNOMOUNT --all
			break
		fi
		sleep 10
		if $BOOTSEQ --is-shutdown > /dev/null 2>&1; then
			break
		fi
	done
}

start()
{
	if [ $KERNEL_VCODE -ge $(KernelVersionCode "3") ]; then
		loop_node_gen
		LoadModule loop
	else
		LoadModule loop max_loop=16
	fi
	LoadModule isofs
	LoadModule udf
	LoadModule cifs

	if $BOOTSEQ --is-ready >/dev/null 2>&1; then
		$SYNOMOUNT --resume &
	else
		SYNOMountAllBooting &
	fi
}

stop()
{
	$SYNOMOUNT --umountall

	RemoveModule udf
	RemoveModule isofs
	RemoveModule loop
	RemoveModule cifs
}

case "$1" in
	start) start ;;
	stop) stop ;;
	*) ;;
esac

