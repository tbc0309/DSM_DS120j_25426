#!/bin/sh
# Copyright (c) 2000-2014 Synology Inc. All rights reserved.

# Synology Service which need MDNS
# iTunes(mt-daapd), AFP, TimeMachine, HTTP:5000, Webdav
# Surveillance, PhotoStation, Printer
#
# FIXME: Let each service write down its own mdns service file.
# Should not generate them here

SYNOSDUTILS="$(which synosdutils)"

AVAHI_CONF_PATH="/etc/avahi"
AVAHI_SERVICE_PATH="${AVAHI_CONF_PATH}/services"
SYNO_PRINT="/usr/syno/bin/synoprint"
PRINTER_CONF="/usr/syno/etc/printer.conf"
TIME_MACHINE_CONF="/usr/syno/etc/time_machine.conf"
CUPS_PRINTERS_CONF="/etc/cups/printers.conf"

# DSM builtin service files in avahi
TM_SCONF="$AVAHI_SERVICE_PATH/tm.service"
AFP_SCONF="$AVAHI_SERVICE_PATH/afp.service"
SMB_SCONF="$AVAHI_SERVICE_PATH/smb.service"
FTP_SCONF="$AVAHI_SERVICE_PATH/ftp.service"
SFTP_SCONF="$AVAHI_SERVICE_PATH/sftp.service"

#builtin service
AFP_SERVICE="atalk"
SMB_SERVICE="samba"
NFS_SERVICE="nfsd"
FTP_SERVICE="ftpd"
SFTP_SERVICE="sftp"
BONJOUR_SERVICE="bonjour"

AddAFP() {
	Port=548

	echo -en \
"<service-group>
<name>$1</name>
<service>
<type>_device-info._tcp</type>
<txt-record>model=Xserve</txt-record>
</service>
<service>
<type>_afpovertcp._tcp</type>
<port>$Port</port>
</service>
</service-group>
" > $AFP_SCONF
}

AddSMB() {
	Port=445

	echo -en \
"<service-group>
<name>$1</name>
<service>
<type>_device-info._tcp</type>
<txt-record>model=Xserve</txt-record>
</service>
<service>
<type>_smb._tcp</type>
<port>$Port</port>
</service>
</service-group>
" > $SMB_SCONF
}

AddNFS() {
	Port=2049
	IFS=$'\n'

	# echo NFS service via "exportfs"
	for EXPORTING_PATH in `/sbin/exportfs -avr | /bin/cut -d":" -f2`; do
		SHARE_NAME=`/bin/basename $EXPORTING_PATH`
		echo -en \
"<service-group>
<name>$1-NFS-$SHARE_NAME</name>
<service>
<type>_nfs._tcp</type>
<port>$Port</port>
<txt-record>path=$EXPORTING_PATH</txt-record>
</service>
</service-group>" > "$AVAHI_SERVICE_PATH/nfs-$SHARE_NAME.service"
    done
}

AddFtp(){
	Port=`/bin/get_key_value /etc/synoinfo.conf ftpport`
	if [ "$Port" == "" ]; then
		Port=21
	fi

	echo -en \
"<service-group>
<name>$1</name>
<service>
<type>_ftp._tcp</type>
<port>$Port</port>
</service>
</service-group>
" > $FTP_SCONF
}

AddSftp(){
	Port=`/bin/get_key_value /etc/synoinfo.conf sftpPort`
	if [ "$Port" == "" ]; then
		Port=22
	fi

	echo -en \
"<service-group>
<name>$1</name>
<service>
<type>_sftp._tcp</type>
<port>$Port</port>
</service>
</service-group>
" > $SFTP_SCONF
}

AddBoujourPrinter() {
	# check usbprinter1/usbprinter2
	# call AddBonjourPrinterConf to add to conf
	MFG_TOKENS="MFG: MANUFACTURER:"
	MDL_TOKENS="MDL: MODEL:"
	MAXPRINTER=`/bin/get_key_value /etc.defaults/synoinfo.conf maxprinters`
	PRINTER_PREFIX="usbprinter"

	for PrinterId in `$SYNO_PRINT --list`; do
		MFG=""; MDL="";
			PrinterStringId=`$SYNO_PRINT --get-string-id $PrinterId`
			for tok in $MFG_TOKENS; do
				if echo $PrinterStringId | grep "$tok">/dev/null; then
					MFG=`echo $PrinterStringId | sed "s/.*$tok\([^;]*\);.*/\1/"`
					break
				fi
			done
			for tok in $MDL_TOKENS; do
				if echo $PrinterStringId | grep "$tok">/dev/null; then
					MDL=`echo $PrinterStringId | sed "s/.*$tok\([^;]*\);.*/\1/"`
					break
				fi
			done

			if [ "${MFG}${MDL}" != "" ]; then
				PrinterName=`$SYNO_PRINT --get-cups-name $PrinterId`
				AddBonjourPrinterConf $1 "$PrinterName" "$MFG $MDL" "$PrinterId"
			else
				echo "Fail to get model info of $PRINTER_PREFIX$i"
			fi
	done
}

