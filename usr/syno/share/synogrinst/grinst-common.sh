ControllerIP="169.254.1.1"
MACAddr=`ifconfig eth0 | grep "HWaddr" | cut -d"W" -f 2 | cut -d" " -f 2`
MntDir="/grinst"
NFSPath="/volume1/public"
ErrInstall="/tmp/installer.error"
GetKeyValue="/bin/get_key_value"
ProgressDir="${MntDir}/progress"
ProgressFile="${ProgressDir}/${MACAddr}"
GRINST_LOG="/tmp/grinst.$$"
Unique=`${GetKeyValue} /etc.defaults/synoinfo.conf unique` || true
Model=`${GetKeyValue} /etc.defaults/synoinfo.conf upnpmodelname` || true

# $1:   static blink
# green    8     9
# orange   :     ;
# Turn off if otherwise.
LedControl() {
	case $1 in
		"8"|"9"|":"|";") LED="$1" ;;
		*) LED="7" ;;
	esac
	echo "$LED" > /dev/ttyS1 || true

	if [ "${SupportLCM}" = "yes" ]; then
		echo "$LED" > /dev/ttyACM0 || true
	fi
}

LOG() {
	echo "$1"
	echo "[`date +%T`] $1" >> ${GRINST_LOG}
}

SetProgress() {
	LOG "=== $1"
	echo "[${Unique}] $1" > ${ProgressFile} || true
}

ErrorExit() {
	LOG "ERROR! $1"
	rm -f "${GRINST_LOCK}" || true
	LedControl ":"
	exit 1
}

# $1/$2: Strings to compare, report $3 if not equal
# $3: Message to Report
ReportIfNotEqual() {
	if [ "$1" != "$2" ]; then
		SetProgress "$3"
		umount -f ${MntDir} || true
		ErrorExit
	fi
}

MountController() {
	if [ -n "$1" ]; then
		ControllerIP=$1
	fi

	mkdir -p ${MntDir} || true
	umount -f ${MntDir} || true
	if mount ${ControllerIP}:${NFSPath} ${MntDir}; then
		LOG "mount success" || true
		return 0
	else
		LOG "ERROR! Cannot mount ${ControllerIP}:${NFSPath} to ${MntDir}" || true
		return 1
	fi
}

UnMountController() {
	umount -f ${MntDir} || true
}
