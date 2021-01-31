#!/bin/sh

eval `/usr/syno/bin/synoportforward --jobnum 'PF add port' | grep "num="`
if [ "xnormal" = "x$1" ]; then
	echo -n $((num));
elif [ "xdesc" = "x$1" ];then
	echo -n $((num-1));
fi

