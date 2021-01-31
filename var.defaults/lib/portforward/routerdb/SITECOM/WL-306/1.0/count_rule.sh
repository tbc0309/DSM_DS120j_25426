#!/bin/sh

if [ "xrange" = "x$1" ]; then
	eval `/usr/syno/bin/synoportforward --jobnum 'PF add range' | grep "num="`
else
	eval `/usr/syno/bin/synoportforward --jobnum 'PF add port' | grep "num="`
fi

echo -n $((num-1));

