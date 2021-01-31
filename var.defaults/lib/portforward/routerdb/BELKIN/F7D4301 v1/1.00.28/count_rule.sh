#!/bin/sh

eval `/usr/syno/bin/synoportforward --jobnum 'PF add port' | grep "num="`
echo $((num-1));
