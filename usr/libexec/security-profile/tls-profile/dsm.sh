#!/bin/bash
if /usr/syno/sbin/synoservice --status nginx > /dev/null 2>&1; then
    /usr/syno/bin/synow3tool --gen-nginx-tmp && /usr/syno/sbin/synoservice --reload nginx
fi
