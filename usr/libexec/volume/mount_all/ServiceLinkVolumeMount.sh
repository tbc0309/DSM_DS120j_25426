#!/bin/sh

################################################
# SynoShare SDK hook for volume mount
# Usable environment variable:
#	LOCATION, DEVICE, MOUNTPOINT, and RESULT
###############################################

TMP_LINK=/var/services/tmp
TMP_STATIC=/var/services/tmp.static

create_var_service_tmp() {
	local TMP_TARGET=$1

	[ -d "$TMP_TARGET" ] || /bin/mkdir $TMP_TARGET
	chmod 1777 $TMP_TARGET

	# Create nginx dir in /var/service/tmp
	/bin/mkdir -p -m 700 $TMP_TARGET/nginx
	/usr/bin/chown http:root $TMP_TARGET/nginx

	/bin/ln -sfn $TMP_TARGET $TMP_LINK

	if [ "$TMP_TARGET" != "$TMP_STATIC" ]; then
		/bin/rm -rf $TMP_STATIC
	fi

	/usr/syno/sbin/synoservice --reload nginx
}

case $1 in
        --sdk-mod-ver)
                echo "1.0"
        ;;
        --name)
                echo "synocheckshare volume hook"
        ;;
        --pkg-ver)
                echo "1.0"
        ;;
        --vendor)
                echo "Synology Inc."
        ;;
        --pre)

        ;;
        --post)
				if [ "$RESULT" -ne 0 ]; then
					exit
				fi

				TMP_TARGET=`/bin/readlink $TMP_LINK`

				if [ ! -e "$TMP_LINK" ] || [ ! -e "$TMP_TARGET" ] || [ "$TMP_TARGET" == "$TMP_STATIC" ]; then
					TMP_BIN=`/usr/syno/bin/servicetool --get-alive-sharebin 5`
					if [ $? -ne 1 ]; then
						TMP_TARGET=$TMP_STATIC
					else
						TMP_TARGET=$TMP_BIN/@tmp
					fi

					create_var_service_tmp $TMP_TARGET
				fi
        ;;
        *)
                echo "Usage: $0 --sdk-mod-ver|--name|--pkg-ver|--vendor|--pre|--post"
        ;;
esac
