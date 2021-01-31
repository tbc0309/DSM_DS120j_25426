#!/bin/bash
# Copyright (c) 2000-2016 Synology Inc. All rights reserved.

SZD_MUSTACHE="/usr/syno/share/nginx"
SZF_NGINX_MUSTACHE="$SZD_MUSTACHE/nginx.mustache"
SZF_AVAHI_MUSTACHE="$SZD_MUSTACHE/avahi.mustache"
SZD_TMP_NGINX="/var/tmp/nginx"
SZD_TMP_APP_D="$SZD_TMP_NGINX/app.d"
SZD_TMP_CONF_D="$SZD_TMP_NGINX/conf.d"
SZF_TMP_NGINX_CONF="$SZD_TMP_NGINX/nginx.conf"
SZF_RP_DATASTORE="$SZD_TMP_NGINX/ReverseProxy.tmp"
SZF_AVAHI_CONF="/etc/avahi/services/dsminfo.service"

GenerateConf()
{
	local mustache="$1"
	local json="$2"
	local conf="$3"
	/usr/syno/bin/synomustache "$mustache" $json -o "$conf"
}

/bin/rm -rf $SZD_TMP_APP_D $SZD_TMP_CONF_D
/bin/mkdir -p $SZD_TMP_APP_D $SZD_TMP_CONF_D
/usr/bin/touch $SZD_TMP_CONF_D/{{main,events}.conf,mime.types,scgi_params}
/usr/syno/bin/synow3 --gen
tmp=$(/bin/ls $SZD_TMP_NGINX/*.tmp)
GenerateConf "$SZF_NGINX_MUSTACHE" "$tmp" "$SZF_TMP_NGINX_CONF" || true

if [ -s "$SZF_RP_DATASTORE" ]; then
	GenerateConf "$SZD_MUSTACHE/Portal.mustache" "$SZF_RP_DATASTORE" "$SZD_TMP_APP_D/server.ReverseProxy.conf" || true
fi

if [ -s "$SZD_TMP_NGINX/DSM.tmp" ]; then
    GenerateConf "$SZF_AVAHI_MUSTACHE" "$SZD_TMP_NGINX/DSM.tmp" "$SZF_AVAHI_CONF" || true
fi
applist=$(/bin/ls /usr/syno/etc/www/app.d/*.mustache) || true
for var in $applist
do
	var=$(/usr/bin/basename "$var" | /bin/sed 's/.mustache//')
	tmpJson="$SZD_TMP_NGINX/app/$var.tmp"
	appMustache="/usr/syno/etc/www/app.d/$var.mustache"
	confTail="$var.conf"

	if [ -s "$appMustache" ] && [ -s "$tmpJson" ]; then
		# dsm included in 5000, www included in 80
		if [ "$(/bin/jq .injectable "$tmpJson")" = "true" ]; then
			GenerateConf "$appMustache" "" "$SZD_TMP_APP_D/www.$confTail" || true
		else
			GenerateConf "$appMustache" "" "$SZD_TMP_APP_D/dsm.$confTail" || true
		fi
		# alias
		if [ "$(jq .alias "$tmpJson")" != "null" ]; then
			GenerateConf "$appMustache" "$tmpJson" "$SZD_TMP_APP_D/.alias.$confTail" || true
			GenerateConf "$SZD_MUSTACHE/Alias_v2.mustache" "$tmpJson {\"include\":\".alias.$confTail\"}" "$SZD_TMP_APP_D/alias.$confTail" || true
		fi
		# server
		if [ "$(jq .fqdn "$tmpJson")" != "null" ] || [ "$(jq .alternativePort "$tmpJson")" != "null" ]; then
			GenerateConf "$appMustache" "$tmpJson {\"server\":true,\"alias\":null}" "$SZD_TMP_APP_D/.server.$confTail" || true
			GenerateConf "$SZD_MUSTACHE/server.mustache" "$tmpJson $SZD_TMP_NGINX/SSLProfile.tmp $SZD_TMP_NGINX/DSM.tmp {\"include\":\".server.$confTail\"}" "$SZD_TMP_APP_D/server.$confTail" || true
		fi
	fi
done

filelist=$(/bin/ls /etc.defaults/nginx/*) || true
for f in $filelist
do
	if [ -f "$f" ]; then
		cp "$f" "$SZD_TMP_NGINX/."
	fi
done
