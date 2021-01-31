#!/bin/sh

case $1 in
    --sdk-mod-ver)
        echo "1.0";
    ;;
    --name)
        echo "update_nginx_resolver";
    ;;
    --pkg-ver)
        echo "1.0";
    ;;
    --vendor)
        echo "Synology Inc.";
    ;;
    --pre)
    ;;
    --post)
        if ! /usr/syno/sbin/synoservicectl --status nginx > /dev/null 2>&1; then
            exit 0
        fi
        if ! /usr/syno/bin/synow3tool --gen-nginx-tmp > /dev/null 2>&1; then
            exit 1
        fi
        if ! /usr/syno/sbin/synoservice --reload nginx > /dev/null 2>&1; then
            exit 1
        fi
    ;;
    *)
        echo "Usage: $0 --sdk-mod-ver|--name|--pkg-ver|--vendor|--pre|--post"
    ;;
esac
