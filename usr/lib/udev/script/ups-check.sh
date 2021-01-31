#!/bin/sh

. /usr/syno/bin/synoupscommon

FLOCK_FILE="/tmp/ups/ups.lock"
UPS_CONF="/usr/syno/etc/ups/ups.conf"
UPS_CONF_BACKUP="/etc.defaults/ups/ups.conf"
# for debug log
UPS_LOG=`/bin/get_key_value /etc/synoinfo.conf upslog`
UPS_UDEVLOCK="/tmp/upsudevlock"
if [ $? -ne 1 ]; then
	UPS_LOG="/dev/null"
fi

echo "=== [" `date` "] udev check UPS rule ===" >> $UPS_LOG

vendorID=`echo $PRODUCT | awk -F/ '{printf("0x%04s", $1);}' | sed 's: :0:g'`
productID=`echo $PRODUCT | awk -F/ '{printf("0x%04s", $2);}' | sed 's: :0:g'`
echo "Vendor: $vendorID, Product: $productID, Action: $ACTION" >> $UPS_LOG

# table for UPS model
UPS_TABLE=/lib/udev/devicetable/usb.nut-hid

# Synology support list(Vendor ID)
APC="0x51d"                       
MGE="0x463"                                    
CyberPower="0x764"                                           
TrippLite="0x9ae"                                                                  
Belkin="0x50d"                                                              
Liebert="0x6da"           
PowerCOM="0xd9f"                                       
UPSList="$APC $MGE $CyberPower $TrippLite $Belkin $Liebert $PowerCOM"

{
flock -x 99
if [ $ACTION = add ]; then
	if [ -f "$UPS_CONF_BACKUP" ]; then
		/bin/cp $UPS_CONF_BACKUP $UPS_CONF
	fi

	# for Powercom RPT-600AP reconnect randomly
	if [ $vendorID = '0x0d9f' -a $productID = '0x0004' ]; then
		/bin/sed -i "s/.*pollonly/\tpollonly/" $UPS_CONF
	fi
fi
flock -u 99
} 99<>$UPS_LOCK

# Black List
# Reason:
# Belkin_F5U002: printer
# ...
Belkin_F5U002="50d/2/104"
blackList="$BelkinF5U002"

isInBlackList()
{
	if [ -z "$1" ]; then
		return 1
	fi
	
	for dev in $blackList; do
		if [ "x$dev" = "x$1" ]; then
			echo "$1 is in the black list" >> $UPS_LOG
			return 0
		fi
	done
	return 1		
}

if [ -f ${UPS_TABLE} ]; then
	grep "libhidups      0x0003      $vendorID   $productID" $UPS_TABLE > /dev/null 2>&1
	if [ $? -eq 0 ]; then
		if ! isInBlackList $PRODUCT; then 
			logger -p user.err -t "udev" "[UPS] $ACTION USB UPS(PRODUCT=$PRODUCT)"
			echo "$ACTION USB UPS(PRODUCT=$PRODUCT)" >> $UPS_LOG
			# we should avoid UPS to receive unplug->plug event but finally
			# change to plug->unplug. So we add lock until ups-util.sh script
			# finished.
			RetryTime=5
			while [ -f "$UPS_UDEVLOCK" -a $RetryTime -gt 0 ]; do
				RetryTime=`expr $RetryTime - 1`
				logger -p user.err -t "udev" "ups lock found. $RetryTime times left for waiting..."
				sleep 3
			done

			touch $UPS_UDEVLOCK
			echo "support"
			exit 0
		fi
	fi
fi

echo "Device($PRODUCT) is not supported UPS..." >> $UPS_LOG
echo "unsupported"
exit 0