GetCupsPrinterUUID() {
	local TempLineNum=`awk "/<Printer $1>/{print NR}" $CUPS_PRINTERS_CONF`
	local Value=`awk "NR>$TempLineNum && /UUID/{print $2}" $CUPS_PRINTERS_CONF | head -n1`
	UUID=`echo $Value | awk '{FS=":"} {printf $3}'`
}

GetCupsPrinterMakeModel() {
	local TempLineNum=`awk "/<Printer $1>/{print NR}" $CUPS_PRINTERS_CONF`
	local Value=`awk "NR>$TempLineNum && /MakeModel/{print}" $CUPS_PRINTERS_CONF | head -n1`
	MakeModel=`echo $Value | sed -n "s/MakeModel //p"`
}

AddBonjourPrinterConf() {
	PortLPR=515
	PortIPP=631
	PRINTER_SCONF="$AVAHI_SERVICE_PATH/bonjour-$2.service"

	AIRPRINT_EXT=""
	AIRPRINT_SUBTYPE=""
	AIRPRINT_URF=""
	AIRPRINT_STAT=`/usr/syno/bin/synoprint --ckairprint $4`
	if [ "$AIRPRINT_STAT" = "on" ]; then
		AIRPRINT_EXT=",application/pdf,image/urf,image/jpeg"
		AIRPRINT_URF="\n<txt-record>URF=W8,SRGB24,DM1,CP255,RS600-300</txt-record>"
		AIRPRINT_SUBTYPE="\n<subtype>_universal._sub._ipp._tcp</subtype>"
	fi

	POSTSCRIPT_EXT=""
	PrinterStringId=`$SYNO_PRINT --get-string-id $PrinterId`
	echo $PrinterStringId |grep -i 'postscript' >/dev/null 2>&1
	if [ $? -eq 0 ];then
	    POSTSCRIPT_EXT=",application/postscript"
	fi

	GetCupsPrinterUUID $2
	GetCupsPrinterMakeModel $2

	echo -en \
"<service-group>
<name>$2 @ $1</name>
<service>
<type>_printer._tcp</type>
<port>$PortLPR</port>
<txt-record>txtvers=1</txt-record>
<txt-record>qtotal=2</txt-record>
<txt-record>ty=$3</txt-record>
<txt-record>note=$1($3)</txt-record>
<txt-record>pdl=application/octet-stream$POSTSCRIPT_EXT</txt-record>
<txt-record>rp=$2</txt-record>
</service>
<service>
<type>_ipp._tcp</type>$AIRPRINT_SUBTYPE
<port>$PortIPP</port>
<txt-record>adminurl=http://$1:$PortIPP/printers/$2</txt-record>
<txt-record>txtvers=1</txt-record>
<txt-record>qtotal=1</txt-record>
<txt-record>ty=$3</txt-record>
<txt-record>note=$1</txt-record>
<txt-record>product=($MakeModel)</txt-record>
<txt-record>pdl=application/octet-stream$AIRPRINT_EXT$POSTSCRIPT_EXT</txt-record>$AIRPRINT_URF
<txt-record>UUID=$UUID</txt-record>
<txt-record>rp=printers/$2</txt-record>
</service>
</service-group>
" > $PRINTER_SCONF
}

CheckServices() {
	ServName="`/bin/hostname`"
	BUILTIN_SERVICE="$AFP_SERVICE $SMB_SERVICE $NFS_SERVICE $FTP_SERVICE $SFTP_SERVICE $BONJOUR_SERVICE"

	# check DSM builtin service alive
	for service in $BUILTIN_SERVICE;
	do
		if [ "x" != "x`/usr/syno/sbin/synoservice --is-enable $service | /bin/grep disabled`" ]; then
			case $service in
				$AFP_SERVICE)
					/bin/rm -f "$AFP_SCONF"
					$SYNOSDUTILS time-machine --afp-status
				;;
				$SMB_SERVICE)
					/bin/rm -f "$SMB_SCONF"
					$SYNOSDUTILS time-machine --smb-status
				;;
				$NFS_SERVICE)
					/bin/rm -f ${AVAHI_SERVICE_PATH}/nfs-*.service
				;;
				$FTP_SERVICE)
					/bin/rm -f "${AVAHI_SERVICE_PATH}/ftp.service"
				;;
				$SFTP_SERVICE)
					/bin/rm -f "${AVAHI_SERVICE_PATH}/sftp.service"
				;;
				$BONJOUR_SERVICE)
					/bin/rm -f ${AVAHI_SERVICE_PATH}/bonjour-*.service
				;;
			esac
		fi
	done
}

ServName="`/bin/hostname`"

# make sure $AVAHI_SERVICE_PATH exists
if ! [ -d $AVAHI_SERVICE_PATH ]; then
    /bin/mkdir -p $AVAHI_SERVICE_PATH;
fi

case "$1" in
		avahi-delete-conf)
			CheckServices
		;;
		afp-conf)
			AddAFP $ServName
			$SYNOSDUTILS time-machine --afp-status
		;;
		smb-conf)
			AddSMB $ServName
			$SYNOSDUTILS time-machine --smb-status
		;;
		bonjour-conf)
			AddBoujourPrinter $ServName
		;;
		ftp-conf)
			AddFtp $ServName
		;;
		sftp-conf)
			AddSftp $ServName
		;;
esac
exit 0
