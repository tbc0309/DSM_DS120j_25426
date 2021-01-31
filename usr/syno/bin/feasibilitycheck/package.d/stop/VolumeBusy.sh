#!/bin/sh

JQ=/bin/jq
SYNOWEBAPI=/usr/syno/bin/synowebapi

response="$($SYNOWEBAPI --exec api=SYNO.Core.Storage.Volume method=list offset=0 limit=-1 location=all 2> /dev/null)"
if [ "true" != "$(echo "$response" | $JQ '.success')" ]; then
    exit 0
fi

status="$(echo $response | $JQ '.data | .volumes | map(.status)')"
if [ "true" = "$(echo "$status" | $JQ 'contains(["deleting"]) or
                                       contains(["mounting_cache"]) or
                                       contains(["unmounting_cache"]) or
                                       contains(["convert_shr_to_pool"])')" ]; then
    exit 1
fi

exit 0
