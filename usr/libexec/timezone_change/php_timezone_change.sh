#!/bin/sh
case $1 in
	--sdk-mod-ver)
		#print SDK support version
		echo "1.0"
		;;
	--name)
		#print package name
		echo "php"
		;;
	--pkg-ver)
		#print package version
		echo "5.6"
		;;
	--vendor)
		#printf package vendor
		echo "php.net"
		;;
	--post)
		PHP_date_timezone="$(/usr/syno/sbin/synodate --getNameInTZDB)"
		/bin/sed -i "s:^.*date.timezone =.*$:date.timezone = ${PHP_date_timezone}:g" "/etc/php/php.ini" || true
		;;
	*)
		echo "Usage: $0 --sdk-mod-ver|--name|--pkg-ver|--vendor|--post"
		;;
esac
