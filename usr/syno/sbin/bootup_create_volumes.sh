#!/bin/bash

echo "start bootup_create_volumes"

if [ -f "/.assistant_install_create_vol" ]; then
	SZF_MANUTIL_VOLUME_SIZE="/.manutil_volume_size"

	if [ ! -f $SZF_MANUTIL_VOLUME_SIZE ]; then
		/usr/syno/bin/volumetool --create-for-install
	else
		# for manutil patch
		manutil_vol_size=`/bin/get_key_value $SZF_MANUTIL_VOLUME_SIZE size`
		if [ 0 -ne $manutil_vol_size ]; then
			touch /tmp/volume.$manutil_vol_size
			/usr/syno/bin/volumetool --create-for-install
		fi
		rm -f $SZF_MANUTIL_VOLUME_SIZE
	fi
	rm -f /.assistant_install_create_vol
fi

PLATFORM=$(get_key_value /etc.defaults/synoinfo.conf unique | cut -d"_" -f2)
if [ "$PLATFORM" = "kvmx64" -o \
		"$PLATFORM" = "nextkvmx64" -o \
		"$PLATFORM" = "kvmcloud" ]; then
	#Create volume for VDSM
	/usr/syno/bin/volumetool --create-vdsm-volumes
fi

