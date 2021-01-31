#!/bin/bash
SZD_TMP="$1"
for FILE in /usr/syno/etc/www /etc/nginx /var/tmp/nginx/app.d /usr/local/etc/nginx/conf.d /usr/local/etc/nginx/sites-enabled /usr/syno/etc/packages/*/AppPortal.json; do
    DEST_DIR="$SZD_TMP"$(/usr/bin/dirname "$FILE")
    mkdir -p "$DEST_DIR"
    cp -rsx "$FILE" "$DEST_DIR"
done
