#!/bin/sh

usb_parse_vidpid()
{
	# work around 2.2.early brokenness
	# munges the usb_bcdDevice such that it is a integer rather
	# than a float: e.g. 1.0 become 0100
	PRODUCT=`echo $PRODUCT | sed -e "s+\.\([0-9]\)$+.\10+" -e "s/\.$/00/" \
								-e "s+/\([0-9]\)\.\([0-9][0-9]\)+/0\1\2+" \
				-e "s+/\([0-9][0-9]\)\.\([0-9][0-9]\)+/\1\2+"`
	set `echo $PRODUCT | /usr/bin/awk -F/ '{print "0x" $1, "0x" $2, "0x" $3 }'` ''
	usb_idVendor=$1
	usb_idProduct=$2
	usb_bcdDevice=$3

	# idVendor and idProduct should be regular hex format
	echo "$usb_idVendor" | egrep "\b0[xX][0-9a-fA-F]+\b" > /dev/null
	if [ $? != 0 ]; then
		return;
	fi
	echo "$usb_idProduct" | egrep "\b0[xX][0-9a-fA-F]+\b" > /dev/null
	if [ $? != 0 ]; then
		return;
	fi
}

usb_parse_vidpid

echo "SYNO_USB_VENDER=${usb_idVendor}"
echo "SYNO_USB_PRODUCT=${usb_idProduct}"
